// ==============================================================================
// cloud_kms_cmek.tf
// Source: OZAT Engineering Blog (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/cloud_kms_cmek.tf
// ==============================================================================

# cloud_kms_cmek.tf
# Создаем собственные ключи шифрования для базы данных и хранилища

resource "google_kms_key_ring" "fintech_keyring" {
  name     = "fintech-keyring-v1"
  location = "europe-west3"
}

# Ключ для шифрования базы данных Cloud SQL (PostgreSQL)
resource "google_kms_crypto_key" "db_crypto_key" {
  name            = "cloud-sql-encryption-key"
  key_ring        = google_kms_key_ring.fintech_keyring.id
  rotation_period = "7776000s" # Авто-ротация каждые 90 дней (требование PCI-DSS)

  lifecycle {
    prevent_destroy = true # Защита от случайного удаления ключа (и потери всех данных)
  }
}

# Назначаем права сервисному аккаунту Cloud SQL на использование этого ключа
resource "google_kms_crypto_key_iam_binding" "sql_kms_binding" {
  crypto_key_id = google_kms_crypto_key.db_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${var.project_number}@gcp-sa-cloud-sql.iam.gserviceaccount.com",
  ]
}
