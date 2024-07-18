variable "project_id" {
  description = "project id"
}

variable "region" {
  description = "region"
}

variable "gke_num_nodes" {
  default     = 3
  description = "number of gke nodes"
}

variable "gke_machine_type" {
  default     = "e2-highmem-4"
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

