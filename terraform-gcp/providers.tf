terraform {
  required_version = ">= 1.3"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "organization_name" # Rimpiazza con il nome dell'organizzazione di Terraform Cloud

    workspaces {
      name = "workspace_name" # Rimpiazza con il nome del workspace da te assegnato
    }
    
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}
