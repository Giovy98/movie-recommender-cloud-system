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

# Regola vpc-gke-allow-custom
resource "google_compute_firewall" "vpc_gke_allow_custom" {
  name        = "vpc-gke-allow-custom"
  network     = google_compute_network.vpc.name
  description = "Consenti traffico custom da specifici intervalli IP"
  
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["10.0.0.0/19", "10.0.32.0/19"]
  
  allow {
    protocol = "all"
  }
}

# Regola vpc-gke-allow-icmp
resource "google_compute_firewall" "vpc_gke_allow_icmp" {
  name        = "vpc-gke-allow-icmp"
  network     = google_compute_network.vpc.name
  description = "Consenti traffico ICMP da qualsiasi fonte"
  
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]
  
  allow {
    protocol = "icmp"
  }
}

# Regola vpc-gke-allow-rdp
resource "google_compute_firewall" "vpc_gke_allow_rdp" {
  name        = "vpc-gke-allow-rdp"
  network     = google_compute_network.vpc.name
  description = "Consenti traffico RDP (porta 3389) da qualsiasi fonte"
  
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]
  
  allow {
    protocol = "tcp"
    ports    = ["3389"]
  }
}

# Regola vpc-gke-allow-ssh
resource "google_compute_firewall" "vpc_gke_allow_ssh" {
  name        = "vpc-gke-allow-ssh"
  network     = google_compute_network.vpc.name
  description = "Consenti traffico SSH (porta 22) da qualsiasi fonte"
  
  direction     = "INGRESS"
  priority      = 65534
  source_ranges = ["0.0.0.0/0"]
  
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# Regola vpc-gke-deny-all-ingress
resource "google_compute_firewall" "vpc_gke_deny_all_ingress" {
  name        = "vpc-gke-deny-all-ingress"
  network     = google_compute_network.vpc.name
  description = "Rifiuta tutto il traffico in ingresso"
  
  direction     = "INGRESS"
  priority      = 65535
  source_ranges = ["0.0.0.0/0"]
  
  deny {
    protocol = "all"
  }
}

# Regola vpc-gke-allow-all-egress
resource "google_compute_firewall" "vpc_gke_allow_all_egress" {
  name        = "vpc-gke-allow-all-egress"
  network     = google_compute_network.vpc.name
  description = "Consenti tutto il traffico in uscita"
  
  direction     = "EGRESS"
  priority      = 65535
  destination_ranges = ["0.0.0.0/0"]
  
  allow {
    protocol = "all"
  }
}




