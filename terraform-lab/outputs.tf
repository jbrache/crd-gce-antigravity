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
# GCE Instance Outputs
# -------------------------------------------------------------------

output "instance_name" {
  description = "Name of the GCE instance"
  value       = google_compute_instance.crd_instance.name
}

output "instance_id" {
  description = "ID of the GCE instance"
  value       = google_compute_instance.crd_instance.id
}

output "instance_zone" {
  description = "Zone of the GCE instance"
  value       = google_compute_instance.crd_instance.zone
}

output "instance_internal_ip" {
  description = "Internal IP address of the GCE instance"
  value       = google_compute_instance.crd_instance.network_interface[0].network_ip
}

# -------------------------------------------------------------------
# Network Outputs
# -------------------------------------------------------------------

output "vpc_network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc_network.id
}

output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc_network.name
}

output "subnet_id" {
  description = "The ID of the GCE subnet"
  value       = google_compute_subnetwork.gce_subnet.id
}

output "subnet_name" {
  description = "The name of the GCE subnet"
  value       = google_compute_subnetwork.gce_subnet.name
}

# -------------------------------------------------------------------
# GCS Outputs
# -------------------------------------------------------------------

output "startup_script_bucket" {
  description = "Name of the GCS bucket containing the startup script"
  value       = google_storage_bucket.startup_scripts.name
}

output "startup_script_url" {
  description = "GCS URL of the startup script"
  value       = "gs://${google_storage_bucket.startup_scripts.name}/${google_storage_bucket_object.startup_script.name}"
}

# -------------------------------------------------------------------
# Service Account Outputs
# -------------------------------------------------------------------

output "service_account_email" {
  description = "Email of the GCE service account"
  value       = google_service_account.gce_sa.email
}

output "service_account_id" {
  description = "ID of the GCE service account"
  value       = google_service_account.gce_sa.id
}

# -------------------------------------------------------------------
# Access Outputs
# -------------------------------------------------------------------

output "ssh_iap_command" {
  description = "gcloud command to SSH into the instance via IAP"
  value       = "gcloud compute ssh ${google_compute_instance.crd_instance.name} --zone=${google_compute_instance.crd_instance.zone} --tunnel-through-iap --project=${var.gcp_project_id}"
}

output "gce_console_url" {
  description = "URL to the GCE instance in the Cloud Console"
  value       = "https://console.cloud.google.com/compute/instancesDetail/zones/${google_compute_instance.crd_instance.zone}/instances/${google_compute_instance.crd_instance.name}?project=${var.gcp_project_id}"
}

output "startup_script_logs_command" {
  description = "Command to view startup script logs (run inside the VM)"
  value       = "sudo journalctl -u google-startup-scripts.service"
}
