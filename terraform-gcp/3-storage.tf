# Creazione del bucket GCS
resource "google_storage_bucket" "data_bucket" {
  depends_on = [google_project_service.api]
  name    = "dataset-sistema-raccomandazione-terraform" # nome del bucket
  location = local.region # regione scelta
  force_destroy = true # permette di eliminare il bucket anche se contiene oggetti

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}
 
resource "google_storage_bucket_object" "raw_folder" {
    name   = "raw/" # nome della cartella
    bucket = google_storage_bucket.data_bucket.name # bucket creato sopra
    content = " " # contenuto vuoto
}

resource "google_storage_bucket_object" "processed_folder" {
    name   = "processed/" # nome della cartella
    bucket = google_storage_bucket.data_bucket.name # bucket creato sopra
    content = " " # contenuto vuoto
}

resource "google_storage_bucket_object" "model_folder" {
    name   = "model/" # nome della cartella
    bucket = google_storage_bucket.data_bucket.name # bucket creato sopra
    content = " " # contenuto vuoto
}


