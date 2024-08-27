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

Note that a Google Cloud billing account needs to be created and assigned to the GCP project that will be used with this repository.

In addition, several APIs will need to be enabled in Google Cloud, which can be done through the console or with the gcloud command:

```
gcloud services enable <SERVICE_NAME>
```

The APIs that might need to be enabled are:
- serviceusage.googleapis.com (Service Usage API)
- cloudresourcemanager.googleapis.com (Cloud Resource Manager API)
- container.googleapis.com (Kubernetes Engine API)
- compute.googleapis.com (Compute Engine API)

### Get the code

Clone the code using ssh ([generate the ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux) and [add it to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=webui)):

```
git clone git@github.com:cms-dpoa/cloud-processing.git
cd cloud-processing/standard-gke-cluster-nfs
```

### Create the cluster

Set `project_id`, `region` and `name` in `terraform.tfvars` to the desired values.
The `project_id` is the id of your GCP project and can be found via gcloud CLI command `gcloud projects list` or in the Google Cloud console when selecting a project.
As of now, Google cloud requires a zone rather than a region, so choose a zone for the `region`-variable.
A zone is usually just the region name followed by -a,-b or -c, i.e. `us-west1-a` instead of `us-west1`.
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

The cluster name is `cluster-<NAME>` where `<NAME>` is `name` as defined in `terraform.tfvars`.

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

Furthermore, the MiniAOD dataset that is to be processed is determined by its recid (record id). The placeholder `<RECID>` in the .yaml file(s) needs to be updated with the chosen recid value.
The datasets with their recids can be found on `https://opendata.cern.ch/`.
The recid is the number in the end of the url, so the following dataset: `https://opendata.cern.ch/record/30549` has the recid `30549`.

Submit the job with this command after changing the filename to the desired workflow file:
```
argo submit argo_pf_start.yaml -n argo 
```

### Destroy the resource

Destroy resources with

```
terraform destroy
```