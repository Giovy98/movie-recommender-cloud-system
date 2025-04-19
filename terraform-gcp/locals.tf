locals {
  project_id = var.project_id           # id del progetto
  region     = "us-central1"            # regione scelta
  apis = [                              # api utilizzate
    "storage-component.googleapis.com", # per il bucket
    "artifactregistry.googleapis.com",  # per il registry
    "iamcredentials.googleapis.com"     # per il service account
  ]
}