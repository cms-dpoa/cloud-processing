resource "kubernetes_namespace" "namespace1" {
  metadata {
    name = "argo"
  }
  depends_on = [
    google_container_node_pool.cluster1_nodes
  ]
}

//  001-nfs-server
resource "kubernetes_deployment" "nfs_server" {
  metadata {
    name      = "nfs-server-${var.name}"
    namespace = kubernetes_namespace.namespace1.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        role = "nfs-server-${var.name}"
      }
    }
    template {
      metadata {
        namespace = kubernetes_namespace.namespace1.metadata.0.name
        labels = {
          role = "nfs-server-${var.name}"
        }
      }
      spec {
        volume {
          name = "mypvc"
          gce_persistent_disk {
            pd_name = "gce-nfs-disk-${var.name}"
            fs_type = "ext4"
          }
        }
        container {
          name  = "nfs-server-${var.name}"
          image = "gcr.io/google_containers/volume-nfs:0.8"
          port {
            name           = "nfs"
            container_port = 2049
          }
          port {
            name           = "mountd"
            container_port = 20048
          }
          port {
            name           = "rpcbind"
            container_port = 111
          }
          volume_mount {
            name       = "mypvc"
            mount_path = "/exports"
          }
          security_context {
            privileged = true
          }
        }
      }
    }
  }
  depends_on = [
    google_container_node_pool.cluster1_nodes
  ]
}

//  002-nfs-server-service
resource "kubernetes_service" "nfs_server" {
  metadata {
    name      = "nfs-server-${var.name}"
    namespace = kubernetes_namespace.namespace1.metadata.0.name
  }
  spec {
    port {
      name = "nfs"
      port = 2049
    }
    port {
      name = "mountd"
      port = 20048
    }
    port {
      name = "rpcbind"
      port = 111
    }
    selector = {
      role = "nfs-server-${var.name}"
    }
  }
  depends_on = [
    google_container_node_pool.cluster1_nodes
  ]
}

//  003-pv-pvc
resource "kubernetes_persistent_volume" "nfs_pv" {
  metadata {
    name = "nfs-${var.name}"
  }
  spec {
    capacity = {
      storage = var.persistent_claim_storage_request
    }
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "standard"
    persistent_volume_source {
      nfs {
        server = resource.kubernetes_service.nfs_server.spec.0.cluster_ip
        path   = "/"
      }
    }
  }
  depends_on = [
    google_container_node_pool.cluster1_nodes
  ]
}

//  003-pv
resource "kubernetes_persistent_volume_claim" "nfs_pvc" {
  metadata {
    name      = "nfs-${var.name}"
    namespace = kubernetes_namespace.namespace1.metadata.0.name
  }
  spec {
    access_modes       = ["ReadWriteMany"]
    storage_class_name = "standard"
    resources {
      requests = {
        storage = var.persistent_claim_storage_request
      }
    }
    volume_name = kubernetes_persistent_volume.nfs_pv.metadata.0.name
  }
  depends_on = [
    kubernetes_persistent_volume.nfs_pv
  ]
}

//  pv-pod
resource "kubernetes_pod" "pv_pod" {
  metadata {
    name      = "pv-pod"
    namespace = kubernetes_namespace.namespace1.metadata.0.name
  }
  spec {
    volume {
      name = "task-pv-storage"
      persistent_volume_claim {
        claim_name = "nfs-${var.name}"
      }
    }
    container {
      name    = "pv-container"
      image   = "busybox"
      command = ["tail", "-f", "/dev/null"]
      volume_mount {
        name       = "task-pv-storage"
        mount_path = "/mnt/data"
      }
    }
  }
  depends_on = [
    google_container_node_pool.cluster1_nodes, kubernetes_persistent_volume_claim.nfs_pvc, kubernetes_deployment.nfs_server, 
    kubernetes_persistent_volume.nfs_pv, kubernetes_service.nfs_server
  ]
}
