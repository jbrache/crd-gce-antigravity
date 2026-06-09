# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is a documentation repository that provides step-by-step instructions for setting up a Google Compute Engine (GCE) instance with Chrome Remote Desktop and installing Antigravity tools (Hub, IDE, and CLI). The setup also includes common development tools like Docker, Node.js, VS Code, and Claude Code itself.

## Key Components

### Startup Script
The main technical artifact is a bash startup script (`crdhost-autoinstall-startup-script.sh`) embedded in the README.md that:
- Installs Chrome Remote Desktop
- Sets up XFCE and/or Cinnamon desktop environments
- Installs Google Chrome
- Configures the desktop session for remote access

This script is uploaded to a GCS bucket and referenced via the `--metadata=startup-script-url` parameter when creating the GCE instance.

### Environment Configuration
When working with this setup, the following environment variables are required and should be set in `~/.bashrc`:

- `CLAUDE_CODE_USE_VERTEX=1` - Enables Vertex AI integration for Claude Code
- `CLOUD_ML_REGION=global` - GCP region for ML services
- `ANTHROPIC_VERTEX_PROJECT_ID=<your-project-id>` - Your GCP project ID for Anthropic/Claude
- `GOOGLE_GENAI_USE_ENTERPRISE=true` - Use enterprise Gemini features
- `GOOGLE_GENAI_USE_VERTEXAI=true` - Use Vertex AI for Gemini
- `GOOGLE_CLOUD_LOCATION=global` - Default GCP location
- `GOOGLE_CLOUD_PROJECT=<your-project-id>` - Your GCP project ID

### Project ID Placeholders
The README contains `<your-project-id>` placeholders that must be replaced with actual GCP project IDs before use. When editing documentation, preserve this pattern for user customization.

## GCP Commands

The setup process uses these primary GCP commands:

```bash
# Create a GCS bucket for startup scripts
gcloud storage buckets create gs://${BUCKET_NAME} --location=us-central1

# Upload startup script to bucket
gcloud storage cp <script> gs://${BUCKET_NAME}/crdhost/<script>

# Create a GCE instance with remote desktop
gcloud compute instances create ${INSTANCE_NAME} \
    --machine-type=e2-standard-16 \
    --image-project=debian-cloud \
    --image-family=debian-12 \
    --boot-disk-size=200GB \
    --no-address \
    --metadata=startup-script-url=gs://${BUCKET_NAME}/crdhost/crdhost-autoinstall-startup-script.sh \
    --zone=us-central1-a
```

## Troubleshooting

Startup script logs can be checked inside the VM with:
```bash
# Re-run the startup script manually
sudo google_metadata_script_runner startup

# View startup script logs
sudo journalctl -u google-startup-scripts.service
```

## Repository Structure

This is a documentation-only repository. The .gitignore includes patterns for Terraform files (`.tfstate`, `.tfvars`, `.terraform/`), suggesting potential future infrastructure-as-code additions, but no Terraform files currently exist.