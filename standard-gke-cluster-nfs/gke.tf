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
    disk_type    = "pd-standard"
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
    labels = {
      env = var.project_id
    }
  }
}

resource "google_compute_disk" "default" {
  name = "gce-nfs-disk-${var.name}"
  type = "pd-standard"
  size = var.persistent_disk_size
  zone  = var.region
}
