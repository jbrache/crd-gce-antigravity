# Using a GCE Instance with Chrome Remote Desktop with Antigravity

Manual creation steps

## Step 1. Create Bucket
```bash
export PROJECT_ID="<your-project-id>"
export BUCKET_NAME="${PROJECT_ID}-samples"
gcloud storage buckets create gs://${BUCKET_NAME} --location=us-central1
```

## Step 2. Create Starup Script
```bash
cat << 'EOF' > crdhost-autoinstall-startup-script.sh
#!/bin/bash -x
set -e
export HOME=/root

INSTALL_XFCE=yes
INSTALL_CINNAMON=no
INSTALL_CHROME=yes
INSTALL_DOCKER=no
INSTALL_FULL_DESKTOP=yes

EXTRA_PACKAGES="less bzip2 zip unzip wget nano"

function is_installed {
  dpkg -s "$1" &> /dev/null
}

# ==========================================================================
# Phase 1: Register all apt repositories (sequential — just writes files)
# ==========================================================================

if ! is_installed chrome-remote-desktop; then
  if [[ ! -e /etc/apt/sources.list.d/chrome-remote-desktop.list ]]; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-linux-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-keyring.gpg] https://dl.google.com/linux/chrome-remote-desktop/deb stable main" \
      | tee /etc/apt/sources.list.d/chrome-remote-desktop.list
  fi
fi

if ! is_installed code; then
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | tee /etc/apt/sources.list.d/vscode.list
fi

APT_UPDATED=no
if ! command -v node &> /dev/null; then
  # Adds NodeSource repo and primes the apt cache for all repos in one pass
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
  APT_UPDATED=yes
fi

# ==========================================================================
# Phase 2: Start large binary downloads in background while apt works
# ==========================================================================

if [[ ! -d /opt/antigravity-hub ]]; then
  (
    set -o pipefail
    curl -fL \
      "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.11-6560309696135168/linux-x64/Antigravity.tar.gz" \
      | tar -xzf - -C /tmp/ \
      && mv /tmp/Antigravity-x64 /opt/antigravity-hub \
      && chown root:root /opt/antigravity-hub/chrome-sandbox \
      && chmod 4755 /opt/antigravity-hub/chrome-sandbox \
      && ln -sf /opt/antigravity-hub/antigravity /usr/local/bin/antigravity \
      || echo "WARNING: Antigravity Hub download/install failed, skipping"
  ) &
  AGRAV_HUB_INSTALL_PID=$!
fi

if [[ ! -d /opt/antigravity-ide ]]; then
  (
    set -o pipefail
    curl -fL \
      "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.0.4-6381998290370560/linux-x64/Antigravity%20IDE.tar.gz" \
      | tar -xzf - -C /tmp/ \
      && mv "/tmp/Antigravity IDE" /opt/antigravity-ide \
      && chown root:root /opt/antigravity-ide/chrome-sandbox \
      && chmod 4755 /opt/antigravity-ide/chrome-sandbox \
      && ln -sf /opt/antigravity-ide/antigravity-ide /usr/local/bin/antigravity-ide \
      || echo "WARNING: Antigravity IDE download/install failed, skipping"
  ) &
  AGRAV_IDE_INSTALL_PID=$!
fi

if [[ "$INSTALL_CHROME" = "yes" ]] && ! is_installed google-chrome-stable; then
  curl -L -o /tmp/google-chrome-stable_current_amd64.deb \
    https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &
  CHROME_PID=$!
fi

if [[ "$INSTALL_DOCKER" = "yes" ]] && ! command -v docker &> /dev/null; then
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh &
  DOCKER_PID=$!
fi

# ==========================================================================
# Phase 3: Single apt-get update + install (overlaps with background downloads)
# ==========================================================================

PACKAGES="desktop-base xscreensaver dbus-x11 $EXTRA_PACKAGES"

if ! is_installed chrome-remote-desktop; then
  PACKAGES="$PACKAGES chrome-remote-desktop"
fi

if ! is_installed code; then
  PACKAGES="$PACKAGES code"
fi

if ! command -v node &> /dev/null; then
  PACKAGES="$PACKAGES nodejs"
fi

if [[ "$INSTALL_XFCE" != "yes" && "$INSTALL_CINNAMON" != "yes" ]]; then
  INSTALL_XFCE=yes
  INSTALL_CINNAMON=yes
fi

if [[ "$INSTALL_XFCE" = "yes" ]]; then
  PACKAGES="$PACKAGES xfce4"
  [[ "$INSTALL_FULL_DESKTOP" = "yes" ]] && PACKAGES="$PACKAGES task-xfce-desktop"
fi

if [[ "$INSTALL_CINNAMON" = "yes" ]]; then
  PACKAGES="$PACKAGES cinnamon-core"
  [[ "$INSTALL_FULL_DESKTOP" = "yes" ]] && PACKAGES="$PACKAGES task-cinnamon-desktop"
fi

echo "Installing all packages..."
[[ "$APT_UPDATED" != "yes" ]] && apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes -q --no-install-recommends $PACKAGES

if [[ "$INSTALL_CINNAMON" = "yes" ]]; then
  echo "exec cinnamon-session-cinnamon2d" > /etc/chrome-remote-desktop-session
elif [[ "$INSTALL_XFCE" = "yes" ]]; then
  echo "exec xfce4-session" > /etc/chrome-remote-desktop-session
fi

systemctl disable lightdm.service || true

# ==========================================================================
# Phase 4: Wait for background downloads and process them
# ==========================================================================

if [[ -n "$${CHROME_PID-}" ]]; then
  if wait $CHROME_PID; then
    DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --fix-broken /tmp/google-chrome-stable_current_amd64.deb
    rm /tmp/google-chrome-stable_current_amd64.deb
  else
    echo "WARNING: Chrome download failed, skipping"
  fi
fi

if [[ -n "$${DOCKER_PID-}" ]]; then
  if wait $DOCKER_PID; then
    sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh
  else
    echo "WARNING: Docker installer download failed, skipping"
  fi
fi

if [[ -n "$${AGRAV_HUB_INSTALL_PID-}" ]]; then
  wait $AGRAV_HUB_INSTALL_PID || true
fi

if [[ -n "$${AGRAV_IDE_INSTALL_PID-}" ]]; then
  wait $AGRAV_IDE_INSTALL_PID || true
fi

if ! command -v agy &> /dev/null; then
  echo "Installing Antigravity CLI..."
  curl -fsSL https://antigravity.google/cli/install.sh | bash \
    || echo "WARNING: Antigravity CLI install failed, continuing"
  cp /root/.local/bin/agy /usr/local/bin/agy && chmod 755 /usr/local/bin/agy || true
fi

if ! command -v uv &> /dev/null; then
  echo "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh \
    || echo "WARNING: uv install failed, continuing"
fi

if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code..."
  npm install -g @anthropic-ai/claude-code \
    || echo "WARNING: Claude Code install failed, continuing"
  ln -sf "$(npm prefix -g)/bin/claude" /usr/local/bin/claude || true
fi

echo "Chrome remote desktop installation completed successfully."
EOF
```

## Step 3. Copy Startup Script to Bucket
```bash
gcloud storage cp crdhost-autoinstall-startup-script.sh gs://${BUCKET_NAME}/crdhost/crdhost-autoinstall-startup-script.sh
```

## Step 4. Create a VM
```bash
export INSTANCE_NAME="crdhost-autoinstall"
gcloud compute instances create ${INSTANCE_NAME} \
    --machine-type=e2-standard-16 \
    --image-project=debian-cloud \
    --image-family=debian-12 \
    --boot-disk-size=200GB \
    --no-address \
    --max-run-duration=28800s \
    --instance-termination-action=STOP \
    --discard-local-ssds-at-termination-timestamp=true
    --metadata=startup-script-url=gs://${BUCKET_NAME}/crdhost/crdhost-autoinstall-startup-script.sh \
    --zone=us-central1-a

```

**[Troubleshooting](https://docs.cloud.google.com/architecture/chrome-desktop-remote-on-compute-engine#troubleshooting)**  
**How to verify exactly what went wrong:** You can check the logs of the startup script to see exactly where it failed. Run these command inside your VM:
```bash
# Run the following command to download the latest script from metadata and execute it
sudo google_metadata_script_runner startup

# Viewing the output of a Linux startup script
sudo journalctl -u google-startup-scripts.service
```

## Step 5. [Configure and start the Chrome Remote Desktop service](https://docs.cloud.google.com/architecture/chrome-desktop-remote-on-compute-engine#configure_and_start_the_chrome_remote_desktop_service)

1. In the Google Cloud console, go to the [**VM Instances**](https://console.cloud.google.com/compute/instances/) page
2. Connect to your instance by clicking the **SSH** button.
3. On your local computer, using the Chrome browser, go to the Chrome Remote Desktop command line setup page:
[https://remotedesktop.google.com/headless](https://remotedesktop.google.com/headless)
4. If you're not already signed in, sign in with a Google Account. This is the account that will be used for authorizing remote access.
5. On the **Set up another computer** page, click **Begin**.
6. Click Authorize.
You need to allow Chrome Remote Desktop to access your account. If you approve, the page displays a command line for Debian Linux that looks like the following:
```bash
DISPLAY= /opt/google/chrome-remote-desktop/start-host \
    --code="4/xxxxxxxxxxxxxxxxxxxxxxxx" \
    --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
    --name=$(hostname)
```

You use this command to set up and start the Chrome Remote Desktop service on your VM instance, linking it with your Google Account using the authorization code.

Note: The authorization code in the command line is valid for only a few minutes, and you can use it only once.
7. Copy the command to the SSH window that's connected to your instance, and then run the command.
8. When you're prompted, enter a 6-digit PIN. This number will be used for additional authorization when you connect later.
You might see errors like `No net_fetcher` or `Failed to read`. You can ignore these errors
9. Verify that the service is running using the following command.
```bash
sudo systemctl status chrome-remote-desktop@$USER
```
If the service is running, you see output that includes the state active:
```bash
chrome-remote-desktop.service - LSB: Chrome Remote Desktop service
    Loaded: loaded (/lib/systemd/system/chrome-remote-desktop@USER.service; enabled; vendor preset: enabled)
    Active: active (running) since DATE_TIME; ELAPSED_TIME
```

## Step 6. Install Antigravity 2.0
https://antigravity.google/download

1. Download and Extract
Open your terminal and run these commands to fetch the archive and extract it:
```bash
# Download the specific Antigravity Hub 2.0.10 tarball
curl -LO https://storage.googleapis.com/antigravity-public/antigravity-hub/2.0.10-5119448496078848/linux-x64/Antigravity.tar.gz

# Extract the archive
tar -xvzf Antigravity.tar.gz
```
2. Move to `/opt` and Fix Sandbox Permissions
The standard Linux location for self-contained, third-party software is the `/opt` directory. Moving it here requires `sudo`.
```bash
# Move the extracted folder to /opt
sudo mv Antigravity-x64 /opt/antigravity-hub

# Fix the Electron sandbox permissions (Crucial!)
sudo chown root:root /opt/antigravity-hub/chrome-sandbox
sudo chmod 4755 /opt/antigravity-hub/chrome-sandbox

# Create a symlink so you can launch it from the terminal by typing 'antigravity-hub'
sudo ln -s /opt/antigravity-hub/antigravity /usr/local/bin/antigravity
```

## Step 7. Install Antigravity IDE
https://antigravity.google/download

1. Download and Extract
Open your terminal and run these commands to fetch the archive and extract it:
```bash
# Download the specific Antigravity IDE tarball
curl -LO https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.0.3-6242596486512640/linux-x64/Antigravity%20IDE.tar.gz

# Extract the archive
tar -xvzf Antigravity%20IDE.tar.gz
```

2. Move to `/opt` and Fix Sandbox Permissions
The standard Linux location for self-contained, third-party software is the `/opt` directory. Moving it here requires `sudo`.
```bash
# Move the extracted folder to /opt
sudo mv "Antigravity IDE" /opt/antigravity-ide

# Fix the Electron sandbox permissions (Crucial!)
sudo chown root:root /opt/antigravity-ide/chrome-sandbox
sudo chmod 4755 /opt/antigravity-ide/chrome-sandbox

# Create a symlink so you can launch it from the terminal by typing 'antigravity-ide'
sudo ln -sf /opt/antigravity-ide/antigravity-ide /usr/local/bin/antigravity-ide
```
## Step 8. Antigravity CLI
```bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
```

## Step 9 Additional Installs
User
```bash
sudo adduser jose
sudo adduser jose sudo
```

Chrome
```bash
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt-get install -y google-chrome-stable_current_amd64.deb
```

Install docker 
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
```

User access to docker daemon
```bash
export USER="jose"
sudo usermod -aG docker $USER
newgrp docker
```

Install UV
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Install Node
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24
```

Install VS Code
```bash
sudo apt install snapd -y
sudo snap install core
sudo snap install --classic code
sudo apt-get install nano
```

Install Claude Code
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Add Gemini and Claude Code setup to .bashrc
```bash
cat << 'EOF' >> ~/.bashrc

# Gemini and Claude Code setup
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=us-east5
export ANTHROPIC_VERTEX_PROJECT_ID=<your-project-id>
export GOOGLE_GENAI_USE_ENTERPRISE=true
export GOOGLE_GENAI_USE_VERTEXAI=true
export GOOGLE_CLOUD_LOCATION=us-central1
export GOOGLE_CLOUD_PROJECT=<your-project-id>
EOF

source ~/.bashrc

```