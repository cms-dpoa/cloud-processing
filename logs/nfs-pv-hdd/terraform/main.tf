resource "google_container_cluster" "primary" {
  name     = "nfs-hdd-cluster-finland"
  location = "europe-north1-a"

  node_pool {
    name              = "default-pool"
    initial_node_count = 1
    node_config {
      machine_type = "e2-medium"  # Specify the appropriate machine type
      disk_size_gb = 100
      disk_type    = "pd-standard"  # Specifies HDD type
    }
  }

  network = "default"
}
