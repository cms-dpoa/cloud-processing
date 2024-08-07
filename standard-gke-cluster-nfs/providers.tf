terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.6.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.23.0"
    }
  }
}

provider "google" {
  credentials = file(var.service_acc)
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${resource.google_container_cluster.cluster1.endpoint}"
  cluster_ca_certificate = base64decode(resource.google_container_cluster.cluster1.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}