# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# resource "google_service_account" "default" {
#   account_id   = "service-account-id"
#   display_name = "Service Account"
# }

data "google_client_config" "default" {}

resource "google_container_cluster" "cluster1" {
  name     = "cluster-${var.name}"
  location = var.region
  remove_default_node_pool = true
  initial_node_count       = 1 
  deletion_protection      = false
}

# Separately Managed Node Pool
resource "google_container_node_pool" "cluster1_nodes" {
  name       = google_container_cluster.cluster1.name
  location   = var.region
  cluster    = google_container_cluster.cluster1.name
  node_count = var.gke_num_nodes

  node_config {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    # service_account = google_service_account.default.email
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_node_disk_size
    disk_type    = var.gke_node_disk_type
    gcfs_config {
      enabled = true
    }
    secondary_boot_disks {
      disk_image = var.gke_image_disk_name
      mode       = "CONTAINER_IMAGE_CACHE"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels = {
      env = var.project_id
    }
  }
}
