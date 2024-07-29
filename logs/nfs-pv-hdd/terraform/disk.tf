provider "google" {
  project = "gcs-bucket-subash"
  region  = "europe-north1"
}

resource "google_compute_disk" "storage-nfs" {
  name  = "storage-nfs"
  zone  = "europe-north1-a"
  type  = "pd-standard"  # Specifies HDD type

  labels = {
    environment      = "nfs"
    goog-gke-volume  = ""
  }

  size = 100  # Size in GB
  physical_block_size_bytes = 4096
}
