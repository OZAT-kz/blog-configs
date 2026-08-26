// ==============================================================================
// gke_secure_cluster.tf
// Source: OZAT Engineering Blog (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/gke_secure_cluster.tf
// ==============================================================================

# gke_secure_cluster.tf
# Создаем приватный GKE кластер для FinTech

resource "google_container_cluster" "fintech_secure_cluster" {
  name     = "fintech-core-cluster"
  location = "europe-west3" # Frankfurt (обычно устраивает большинство юрисдикций, если нет локальных ЦОД)

  # Отключаем дефолтный пул узлов, мы создадим кастомный с нужными политиками
  remove_default_node_pool = true
  initial_node_count       = 1

  # Приватный кластер: узлы не имеют белых IP
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "10.0.0.0/8"
      display_name = "Corporate VPN"
    }
  }

  # Интеграция с Cloud KMS для шифрования секретов Kubernetes (etcd)
  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.k8s_secrets.id
  }

  # Workload Identity - прощайте сервисные аккаунты в JSON ключах!
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "secure_nodes" {
  name       = "secure-node-pool"
  cluster    = google_container_cluster.fintech_secure_cluster.id
  node_count = 3

  node_config {
    machine_type = "e2-standard-4"
    
    # Shielded VMs - защита от руткитов и изменений на уровне бутлоадера
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }

    # Сервисный аккаунт с минимальными правами (Least Privilege)
    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
