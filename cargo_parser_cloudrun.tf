# ==============================================================================
# Terraform for Cargo Parser with Document AI
# Source: OZAT Engineering Hub (https://ozat.kz)
# GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/cargo_parser_cloudrun.tf
# ==============================================================================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" { type = string }
variable "region" { default = "europe-west1" }

provider "google" {
  project = var.project_id
  region  = var.region
}

# Активация API Document AI
resource "google_project_service" "documentai" {
  service = "documentai.googleapis.com"
  disable_on_destroy = false
}

# Создание Document AI Processor (OCR)
resource "google_document_ai_processor" "ocr_processor" {
  display_name = "cargo-ocr-processor"
  location     = "eu"
  type         = "OCR_PROCESSOR"
  depends_on   = [google_project_service.documentai]
}

# Секрет Gemini API
resource "google_secret_manager_secret" "gemini_key" {
  secret_id = "gemini-api-key"
  replication { auto {} }
}

# Cloud Run Service
resource "google_cloud_run_v2_service" "cargo_parser" {
  name     = "cargo-waybill-parser"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    scaling { max_instance_count = 10 }
    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/apps/cargo-parser:latest"
      
      env {
        name  = "DOCAI_PROCESSOR_ID"
        value = google_document_ai_processor.ocr_processor.id
      }
      env {
        name  = "DOCAI_LOCATION"
        value = "eu"
      }
      env {
        name = "GEMINI_API_KEY"
        value_source { secret_key_ref { secret = google_secret_manager_secret.gemini_key.secret_id; version = "latest" } }
      }
    }
  }
}
