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
    name                    = "gke-vpc"
    routing_mode            = "REGIONAL"
    auto_create_subnetworks = false
    delete_default_routes_on_create = true
    depends_on = [google_project_service.api]
}

# subnet pubblica
resource "google_compute_subnetwork" "public" { 
  name                     = "public"
  ip_cidr_range            = "10.0.0.0/19" #Riserva un range di IP privati.
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # Le VM possono accedere ai servizi Google 
  stack_type               = "IPV4_ONLY"
}

# subnet privata
resource "google_compute_subnetwork" "private" {
  name                     = "private"
  ip_cidr_range            = "10.0.32.0/19" 
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true
  stack_type               = "IPV4_ONLY"

  secondary_ip_range{
    range_name = "k8s-pods"
    ip_cidr_range = "172.16.0.0/14" # Range di IP privati per i pod
  }
  secondary_ip_range {
    range_name = "k8s-services"
    ip_cidr_range = "172.20.0.0/18" # Range di IP privati per i servizi
  }
}
resource "google_compute_route" "default_route" {
  name             = "default-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

resource "google_container_cluster" "gke_cluster" {
  name     = "gke-cluster"
  location = "us-west1-a"

  remove_default_node_pool = true
  initial_node_count       = 3

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.private.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pods"
    services_secondary_range_name = "k8s-services"
  }

  private_cluster_config {
    enable_private_nodes = false
  }

  depends_on = [google_project_service.api]
}

resource "google_container_node_pool" "default_pool" {
  name       = "default-pool"
  cluster    = google_container_cluster.gke_cluster.name
  location   = "us-west1-a"

  initial_node_count = 3

  autoscaling {
    min_node_count = 3
    max_node_count = 6
  }

  node_config {
    machine_type = "e2-medium"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    tags = ["gke-node"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}




