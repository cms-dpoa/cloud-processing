## Terraform scripts for a GKE Standard Cluster with an NFS disk

### Prerequisites


Install `gcloud` installed

Have a GCP project available, check them with

```
gcloud projects list
```

Check the current project with

```
gcloud config list
```

Change the project if needed with:

```
gcloud config set project <PROJECT_ID>
```

Install terraform: follow Ubuntu/Debian in https://developer.hashicorp.com/terraform/install

Install kubectl:
- either [on its own](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management) or with [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Get the code

Clone the code using ssh ([generate the ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux) and [add it to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=webui)):

```
git clone git@github.com:cms-dpoa/cloud-processing.git
cd cloud-processing/standard-gke-cluster-nfs
```

### Create the cluster

Set `project_id`, `region`, `name` and `service_acc` in `terraform.tfvars` to the desired values.
It might be necessary to specify a zone, rather than a region for the `region`-variable.
See regions and zones here: https://cloud.google.com/compute/docs/regions-zones

The `name`-variable will be used to set the name of the gke cluster and other resources as in the following example: 

```
"cluster-<NAME>"
```

`service_acc` specifies the filename of a service account .json-file to ensure valid permissions for creating cloud resources.

Initialize terraform:

```
terraform init
```

Check what will created:

```
terraform plan
```

Create the resources

```
terraform apply
```

### Check the cluster

Connect to the cluster with

```
gcloud container clusters get-credentials <CLUSTER_NAME> --region <REGION> --project <PROJECT_ID>
```

The cluster name is `cluster-<N>` where `<N>` is `name` as defined in `terraform.tfvars`.

Use `kubectl` to inspect the cluster, e.g.

```
kubectl get all
```

```
kubectl get nodes
```

```
kubectl get pv
```

```
kubectl get ns
```

```
kubectl get all -n argo
```

### Use the cluster

Install the argo workflows CLI following the instructions in https://github.com/argoproj/argo-workflows/releases/

The `argo` subdirectory has these example workflows:

- argo_pf_start.yaml: runs 6 parallel jobs with resource requests so that there will be only one job on each node. Can be used to make sure that the container image is pulled to each node and to monitor the resource needs before launching the production.
- argo_pfnano_nomerge_single.yaml: an example workflow with 24 parallel jobs.

Set the `claimName` in the .yaml file(s) according to the name of the nfs-disk that was deployed via terraform.
It should be in the format `nfs-<name>`, where `<name>` refers to the name given in `terraform.tfvars`.

Submit the job with this command after changing the filename to the desired workflow file:
```
argo submit argo_pf_start.yaml -n argo 
```

### Destroy the resource

Destroy resources with

```
terraform destroy
```




