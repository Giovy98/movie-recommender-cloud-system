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
    organization = "organization_name" # Replace with your Terraform Cloud organization name

    workspaces {
      name = "workspace_name" # Replace with your desired workspace name
    }
    
  }
}

provider "google" {
  project = local.project_id
  region  = local.region
}
