## Terraform scripts for a GKE Standard Cluster with a Google Cloud Storage (GCS) bucket and a secondary boot disk

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

([Generate a ssh key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent?platform=linux) and [add it to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account?tool=webui)), if not alreday done.

Prepare the secondary boot disk.

Create a bucket for the logs. This can be separate from the bucket for the output files, but it is created in the same way, see instructions below. Then use the code from [gke-disk-image-builder](https://github.com/GoogleCloudPlatform/ai-on-gke/tree/main/tools/gke-disk-image-builder) to build the disk. Note that the timeout time needs to be increased for the pfnano image (100m was enough).

### Get the code

Clone the code using:

```
git clone git@github.com:cms-dpoa/cloud-processing.git
cd cloud-processing/standard-gke-cluster-gcs
```

### Create the bucket

The bucket for the output files has to be created separately since it is not included in the terraform deployments.
Please make sure to use the same location for the bucket as the project.
With gcloud CLI, buckets can be created as following:

```
gcloud storage buckets create gs://<BUCKET_NAME> --location=<BUCKET_LOCATION>
```

To use the bucket, a service account and IAM policy binding have to be set up:

1. Setting up service account:
```
gcloud iam service-accounts create bucket-access --project <project-name>
```
2. Creating IAM policy binding:
```
gcloud projects add-iam-policy-binding <project-name> --member "serviceAccount:bucket-access@<project-name>.iam.gserviceaccount.com" --role "roles/storage.objectAdmin"
```

More information can be found here: https://cloud.google.com/storage/docs/creating-buckets#storage-create-bucket-cli


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

Enable image streaming so that image can be read from the secondary boot disk prepared above.

```
gcloud container clusters update cluster-<NAME> --zone <REGION> --enable-image-streaming
```

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

The `argo` subdirectory has an example workflow:

- argo_bucket_run.yaml: an example workflow with <N_JOBS> jobs.

Change the bucket name in the workflow file to correspond to the bucket in use.
In other words, set the bucket `value` in the .yaml file(s) according to the name of the storage bucket (`<BUCKET_NAME>`) that was created earlier for storing the processing outputs.

Furthermore, the MiniAOD dataset that is to be processed is determined by its recid (record id). The placeholder `<RECID>` in the .yaml file(s) needs to be updated with the chosen recid value.
The datasets with their recids can be found on `https://opendata.cern.ch/`.
The recid is the number in the end of the url, so the following dataset: `https://opendata.cern.ch/record/30549` has the recid `30549`.

Submit the job with this command after changing the filename to the desired workflow file:
```
argo submit argo_bucket_run.yaml -n argo 
```

### Download the output files
Once the workflow is completed, the output files are transferred to the storage bucket.
The files can be downloaded to a local machine either from within the google cloud console or with the following command:
```
gsutil -m cp -r gs://<BUCKET_NAME>/ .
```
The target directory can be set by replacing the dot with the desired local path.
The bucket can be emptied with:
```
gsutil -m rm gs://<BUCKET_NAME>/**
```
Alternatively, the bucket can be completely deleted with:
```
gcloud storage rm --recursive gs://<BUCKET_NAME>
```

### Destroy the resources

Destroy resources with

```
terraform destroy
```