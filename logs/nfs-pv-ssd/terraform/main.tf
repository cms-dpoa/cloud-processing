resource "google_container_cluster" "primary" {
  name     = "nfs-pvc-cluster-las-vegas"
  location = "us-west4-a"

  node_pool {
    name       = "default-pool"
    initial_node_count = 1
    node_config {
      machine_type = "e2-medium"  # Specify the appropriate machine type
      disk_size_gb = 100
      disk_type    = "pd-ssd"
    }
  }

  network = "default"

}
