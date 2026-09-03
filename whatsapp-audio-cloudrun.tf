# ==============================================================================
# Terraform for WhatsApp Voice Bot
# Source: OZAT Engineering Hub (https://ozat.kz)
# GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/whatsapp-audio-cloudrun.tf
# ==============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" { type = string }
variable "region" { default = "europe-west1" }

provider "google" {
  project = var.project_id
  region  = var.region
}

# Secret Manager 
resource "google_secret_manager_secret" "api_keys" {
  for_each = toset(["gemini-api-key", "whatsapp-token", "moysklad-token"])
  secret_id = each.value
  replication { auto {} }
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "voice_to_crm" {
  name     = "whatsapp-voice-to-crm"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/apps/whatsapp-voice-crm:latest"
      
      env {
        name = "GEMINI_API_KEY"
        value_source { secret_key_ref { secret = "gemini-api-key"; version = "latest" } }
      }
      env {
        name = "WHATSAPP_ACCESS_TOKEN"
        value_source { secret_key_ref { secret = "whatsapp-token"; version = "latest" } }
      }
      env {
        name = "MOYSKLAD_API_TOKEN"
        value_source { secret_key_ref { secret = "moysklad-token"; version = "latest" } }
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.voice_to_crm.name
  location = google_cloud_run_v2_service.voice_to_crm.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
