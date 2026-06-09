# Get Started with Antigravity

## Overview

In this lab, you will set up a complete cloud-based development environment using Google Compute Engine and Chrome Remote Desktop. You'll deploy a virtual machine pre-configured with Antigravity tools—a suite of collaborative development tools including Antigravity 2.0, Antigravity IDE, and the Antigravity CLI (agy).

The lab uses Terraform to provision a secure GCE instance with a full desktop environment (XFCE), Chrome Remote Desktop for remote access, and a curated set of development tools including Docker, Node.js, VS Code, Claude Code, and uv (Python package installer). This setup enables you to access a powerful, consistent development environment from any device with a web browser.

By the end of this lab, you'll have hands-on experience with Chrome Remote Desktop for accessing cloud-based virtual machines and be ready to explore Antigravity's collaborative development capabilities.

### Objectives

In this lab, you will learn how to perform the following tasks:

- Configure and authorize the Chrome Remote Desktop service on a Compute Engine instance
- Connect to a cloud-based desktop environment via Chrome Remote Desktop
- Launch and authenticate Antigravity 2.0 with your Google Cloud project
- Build and deploy an application using Antigravity's AI-assisted development workflow
- Execute repository-based recipes and follow automated build instructions

## Setup and requirements

### Start the Lab

**⚠️ Important Reminders:**

- **Do not use** your personal Google Cloud account/project for this lab.
- When you click "Open Google Cloud Console," **right-click** and select "Open link in incognito window." Using incognito mode is recommended to avoid any conflicts with existing Google credentials.

## Task 1. Configure and start the Chrome Remote Desktop service

![01_setup_crd_vm.gif](https://raw.githubusercontent.com/jbrache/crd-gce-antigravity/refs/heads/main/terraform-lab/instructions/img/01_setup_crd_vm.gif)

To start the remote desktop server, you need to have an authorization key for the Google Account that you want to use to connect to it:

1.  In the Google Cloud console, go to the **VM Instances** page:

    [Go to the VM Instances page](https://console.cloud.google.com/compute/instances/)

2.  Connect to your instance by clicking the **SSH** button.

3.  On your local computer, using the Chrome browser **in incognito mode**, go to the Chrome Remote Desktop command line setup page:

    [https://remotedesktop.google.com/headless](https://remotedesktop.google.com/headless)

    <ql-infobox><strong>Note:</strong> Googlers, you can *not* use your corp account to authorize CRD connections to Compute Engine VMs due to beyond-corp restrictions. Ensure you're using a incognito mode with the Qwiklabs credentials.
    </ql-infobox>

4.  If you're not already signed in, sign in with a Google Account. This is the account that will be used for authorizing remote access.

5.  On the **Set up another computer** page, click **Begin**.

6.  Click **Authorize**.

    You need to allow Chrome Remote Desktop to access your account. If you approve, the page displays a command line for Debian Linux that looks like the following:

    <pre class="console">
    DISPLAY= /opt/google/chrome-remote-desktop/start-host \
        --code="4/xxxxxxxxxxxxxxxxxxxxxxxx" \
        --redirect-url="https://remotedesktop.google.com/_/oauthredirect" \
        --name=$(hostname)
    </pre>

    You use this command to set up and start the Chrome Remote Desktop service on your VM instance, linking it with your Google Account using the authorization code.

    <ql-infobox><strong>Note:</strong> The authorization code in the command line is valid for only a few
    minutes, and you can use it only once.
    </ql-infobox>

7.  Copy the command to the SSH window that's connected to your instance, and then run the command.
8.  When you're prompted, enter a 6-digit PIN, i.e. **000000**. This number will be used for additional authorization when you connect later.

    You might see errors like `No net_fetcher` or `Failed to read`. You can ignore these errors.

**Optional:** Verify that the service is running using the following command.

```sh
sudo systemctl status chrome-remote-desktop@$USER
```

If the service is running, you see output that includes the state `active`:

<pre class="console">
chrome-remote-desktop.service - LSB: Chrome Remote Desktop service
    Loaded: loaded (/lib/systemd/system/chrome-remote-desktop@USER.service; enabled; vendor preset: enabled)
    Active: <b>active (running)</b> since DATE_TIME; ELAPSED_TIME
</pre>

**Optional:** Troubleshooting the startup script, skip if you see the chrome remote desktop service running.

```sh
# Run the following command to download the latest script from metadata and execute it
sudo google_metadata_script_runner startup

# Viewing the output of a Linux startup script
sudo journalctl -u google-startup-scripts.service
```

## Task 2. Connect to the VM instance

![02_crd_connect.gif](https://raw.githubusercontent.com/jbrache/crd-gce-antigravity/refs/heads/main/terraform-lab/instructions/img/02_crd_connect.gif)

You can connect to the VM instance using the Chrome Remote Desktop web
application.

1.  On your local computer, go to the [Chrome Remote Desktop](https://remotedesktop.google.com)
    website, **while using an incognito mode with the Qwiklabs credentials**.

2.  Click **Access my computer.**

3.  If you're not already signed in to Google, sign in with the same Google Account that you used to set up the Chrome Remote Desktop service.

    You see your new VM instance `crdhost` in the **Remote Devices** list.

4.  Click the name of the remote desktop instance.

5.  When you're prompted, enter the PIN that you created earlier, and then click the arrow button to connect.

    You are now connected to the desktop environment on your remote Compute Engine instance.

6. If you are prompted, always allow the Remote Desktop application to read your clipboard and let you copy and paste between local and remote applications.

7. If you installed the Xfce desktop, the first time you connect, you are prompted to set up the desktop panels. Click **Use Default Config** to get the standard taskbar at the top and the quick launch panel at the bottom.

![xfce desktop showing the taskbar and quick launch panel.](https://raw.githubusercontent.com/jbrache/crd-gce-antigravity/refs/heads/main/terraform-lab/instructions/img/02_xfce_desktop.png)

## Task 3. Start Antigravity

![03_antigravity_signin.gif](https://raw.githubusercontent.com/jbrache/crd-gce-antigravity/refs/heads/main/terraform-lab/instructions/img/03_antigravity_signin.gif)

1.  Open a terminal and start Antigravity 2.0 by typing `antigravity`.

    You can also try `antigravity-ide` (Antigravity IDE) or `agy` (Antigravity CLI), but the focus in these steps is on Antigravity 2.0.

2.  Once Antigravity 2.0 UI loads, on the `Welcome to Antigravity` screen, select: `Use Google Cloud project instead`.

3.  Using the Qwiklabs username/password, authenticate in the launched browser.

4.  When you get to the form to `Enter Google Cloud Project Details`, enter the `Google Cloud Project ID` of the Qwiklabs project.

## Task 4. Build Application from an existing workflow

You will be using this workflow in Antigravity to build the application:

- https://github.com/jchavezar/vertex-ai-samples/tree/main/agy-recipes/aether-architecture-portal

Create a new project to start the conversation, for example name it: `aether-architecture-portal`.

Start a new conversation with the following **prompt** in your project:

```sh
Your task is to build the "aether-architecture-portal" recipe from the vertex-ai-samples repository. Please execute the following steps in order:

1. Clone the repository to your local workspace:
   `git clone --depth 1 https://github.com/jchavezar/vertex-ai-samples.git`

2. Navigate to the specific recipe directory:
   `cd vertex-ai-samples/agy-recipes/aether-architecture-portal`

3. Read the `README.md` file located in this directory to understand the dependencies, architecture, and required build steps.

4. Strictly follow the recipe instructions provided in the `README.md`. Execute the necessary commands, apply the configurations, and build the portal exactly as specified. 

Please provide a summary of the steps you took, any prerequisites I need to have configured (like GCP credentials or specific API enablement), and confirm when the build is successfully completed or if you ran into any errors.
```

**At the end of the workflow** in this lab you should get to a point where sample recipe/workflow is launched and you're able to open the React Web UI running on Port 5173: `http://localhost:5173`

![04_end_result.png](https://raw.githubusercontent.com/jbrache/crd-gce-antigravity/refs/heads/main/terraform-lab/instructions/img/04_end_result.png)

## Task 5. Review

Congratulations! In this lab, you successfully set up and explored a cloud-based development environment with Antigravity tools. Here's what you accomplished:

### What You Learned

1. **Chrome Remote Desktop Configuration**
   - Configured and started the Chrome Remote Desktop service on a GCE instance
   - Authorized remote access using your Google Account
   - Connected to a cloud-based desktop environment from your web browser

2. **Cloud Infrastructure Setup**
   - Deployed a fully-configured GCE instance using Terraform
   - Set up a secure, private network with IAP tunnel access
   - Configured a development environment with XFCE desktop, Docker, Node.js, VS Code, and other essential tools

3. **Antigravity Tools**
   - Launched Antigravity 2.0 and authenticated with your Google Cloud project
   - Explored the Antigravity ecosystem including Antigravity 2.0, Antigravity IDE, and the Antigravity CLI (agy)
   - Used Antigravity to build an application from an existing workflow by cloning a repository and following recipe instructions

4. **Development Workflow**
   - Executed a complete workflow to build the "aether-architecture-portal" application
   - Used AI-assisted development to clone repositories, navigate directories, and execute build instructions
   - Learned how to leverage Antigravity for automated development tasks

### Key Takeaways

- Chrome Remote Desktop provides a convenient way to access cloud-based development environments from any device
- Terraform enables reproducible infrastructure deployment for consistent development setups
- Antigravity tools streamline collaborative development and AI-assisted coding workflows
- Cloud-based development environments offer scalability and accessibility advantages over local setups

### Next Steps

Now that you have a working Antigravity environment, you can:

- Explore more recipes in the [vertex-ai-samples/agy-recipes repository](https://github.com/jchavezar/vertex-ai-samples/tree/main/agy-recipes)
- Try building your own applications using Antigravity's AI-assisted development features
- Experiment with the Antigravity CLI (`agy`) for command-line workflows