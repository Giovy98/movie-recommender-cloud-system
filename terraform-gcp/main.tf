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

# --- Cluster GKE Regionale Privato (Identico a prima) ---
resource "google_container_cluster" "primary" {
  name     = "gke-cluster-1" # Nome del tuo cluster GKE
  location = local.region    # Usa la stessa regione delle altre risorse

  # Networking
  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.private.id # Usa la subnet privata
  logging_service    = "logging.googleapis.com/kubernetes" # Abilita Cloud Logging (raccomandato)
  monitoring_service = "monitoring.googleapis.com/kubernetes" # Abilita Cloud Monitoring (raccomandato)
  networking_mode = "VPC_NATIVE" # Obbligatorio per usare range secondari

  # Configurazione VPC-Native (usa i range secondari definiti nella subnet "private")
  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.private.secondary_ip_range[1].range_name # "k8s-services"
    services_secondary_range_name = google_compute_subnetwork.private.secondary_ip_range[0].range_name # "k8s-pods"
  }

  # Configurazione Cluster Privato
  private_cluster_config {
    enable_private_endpoint = true  # Il Control Plane ha solo IP privato
    enable_private_nodes    = true  # I Nodi hanno solo IP privati
    master_ipv4_cidr_block  = "192.168.10.0/28" # Range privato /28 *NON* sovrapposto per il Control Plane GKE. Scegli un range libero nella tua VPC.
    # master_global_access_config { # Disabilita l'accesso globale al private endpoint (opzionale, più sicuro)
    #   enabled = false
    # }
  }

   # Rete autorizzata per accedere al Control Plane GKE
   master_authorized_networks_config {
     cidr_blocks {
       cidr_block   = google_compute_subnetwork.private.ip_cidr_range
       display_name = "Private Subnet Range"
     }
     cidr_blocks {
        cidr_block = google_compute_subnetwork.public.ip_cidr_range
        display_name = "Public Subnet Range"
     }
    #  cidr_blocks { # Se vuoi accedere da kubectl tramite NAT Gateway (meno sicuro di IAP/Bastion)
    #    cidr_block   = "${google_compute_address.nat.address}/32"
    #    display_name = "NAT Gateway IP"
    #  }
   }

   # Abilita Network Policy (Calico) per sicurezza a livello di rete tra pod
   network_policy {
     enabled = true
   }

  # Rimuoviamo il node pool di default per crearne uno personalizzato
  remove_default_node_pool = true
  initial_node_count       = 1 # Richiesto anche se si rimuove il default node pool

  depends_on = [
    google_project_service.api,
    google_compute_subnetwork.private,
    google_compute_router_nat.nat # Assicura che il NAT sia pronto se i nodi devono scaricare da internet al boot
  ]

  # Specifica la versione minima del master (opzionale, ma buona pratica)
  # Puoi usare una versione specifica o un canale (RAPID, REGULAR, STABLE)
  # min_master_version = "1.29" # Esempio, controlla le versioni disponibili

  # Abilita l'uso di Workload Identity (raccomandato per accesso sicuro ai servizi GCP dai pod)
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog" # Assicurati di avere var.project_id
  }
}

# --- Node Pool Personalizzato GKE ---
resource "google_container_node_pool" "primary_nodes" {
  name       = "default-pool" # Nome del node pool
  location   = local.region
  cluster    = google_container_cluster.primary.name
  node_count = 1 # Numero iniziale di nodi (puoi abilitare l'autoscaling)

  # Configurazione dei nodi
  node_config {
    machine_type = "e2-medium" # Scegli il tipo di macchina
    disk_size_gb = 30          # Dimensione del disco di boot
    disk_type    = "pd-standard" # Tipo di disco

    # >>> MODIFICA CHIAVE: Usa il Service Account ESISTENTE fornito dalla variabile <<<
    service_account = var.existing_gke_sa_email
    # -----------------------------------------------------------------------------

    oauth_scopes = [ # Definisci gli scope necessari per le API GCP
      "https://www.googleapis.com/auth/cloud-platform" # Scope ampio, o più granulare:
    ]

    # Metadata raccomandati
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Tag di rete (utili per regole firewall specifiche)
    tags = ["gke-node", "${google_container_cluster.primary.name}-node"]
  }

  # Gestione del Node Pool (auto-riparazione e auto-upgrade raccomandati)
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Opzionale: Abilita Autoscaling
   autoscaling {
     min_node_count = 1
     max_node_count = 5
   }

  # Aggiornato depends_on: Rimosso dipendenze dai permessi IAM non più gestiti qui
  depends_on = [
    google_container_cluster.primary
  ]
}