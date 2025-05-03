locals {
  service_account = var.sa_email        # email del service account
  project_id = var.project_id           # id del progetto
  region     = var.region               # regione scelta                    

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