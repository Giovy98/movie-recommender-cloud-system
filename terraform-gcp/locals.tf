locals {
  project_id = var.project_id           # id del progetto
  region     = var.region               # regione scelta
  zone       = var.zone                     # zona scelta
  apis = [                              # api utilizzate
    "storage-component.googleapis.com", # per il bucket
    "artifactregistry.googleapis.com",  # per il repository
    "compute.googleapis.com",           # per la  vpc 
    "container.googleapis.com",         # per il cluster GKE
  ]
  tfc_organization = var.tfc_organization # nome dell'organizzazione in Terraform Cloud
  tfc_workspace = var.tfc_workspace       # nome del workspace in Terraform Cloud

}