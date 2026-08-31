// ==============================================================================
// Terraform for Instagram Gemini Bot on Cloud Run and Cloud Tasks
// Source: OZAT Engineering Hub (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/instagram-gemini-infrastructure.tf
// ==============================================================================

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.30.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = "europe-west1"
}

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}

# 1. Cloud Run Service для Webhook-шлюза
resource "google_cloud_run_v2_service" "instagram_bot" {
  name     = "instagram-direct-gemini-bot"
  location = "europe-west1"
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0 # Scale-to-zero для экономии (0 ₸ в простое)
      max_instance_count = 5
    }

    containers {
      image = "europe-west1-docker.pkg.dev/${var.project_id}/apps/instagram-bot:v1.0"
      
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      env {
        name  = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = "gemini-api-key"
            version = "latest"
          }
        }
      }

      env {
        name  = "INSTAGRAM_APP_SECRET"
        value_source {
          secret_key_ref {
            secret  = "instagram-app-secret"
            version = "latest"
          }
        }
      }
    }
  }
}

# 2. Cloud Tasks Queue для брошенных корзин и Follow-up уведомлений
resource "google_cloud_tasks_queue" "followups_queue" {
  name     = "instagram-followups"
  location = "europe-west1"

  rate_limits {
    max_dispatches_per_second = 10
    max_concurrent_dispatches = 5
  }

  retry_config {
    max_attempts = 3
    min_backoff  = "10s"
    max_backoff  = "300s"
  }
}

# 3. Публичный доступ к эндпоинту вебхуков Meta
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.instagram_bot.name
  location = google_cloud_run_v2_service.instagram_bot.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
