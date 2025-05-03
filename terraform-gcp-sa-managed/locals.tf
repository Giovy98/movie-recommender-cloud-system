locals {
  service_account = var.sa_email        # email del service account
  project_id = var.project_id           # id del progetto
  region     = var.region               # regione scelta
  zone       = var.zone                     # zona scelta
  apis = [                              # api utilizzate
    "storage-component.googleapis.com", # per il bucket
    "artifactregistry.googleapis.com",  # per il repository
    "compute.googleapis.com",           # per la  vpc 
    "container.googleapis.com",         # per il cluster GKE
  ]

  roles =  [
    "roles/artifactregistry.admin",
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    "roles/container.admin",
    "roles/iam.projectIamAdmin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/servicemanagement.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/storage.admin"
  ]
}