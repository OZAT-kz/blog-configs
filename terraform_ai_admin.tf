// ==============================================================================
// «Алло, на реснички есть места?»: Голосовой AI-администратор для салонов красоты Алматы, который не ходит на обед
// Source: OZAT Engineering Hub (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/terraform_ai_admin.tf
// ==============================================================================

resource "google_cloud_run_v2_service" "ai_admin" {
  name     = "ai-salon-admin"
  location = "europe-west4"
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = "eu.gcr.io/my-project/ai-salon-admin:latest"
      
      env {
        name = "GEMINI_API_KEY"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret.gemini_key.secret_id
            version = "latest"
          }
        }
      }
      
      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }
    }
    
    # Scale to zero для малого бизнеса - это мастхэв!
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }
  }
}
