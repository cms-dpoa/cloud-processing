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

variable "persistent_disk_size" {
  default     = 100
  description = "Persistent disk size"
}

variable "persistent_disk_type" {
  default = "pd-standard"
  description = "Persistent disk type"
}

variable "persistent_claim_storage_request" {
  default     = "100Gi"
  description = "Persistent claim storage request"
}

variable "name" {
  default     = "1"
  description = "Cluster name"
}

variable "service_acc" {
  description = "service account file"
}