resource "google_artifact_registry_repository" "docker_repo" {
    repository_id = "docker-repository-terraform" # id del repository
    provider = google
    location = "us-west1" # regione scelta
    format   = "DOCKER" # formato del repository
    description = "Repository per immagini Docker creata tramite Terraform" # descrizione del repository

    depends_on = [google_project_service.api]
  
}