// ==============================================================================
// Бан Директа в пятницу вечером: Как за 15 минут поднять аварийный Web-каталог на Cloud Run, пока Instagram-магазин в нокауте
// Source: OZAT Engineering Hub (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/cloud_run_emergency_catalog_ru.tf
// ==============================================================================

# Развертывание аварийного сервиса в Google Cloud Run
resource "google_cloud_run_v2_service" "emergency_catalog" {
  name     = "emergency-catalog-service"
  location = "asia-southeast1" # Ближайший регион с минимальной задержкой к РК
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0  # Масштабирование в ноль для экономии бюджета
      max_instance_count = 10 # Защита от перегрузки при резком наплыве
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

# Разрешаем публичный доступ к каталогу
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name     = google_cloud_run_v2_service.emergency_catalog.name
  location = google_cloud_run_v2_service.emergency_catalog.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
