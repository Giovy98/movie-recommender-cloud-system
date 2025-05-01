resource "google_project_service" "api" {
  for_each           = toset(local.apis)
  service            = each.key
  disable_on_destroy = false
}


resource "google_storage_bucket" "data_bucket" {
  name                        = var.bucket_name
  location                    = local.region
  force_destroy               = true
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.api]

  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "folders" {
  for_each = toset(["raw/", "processed/", "model/"])
  name     = each.key
  bucket   = google_storage_bucket.data_bucket.name
  content  = " "
}

resource "google_artifact_registry_repository" "docker_repo" {
  repository_id = var.artifact_repository
  location      = local.region
  format        = "DOCKER"
  description   = "Repository per immagini Docker creata tramite Terraform"
  depends_on    = [google_project_service.api]
}

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "gke-vpc"
  auto_create_subnetworks = true # Chiave per la semplicità!
  routing_mode            = "REGIONAL" # O "GLOBAL", per auto-mode di solito è REGIONAL

  depends_on = [google_project_service.api]
}

resource "google_container_cluster" "gke_cluster" {
  project  = var.project_id
  name     = "gke-cluster"
  location = local.region

  network = google_compute_network.vpc.id

  remove_default_node_pool = false
  initial_node_count       = 3 # Inizia con un singolo nodo nel pool di default

  ip_allocation_policy {}

  depends_on = [
    google_compute_network.vpc,
    google_project_service.api
  ]
}