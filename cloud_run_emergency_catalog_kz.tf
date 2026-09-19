// ==============================================================================
// Жұма кешіндегі Директ бұғаты: Instagram-дүкен нокаутта жатқанда, Cloud Run-да 15 минутта апаттық Web-каталогты қалай көтеруге болады
// Source: OZAT Engineering Hub (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/cloud_run_emergency_catalog_kz.tf
// ==============================================================================

# Google Cloud Run-да апаттық сервисті өрістету
resource "google_cloud_run_v2_service" "emergency_catalog" {
  name     = "emergency-catalog-service"
  location = "asia-southeast1" # Қазақстанға минималды кідірісі бар ең жақын аймақ
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0  # Бюджетті үнемдеу үшін нөлге дейін масштабтау
      max_instance_count = 10 # Күрт жүктеме кезінде артық шығыннан қорғау
    }

    containers {
      image = "asia-southeast1-docker.pkg.dev/ozatkz-project/catalog-repo/emergency-app:v1"

      resources {
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      env {
        name  = "NODE_ENV"
        value = "production"
      }
    }
  }
}

# Каталогқа жария қолжетімділікке рұқсат беру
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name     = google_cloud_run_v2_service.emergency_catalog.name
  location = google_cloud_run_v2_service.emergency_catalog.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
