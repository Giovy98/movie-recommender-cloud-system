resource "google_project_service" "api" {
  for_each           = toset(local.apis)
  service            = each.key
  disable_on_destroy = false
}

resource "google_storage_bucket" "data_bucket" {
  depends_on                  = [google_project_service.api]
  name                        = "dataset-sistema-raccomandazione-terraform"
  location                    = local.region
  force_destroy               = true
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "raw_folder" {
  name    = "raw/"
  bucket  = google_storage_bucket.data_bucket.name
  content = " "
}

resource "google_storage_bucket_object" "processed_folder" {
  name    = "processed/"
  bucket  = google_storage_bucket.data_bucket.name
  content = " "
}

resource "google_storage_bucket_object" "model_folder" {
  name    = "model/"
  bucket  = google_storage_bucket.data_bucket.name
  content = " "
}

resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = "docker-repository-terraform"
  location      = "us-west1"
  format        = "DOCKER"
  description   = "Repository per immagini Docker creata tramite Terraform"

  provider   = google
  depends_on = [google_project_service.api]
}
