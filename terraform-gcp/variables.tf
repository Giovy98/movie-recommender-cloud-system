variable "project_id" {
  description = "ID del progetto GCP"
  type        = string
}

variable "bucket_name" {
  description = "Nome del bucket GCS"
  type        = string
}

variable "artifact_repository" {
  description = "Nome dell'Artifact Registry"
  type        = string
}

variable "region" {
  description = "Regione GCP"
  type        = string
}

variable "gke_node_service_account_email" {
  description = "Email del service account per i nodi GKE"
  type        = string
}
