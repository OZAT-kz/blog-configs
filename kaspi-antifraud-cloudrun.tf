# ==============================================================================
# Terraform Manifest for Cloud Run Anti-Fraud Microservice
# Source: OZAT Engineering Hub (https://ozat.kz)
# GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/kaspi-antifraud-cloudrun.tf
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

variable "region" {
  type        = string
  default     = "europe-west1"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Secret Manager для ключей Gemini и Telegram
resource "google_secret_manager_secret" "gemini_api_key" {
  secret_id = "gemini-api-key"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "telegram_token" {
  secret_id = "telegram-bot-token"
  replication {
    auto {}
  }
}

# Service Account с минимальными привилегиями
resource "google_service_account" "antifraud_sa" {
  account_id   = "kaspi-antifraud-service"
  display_name = "Kaspi Receipt Anti-Fraud Microservice SA"
}

# Роль доступа к Firestore
resource "google_project_iam_member" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.antifraud_sa.email}"
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "antifraud_service" {
  name     = "kaspi-receipt-antifraud"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.antifraud_sa.email
    
    scaling {
      min_instance_count = 0
      max_instance_count = 10
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/apps/kaspi-antifraud:latest"
      
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      env {
        name = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.gemini_api_key.secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "TELEGRAM_BOT_TOKEN"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.telegram_token.secret_id
            version = "latest"
          }
        }
      }

      env {
        name  = "TARGET_SHOP_NAME"
        value = "ИП Шоурум Алматы"
      }
    }
  }
}

# Публичный доступ для Webhook Telegram
resource "google_cloud_run_v2_service_iam_member" "public_webhook" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.antifraud_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
