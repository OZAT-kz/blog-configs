// ==============================================================================
// AdSense-монетизация для блогеров: от унизительного бартера к валютной выручке на Cloud Run и Next.js
// Source: OZAT Engineering Hub (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/cloud_run_media_hub_cdn_ru.tf
// ==============================================================================

# Terraform манифест для Cloud Run и Cloud CDN
resource "google_cloud_run_v2_service" "media_hub" {
  name     = "influencer-media-hub"
  location = "asia-southeast1"
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling {
      min_instance_count = 0  # Нулевые расходы при отсутствии трафика
      max_instance_count = 8  # Плавное масштабирование до 800 rps
    }

    containers {
      image = "asia-southeast1-docker.pkg.dev/ozatkz-project/media-repo/hub-app:v1"

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

# Активация Serverless Network Endpoint Group (NEG) для CDN
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "media-hub-serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = "asia-southeast1"
  cloud_run {
    service = google_cloud_run_v2_service.media_hub.name
  }
}

# Бэкенд-сервис с включенным Cloud CDN и кешированием статики
resource "google_compute_backend_service" "cdn_backend" {
  name                  = "media-hub-cdn-backend"
  protocol              = "HTTPS"
  enable_cdn            = true
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }

  cdn_policy {
    cache_mode                   = "CACHE_ALL_STATIC"
    default_ttl                  = 3600
    client_ttl                   = 7200
    max_ttl                      = 86400
    serve_while_stale            = 86400
    negative_caching             = true
  }
}
