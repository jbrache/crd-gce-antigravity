/**
 * Copyright 2026 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# -------------------------------------------------------------------
# Local Variables
# -------------------------------------------------------------------
locals {
  network_id   = google_compute_network.vpc_network.id
  subnet_id    = google_compute_subnetwork.gce_subnet.id
  instance_tag = "crd-gce-instance"
  user         = strcontains(var.username, "@") ? var.username : "${var.username}@qwiklabs.net"
  bucket_name  = "${var.gcp_project_id}-scripts"

  common_labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
  })

  startup_script = <<-EOT
    #!/bin/bash -x
    set -e
    export HOME=/root

    INSTALL_XFCE=${var.install_xfce ? "yes" : "no"}
    INSTALL_CINNAMON=${var.install_cinnamon ? "yes" : "no"}
    INSTALL_CHROME=yes
    INSTALL_DOCKER=${var.install_docker ? "yes" : "no"}
    INSTALL_FULL_DESKTOP=yes
    INSTALL_ANTIGRAVITY_HUB=${var.install_antigravity_hub ? "yes" : "no"}
    INSTALL_ANTIGRAVITY_IDE=${var.install_antigravity_ide ? "yes" : "no"}
    INSTALL_AGY=${var.install_agy ? "yes" : "no"}
    INSTALL_UV=${var.install_uv ? "yes" : "no"}
    INSTALL_CLAUDE=${var.install_claude ? "yes" : "no"}

    EXTRA_PACKAGES="less bzip2 zip unzip wget nano git"

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

    if [[ "$INSTALL_ANTIGRAVITY_HUB" = "yes" ]] && [[ ! -d /opt/antigravity-hub ]]; then
      (
        set -o pipefail
        curl -fL \
          "${var.antigravity_hub_url}" \
          | tar -xzf - -C /tmp/ \
          && mv /tmp/Antigravity-x64 /opt/antigravity-hub \
          && chown root:root /opt/antigravity-hub/chrome-sandbox \
          && chmod 4755 /opt/antigravity-hub/chrome-sandbox \
          && ln -sf /opt/antigravity-hub/antigravity /usr/local/bin/antigravity \
          || echo "WARNING: Antigravity Hub download/install failed, skipping"
      ) &
      AGRAV_HUB_INSTALL_PID=$!
    fi

    if [[ "$INSTALL_ANTIGRAVITY_IDE" = "yes" ]] && [[ ! -d /opt/antigravity-ide ]]; then
      (
        set -o pipefail
        curl -fL \
          "${var.antigravity_ide_url}" \
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

    if [[ "$INSTALL_AGY" = "yes" ]] && ! command -v agy &> /dev/null; then
      echo "Installing Antigravity CLI..."
      curl -fsSL https://antigravity.google/cli/install.sh | bash \
        || echo "WARNING: Antigravity CLI install failed, continuing"
      cp /root/.local/bin/agy /usr/local/bin/agy && chmod 755 /usr/local/bin/agy || true
    fi

    if [[ "$INSTALL_UV" = "yes" ]] && ! command -v uv &> /dev/null; then
      echo "Installing uv..."
      curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh \
        || echo "WARNING: uv install failed, continuing"
    fi

    if [[ "$INSTALL_CLAUDE" = "yes" ]] && ! command -v claude &> /dev/null; then
      echo "Installing Claude Code..."
      npm install -g @anthropic-ai/claude-code \
        || echo "WARNING: Claude Code install failed, continuing"
      ln -sf "$(npm prefix -g)/bin/claude" /usr/local/bin/claude || true
    fi

    echo "Chrome remote desktop installation completed successfully."
    EOT
}

# -------------------------------------------------------------------
# Project Configuration
# -------------------------------------------------------------------
resource "google_project_service" "required_apis" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "iap.googleapis.com",
    "storage.googleapis.com",
  ])

  project            = var.gcp_project_id
  service            = each.key
  disable_on_destroy = false
}

resource "time_sleep" "wait_for_apis" {
  depends_on      = [google_project_service.required_apis]
  create_duration = var.api_activation_wait
}

# -------------------------------------------------------------------
# Service Account and IAM
# -------------------------------------------------------------------
resource "google_service_account" "gce_sa" {
  project      = var.gcp_project_id
  account_id   = var.gce_service_account_id
  display_name = "GCE Chrome Remote Desktop Service Account"
}

resource "google_project_iam_member" "gce_sa_roles" {
  for_each = toset([
    "roles/compute.networkUser",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/aiplatform.user"
  ])

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gce_sa.email}"
}

resource "google_project_iam_member" "user_os_login" {
  project  = var.gcp_project_id
  role     = "roles/compute.osAdminLogin"
  member   = "user:${local.user}"
}

resource "google_project_iam_member" "user_iap_tunnel" {
  project  = var.gcp_project_id
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:${local.user}"
}

# -------------------------------------------------------------------
# VPC Network
# -------------------------------------------------------------------
resource "google_compute_network" "vpc_network" {
  project                 = var.gcp_project_id
  name                    = var.vpc_name
  auto_create_subnetworks = false
  mtu                     = 1460
}

resource "google_compute_subnetwork" "gce_subnet" {
  project                  = var.gcp_project_id
  name                     = "${var.gcp_region}-gce"
  ip_cidr_range            = var.subnetwork_range
  region                   = var.gcp_region
  network                  = google_compute_network.vpc_network.name
  private_ip_google_access = true
}

# -------------------------------------------------------------------
# Firewall Rules
# -------------------------------------------------------------------
resource "google_compute_firewall" "gce_egress" {
  project     = var.gcp_project_id
  name        = "crd-gce-allow-egress"
  network     = google_compute_network.vpc_network.name
  direction   = "EGRESS"
  priority    = 100
  target_tags = [local.instance_tag]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "gce_ingress_internal" {
  project       = var.gcp_project_id
  name          = "crd-gce-allow-ingress-internal"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"
  priority      = 100
  target_tags   = [local.instance_tag]
  source_ranges = [var.subnetwork_range]

  allow { protocol = "icmp" }
  allow { protocol = "tcp" }
  allow { protocol = "udp" }
}

# Allow SSH via Identity-Aware Proxy
resource "google_compute_firewall" "gce_ingress_iap" {
  project       = var.gcp_project_id
  name          = "crd-gce-allow-ingress-iap"
  network       = google_compute_network.vpc_network.name
  direction     = "INGRESS"
  priority      = 100
  target_tags   = [local.instance_tag]
  source_ranges = ["35.235.240.0/20"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# -------------------------------------------------------------------
# Cloud NAT (required for outbound internet access with no external IP)
# -------------------------------------------------------------------
resource "google_compute_router" "gce_router" {
  project = var.gcp_project_id
  name    = "gce-router-${var.gcp_region}"
  region  = var.gcp_region
  network = local.network_id
}

resource "google_compute_router_nat" "gce_nat" {
  project                            = var.gcp_project_id
  name                               = "gce-nat-${var.gcp_region}"
  router                             = google_compute_router.gce_router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -------------------------------------------------------------------
# GCS Bucket for Startup Script
# -------------------------------------------------------------------
resource "google_storage_bucket" "startup_scripts" {
  project                     = var.gcp_project_id
  name                        = local.bucket_name
  location                    = var.gcp_region
  force_destroy               = false
  uniform_bucket_level_access = true

  depends_on = [time_sleep.wait_for_apis]
}

resource "google_storage_bucket_iam_member" "gce_sa_bucket_access" {
  bucket = google_storage_bucket.startup_scripts.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.gce_sa.email}"
}

resource "google_storage_bucket_object" "startup_script" {
  name    = "crdhost/crdhost-autoinstall-startup-script.sh"
  bucket  = google_storage_bucket.startup_scripts.name
  content = local.startup_script
}

# -------------------------------------------------------------------
# GCE Instance
# -------------------------------------------------------------------
resource "google_compute_instance" "crd_instance" {
  project      = var.gcp_project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.gcp_zone

  labels = local.common_labels
  tags   = [local.instance_tag]

  scheduling {
    provisioning_model          = "STANDARD"
    max_run_duration {
      # Maximum run duration of 8 hours (8 * 60 * 60 = 28800 seconds)
      seconds                   = 28800
    }
    instance_termination_action = "STOP"
    on_instance_stop_action {
      discard_local_ssd         = true
    }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = var.boot_disk_size_gb
      type  = "pd-ssd"
    }
  }

  network_interface {
    subnetwork = local.subnet_id
    # No access_config block = no external IP (equivalent to --no-address)
  }

  metadata = {
    startup-script-url = "gs://${google_storage_bucket.startup_scripts.name}/${google_storage_bucket_object.startup_script.name}"
  }

  service_account {
    email  = google_service_account.gce_sa.email
    scopes = ["cloud-platform"]
  }

  depends_on = [
    # time_sleep.wait_for_org_policy,
    google_storage_bucket_object.startup_script,
    google_project_iam_member.gce_sa_roles,
  ]
}
