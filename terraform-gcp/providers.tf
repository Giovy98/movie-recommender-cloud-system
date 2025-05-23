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
    organization = "giovy-team" 

    workspaces {
      name = "terraform-remote-state" 
    }
    
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}
