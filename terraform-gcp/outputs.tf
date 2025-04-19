output "bucket_name" {
  description = "Nome del bucket creato"
  value       = google_storage_bucket.data_bucket.name
}

output "bucket_url" {
  description = "URL del bucket"
  value       = "gs://${google_storage_bucket.data_bucket.name}/"
}

output "raw_folder_path" {
  description = "Path alla cartella raw"
  value       = "gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.raw_folder.name}"
}

output "processed_folder_path" {
  description = "Path alla cartella processed"
  value       = "gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.processed_folder.name}"
}

output "model_folder_path" {
  description = "Path alla cartella model"
  value       = "gs://${google_storage_bucket.data_bucket.name}/${google_storage_bucket_object.model_folder.name}"
}

output "docker_repo_name" {
  description = "Nome del repository Docker creato"
  value       = google_artifact_registry_repository.docker_repo.name
}
