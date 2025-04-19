locals {
	project_id = "my-project-1531942571796" # id del progetto
	region     = "us-central1" # regione scelta
	apis = [ # api utilizzate
	"compute.googleapis.com", # per VPC e subnet
	"container.googleapis.com", # per gestire k8s
	"storage-component.googleapis.com", # per il bucket
	"artifactregistry.googleapis.com", # per il registry
	"iamcredentials.googleapis.com" # per il service account
	]
}