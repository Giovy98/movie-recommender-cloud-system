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
    name                    = "test-vpc"
    routing_mode            = "REGIONAL"
    auto_create_subnetworks = false
    delete_default_routes_on_create = true
   
   depends_on = [google_project_service.api]
}

resource "google_compute_subnetwork" "public" { # subnet pubblica
  name                     = "public"
  ip_cidr_range            = "10.0.0.0/19" #Riserva un range di IP privati.
  region                   = local.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # Le VM possono accedere ai servizi Google 
  stack_type               = "IPV4_ONLY"
}

# subnet privata
# Le VM non possono accedere a internet, ma possono accedere ai servizi Google
# Le VM possono accedere a internet tramite un NAT gateway
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

# Opzionale 
resource "google_compute_address" "nat" {
  name         = "nat-terraform"
  address_type = "EXTERNAL"
  network_tier = "Standard"

  depends_on = [google_project_service.api]
}

resource "google_compute_router" "router" {
  name    = "router-terraform"
  region  = local.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name   = "nat-router"
  region = local.region
  router = google_compute_router.router.name

  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ips                            = [google_compute_address.nat.self_link]

  subnetwork {
    name                    = google_compute_subnetwork.private.self_link
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8000", "8080","8501", "22"]
  }

  source_ranges = ["35.235.240.0/20"]
}