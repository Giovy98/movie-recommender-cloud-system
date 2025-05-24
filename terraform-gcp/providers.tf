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
    organization = "ORG_NAME" 

    workspaces {
      name = "WORKSPACE_NAME" 
    }
    
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}
