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
cd cloud-processing/standard-gke-cluster-gcs
```

### Create the bucket

The bucket has to be created separately since it is not included in the terraform deployments.
If using gcloud CLI, buckets can be created as following:

```
gcloud storage buckets create gs://<BUCKET_NAME> --location=<BUCKET_LOCATION>
```

More information can be found here: https://cloud.google.com/storage/docs/creating-buckets#storage-create-bucket-cli


### Create the cluster

Set `project_id`, `region` and `name` in `terraform.tfvars` to the desired values.
It might be necessary to specify a zone, rather than a region for the `region`-variable.
See regions and zones here: https://cloud.google.com/compute/docs/regions-zones

The `name`-variable will be used to set the name of the gke cluster and other resources as in the following example: 

```
"cluster-<NAME>"
```

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

- argo_bucket_start.yaml: runs 6 parallel jobs with resource requests so that there will be only one job on each node. Can be used to make sure that the container image is pulled to each node and to monitor the resource needs before launching the production.
- argo_bucket_run.yaml: an example workflow with 24 parallel jobs.

Change the bucket name in the workflow file to correspond to the bucket in use.
In other words, set the bucket `value` in the .yaml file(s) according to the name of the storage bucket (`<BUCKET_NAME>`) that was created earlier for storing the processing outputs.

Furthermore, the MiniAOD dataset that is to be processed is determined by its recid (record id). The placeholder `<RECID>` in the .yaml file(s) needs to be updated with the chosen recid value.
The datasets with their recids can be found on `https://opendata.cern.ch/`.
The recid is the number in the end of the url, so the following dataset: `https://opendata.cern.ch/record/30549` has the recid `30549`.

Submit the job with this command after changing the filename to the desired workflow file:
```
argo submit argo_bucket_start.yaml -n argo 
```

### Destroy the resource

Destroy resources with

```
terraform destroy
```





