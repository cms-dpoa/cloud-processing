provider "google" {
  project = "gcs-bucket-subash"
  region  = "us-west4"
}
resource "google_compute_disk" "storage-nfs" {
  name  = "storage-nfs"
  zone  = "us-west4-a"
  type  = "pd-ssd"  # Specifies SSD type

  labels = {
    environment      = "nfs"
    goog-gke-volume  = ""
  }

  size = 100  # Size in GB
  physical_block_size_bytes = 4096
}
