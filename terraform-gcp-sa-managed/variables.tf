variable "sa_email" {
  description = "L'indirizzo email del Service Account."
  type        = string
}
variable "project_id" {
  description = "ID del progetto GCP"
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

