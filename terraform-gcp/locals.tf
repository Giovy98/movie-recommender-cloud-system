locals {
  project_id = var.project_id           # id del progetto
  region     = var.region            # regione scelta
  apis = [                              # api utilizzate
    "storage-component.googleapis.com", # per il bucket
    "artifactregistry.googleapis.com",  # per il registry
  ]
}