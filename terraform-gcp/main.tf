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
  network_tier = "STANDARD"

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

resource "google_container_cluster" "gke" {
  name                     = "testing-cluster"
  location                 = local.region
  remove_default_node_pool = true
  initial_node_count       = 3
  network                  = google_compute_network.vpc.self_link
  subnetwork               = google_compute_subnetwork.private.self_link
  networking_mode          = "VPC_NATIVE"

  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${local.project_id}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "k8s-pods"
    services_secondary_range_name = "k8s-services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "192.168.0.0/28"
  }

}

resource "google_service_account" "gke" {
  account_id = "demo-gke"
}

resource "google_container_node_pool" "general" {
  name    = "general"
  cluster = google_container_cluster.gke.id

  autoscaling {
    min_node_count = 3
    max_node_count = 6
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = "e2-medium"

    labels = {
      role = "general"
    }

    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}