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

variable "zone" {
  description = "Zona GCP"
  type = string
}

variable "gke_sa_email" {
  description = "L'indirizzo email del Service Account esistente da usare per i nodi GKE."
  type        = string
}

variable "gke_cluster_name" {
  description = "Nome del cluster GKE"
  type        = string
  
}


