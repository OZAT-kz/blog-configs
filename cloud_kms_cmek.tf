// ==============================================================================
// Cloud KMS Customer-Managed Encryption Keys (Terraform)
// Source: OZAT Engineering Blog (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/cloud_kms_cmek.tf
// ==============================================================================

# cloud_kms_cmek.tf
# Дерекқор мен қойма үшін өзіміздің шифрлау кілттерімізді құрамыз

resource "google_kms_key_ring" "fintech_keyring" {
  name     = "fintech-keyring-v1"
  location = "europe-west3"
}

# Cloud SQL (PostgreSQL) дерекқорын шифрлауға арналған кілт
resource "google_kms_crypto_key" "db_crypto_key" {
  name            = "cloud-sql-encryption-key"
  key_ring        = google_kms_key_ring.fintech_keyring.id
  rotation_period = "7776000s" # Әр 90 күн сайын авто-ротация (PCI-DSS талабы)

  lifecycle {
    prevent_destroy = true # Кілттің кездейсоқ жойылуынан (және барлық деректерді жоғалтудан) қорғау
  }
}

# Cloud SQL сервистік аккаунтына осы кілтті пайдалану құқығын тағайындаймыз
resource "google_kms_crypto_key_iam_binding" "sql_kms_binding" {
  crypto_key_id = google_kms_crypto_key.db_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${var.project_number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
  ]
}
