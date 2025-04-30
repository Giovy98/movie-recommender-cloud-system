locals {
  project_id = var.project_id           # id del progetto
  region     = var.region            # regione scelta
  apis = [                              # api utilizzate
    "storage-component.googleapis.com", # per il bucket
    "artifactregistry.googleapis.com",  # per il registry
    "compute.googleapis.com", # per VPC e subnet
    "container.googleapis.com", # per gestire k8s  
  ]
}