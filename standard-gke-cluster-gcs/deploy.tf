resource "kubernetes_namespace" "namespace1" {
  metadata {
    name = "argo"
  }
  depends_on = [
    google_container_node_pool.cluster1_nodes
  ]
}

# $ gcloud iam service-accounts add-iam-policy-binding bucket-access@<project-name>.iam.gserviceaccount.com --role roles/iam.workloadIdentityUser --member "serviceAccount:<project-name>.svc.id.goog[argo/default]"

# SYNOPSIS
#     gcloud iam service-accounts add-iam-policy-binding SERVICE_ACCOUNT
#         --member=PRINCIPAL --role=ROLE
#         [--condition=[KEY=VALUE,...]
#           | --condition-from-file=CONDITION_FROM_FILE] [GCLOUD_WIDE_FLAG ...]


# resource "google_service_account_iam_binding" "bucketbinding" {
#   service_account_id = "bucket-access@.iam.gserviceaccount.com"
#   role               = "roles/iam.workloadIdentityUser"<project-name>

#   members = [
#     "serviceAccount:<project-name>.svc.id.goog[argo/default]",
#   ]
# }

# $ kubectl annotate serviceaccount default -n argo iam.gke.io/gcp-service-account=bucket-access@<project-name>.iam.gserviceaccount.com

/* resource "kubernetes_annotations" "bucketannotation" {
  api_version = "v1"
  kind        = "ConfigMap"
  metadata {
    name = "my-config"
  }
  annotations = {
    "owner" = "myteam"
  }
}§ */