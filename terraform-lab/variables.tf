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
# Project Configuration
# -------------------------------------------------------------------
# Qwiklabs Mandatory Values
variable "gcp_project_id" {
  description = "The existing Google Cloud project ID to use for resources"
  type        = string
}

# Qwiklabs Mandatory Values
variable "gcp_region" {
  description = "The GCP region to create resources in"
  type        = string
  default     = "us-central1"
}

# Qwiklabs Mandatory Values
variable "gcp_zone" {
  description = "The GCP zone for the GCE instance"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment tag to help identify the entire deployment"
  type        = string
  default     = "dev"
}

variable "labels" {
  type        = map(any)
  description = "Labels, provided as a map"
  default     = {}
}

# -------------------------------------------------------------------
# Developer Configuration
# -------------------------------------------------------------------

variable "username" {
  description = "A reference custom input which is the username of the user"
  type        = string
  default     = null
}

# -------------------------------------------------------------------
# Network Configuration
# -------------------------------------------------------------------

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "crd-gce-vpc"
}

variable "subnetwork_range" {
  description = "The range of internal addresses that are owned by this subnetwork"
  type        = string
  default     = "10.3.0.0/16"
}

# -------------------------------------------------------------------
# Service Account Configuration
# -------------------------------------------------------------------

variable "gce_service_account_id" {
  description = "Service account ID for the GCE instance"
  type        = string
  default     = "crd-gce-sa"
}

# -------------------------------------------------------------------
# Compute Configuration
# -------------------------------------------------------------------

variable "instance_name" {
  description = "Name of the GCE instance"
  type        = string
  default     = "crdhost-autoinstall"
}

variable "machine_type" {
  description = "Machine type for the GCE instance"
  type        = string
  default     = "e2-standard-16"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 200
}

# -------------------------------------------------------------------
# Desktop Environment Configuration
# -------------------------------------------------------------------

variable "install_xfce" {
  description = "Whether to install XFCE desktop environment"
  type        = bool
  default     = true
}

variable "install_cinnamon" {
  description = "Whether to install Cinnamon desktop environment"
  type        = bool
  default     = false
}

variable "install_docker" {
  description = "Whether to install Docker"
  type        = bool
  default     = false
}

variable "install_antigravity_hub" {
  description = "Whether to install Antigravity Hub"
  type        = bool
  default     = true
}

variable "antigravity_hub_url" {
  description = "URL for the Antigravity Hub installation package"
  type        = string
  default     = "https://storage.googleapis.com/antigravity-public/antigravity-hub/2.1.4-6481382726303744/linux-x64/Antigravity.tar.gz"
}

variable "install_antigravity_ide" {
  description = "Whether to install Antigravity IDE"
  type        = bool
  default     = true
}

variable "antigravity_ide_url" {
  description = "URL for the Antigravity IDE installation package"
  type        = string
  default     = "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.1.1-6123990880747520/linux-x64/Antigravity%20IDE.tar.gz"
}

# -------------------------------------------------------------------
# CLI Tools Configuration
# -------------------------------------------------------------------

variable "install_agy" {
  description = "Whether to install Antigravity CLI (agy)"
  type        = bool
  default     = true
}

variable "install_uv" {
  description = "Whether to install uv (Python package installer)"
  type        = bool
  default     = true
}

variable "install_claude" {
  description = "Whether to install Claude Code"
  type        = bool
  default     = true
}

# -------------------------------------------------------------------
# API Timing Configuration
# -------------------------------------------------------------------

variable "api_activation_wait" {
  description = "Duration to wait after enabling APIs (e.g., '30s')"
  type        = string
  default     = "10s"
}

variable "org_policy_wait" {
  description = "Duration to wait after setting organization policies (e.g., '60s')"
  type        = string
  default     = "60s"
}
