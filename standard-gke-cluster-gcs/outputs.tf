output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.cluster1.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.cluster1.endpoint
  description = "GKE Cluster Host"
}

output "gke_num_nodes" {
  value       = var.gke_num_nodes
  description = "GKE cluster nodes"
}

output "gke_machine_type" {
  value       = var.gke_machine_type
  description = "GKE machine type"
}

output "gke_node_disk_size" {
  value       = var.gke_node_disk_size
  description = "GKE node disk size"
}