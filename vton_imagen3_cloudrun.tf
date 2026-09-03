# ==============================================================================
# Terraform for VTON Backend
# Source: OZAT Engineering Hub (https://ozat.kz)
# GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/vton_imagen3_cloudrun.tf
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
variable "region" { default = "europe-west1" } # Cloud Run
variable "vertex_region" { default = "us-central1" } # Imagen 3 Availability

provider "google" {
  project = var.project_id
  region  = var.region
}

# Активация API Vertex AI
resource "google_project_service" "aiplatform" {
  service = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

# Сервисный аккаунт для Cloud Run с доступом к Vertex AI
resource "google_service_account" "vton_sa" {
  account_id   = "vton-backend-sa"
  display_name = "SA for VTON Cloud Run"
}

resource "google_project_iam_member" "vertex_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.vton_sa.email}"
}

# Cloud Run микросервис
resource "google_cloud_run_v2_service" "vton_backend" {
  name     = "vton-bot-backend"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.vton_sa.email
    scaling {
      max_instance_count = 5
    }
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/apps/vton-backend:latest"
      resources {
        limits = {
          memory = "1024Mi"
          cpu    = "1"
        }
      }
      env {
        name  = "VERTEX_LOCATION"
        value = var.vertex_region
      }
    }
  }
  depends_on = [google_project_iam_member.vertex_user]
}
