variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "gke_num_nodes" {
  default     = 2
  description = "number of gke nodes"
}

variable "gke_machine_type" {
  default     = "e2-standard-4"
  description = "GKE machine type"
}

variable "gke_node_disk_size" {
  default     = 100
  description = "GKE node disk size"
}

variable "gke_node_disk_type" {
  default     = "pd-standard"
  description = "GKE node disk type"
}

variable "name" {
  default     = "1"
  description = "Cluster name"
}

variable "gke_image_disk_name" {
  default     = "global/images/pfnano-disk-image"
  description = "Secondary boot disk name"
}

