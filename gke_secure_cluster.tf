// ==============================================================================
// gke_secure_cluster.tf
// Source: OZAT Engineering Blog (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/gke_secure_cluster.tf
// ==============================================================================

# gke_secure_cluster.tf
# FinTech үшін жеке GKE кластерін құрамыз

resource "google_container_cluster" "fintech_secure_cluster" {
  name     = "fintech-core-cluster"
  location = "europe-west3" # Франкфурт (егер жергілікті ХҚО болмаса, әдетте көптеген юрисдикцияларды қанағаттандырады)

  # Дефолтты түйіндер пулын өшіреміз, біз қажетті саясаттары бар кастомды пул құрамыз
  remove_default_node_pool = true
  initial_node_count       = 1

  # Жеке кластер: түйіндерде ақ IP жоқ
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

  # Kubernetes құпияларын (etcd) шифрлау үшін Cloud KMS-пен интеграция
  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.k8s_secrets.id
  }

  # Workload Identity - JSON кілттеріндегі сервистік аккаунттармен қоштасыңыз!
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
    
    # Shielded VMs - бутлоадер деңгейіндегі өзгерістер мен руткиттерден қорғау
    shielded_instance_config {
      enable_secure_boot = true
      enable_integrity_monitoring = true
    }

    # Минималды құқықтары бар сервистік аккаунт (Least Privilege)
    service_account = google_service_account.gke_sa.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
