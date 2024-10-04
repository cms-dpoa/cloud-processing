#!/bin/bash

# Move this file to the root directory and give the correct paths for
# the terraform directory (containing terraform.tfvars) and argo workflows to run

# The following variables can be customised
# some of them, like the project id, are required

# The following contains paths for the terraform config files,
# workflow file and namespace to use
TERRAFORM_DIR="standard-gke-cluster-gcs"
START_WORKFLOW="argo/argo_bucket_start.yaml"
WORKFLOW_FILE="argo/argo_bucket_run.yaml"
NAMESPACE="argo"

# Cluster variables
# Cluster name should be unique for better cost monitoring
# In this case it is kept unique via including the timestamp
PROJECT_ID=""
REGION="europe-north1-b"
TIMESTAMP=$(date +'%y%m%d-%H-%M')
CLUSTER_NAME="cluster-$TIMESTAMP"
NUM_NODES=3
MACHINE_TYPE="e2-custom-32-65536"
NODE_DISK_TYPE="pd-standard"
NODE_DISK_SIZE=500

# Workflow variables
RECID=
NUM_EVENTS=1000000
NUM_JOBS=96

# Set a value for nfs disk type if using the nfs cluster, e.g. "pd-standard" or "pd-ssd"
# If using the gcs (google cloud storage) bucket workflow, enter the name of your bucket
NFS_DISK_TYPE=""
BUCKET_NAME=""
SERVICE_ACC_FILE=""

# From this point, the functions for the script are defined
# first creating a terraform planfile to deploy resources according to specifications

# Function to deploy the cluster and other cloud resources using Terraform
deploy_resources() {
    echo "Deploying resources with Terraform..."
    terraform init
    terraform plan \
    -var "project_id=$PROJECT_ID" \
    -var "region=$REGION" \
    -var "name=$TIMESTAMP" \
    -var "gke_num_nodes=$NUM_NODES" \
    -var "gke_machine_type=$MACHINE_TYPE" \
    -var "gke_node_disk_type=$NODE_DISK_TYPE" \
    -var "gke_node_disk_size=$NODE_DISK_SIZE" \
    -var "persistent_disk_type=${NFS_DISK_TYPE:-}" \
    -var "service_acc=${SERVICE_ACC_FILE:-}" \
    -out=tfplan || { echo "Terraform plan failed"; return 1; }

    terraform apply -auto-approve tfplan || { echo "Terraform apply failed"; return 1; }
}

prepare_cluster() {
    echo "Setting up cluster..."
    gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION

    # Quickstart version for argo, not meant for use in production
    #kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-workflows/master/manifests/quick-start-postgres.yaml

    # Install argo, user proper install file instead of previously used quickstart version
    # Requires service account, role and role binding for permissions
    kubectl apply -n $NAMESPACE -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.10/install.yaml
    kubectl apply -f "argo/service_account.yaml"
    kubectl apply -f "argo/argo_role.yaml"
    kubectl apply -f "argo/argo_role_binding.yaml"
    echo "Cluster preparation complete."
}

# Function to run the start workflow to initialise the nodes before running the main job
run_start_workflow() {
    echo "Submitting Argo start workflow..."
    argo submit -n $NAMESPACE $START_WORKFLOW \
    -p nEvents=1000 \
    -p recid=$RECID \
    -p nJobs=$NUM_NODES \
    -p bucket=$BUCKET_NAME \
    -p claimName="nfs-$TIMESTAMP"
}

# Function to run Argo workflow
run_argo_workflow() {
    # Deleting previous workflow from the list of workflows
    argo delete -n $NAMESPACE @latest
    echo "Submitting Argo workflow..."
    argo submit -n $NAMESPACE $WORKFLOW_FILE \
    -p nEvents=$NUM_EVENTS \
    -p recid=$RECID \
    -p nJobs=$NUM_JOBS \
    -p bucket=$BUCKET_NAME \
    -p claimName="nfs-$TIMESTAMP"
}

# Function to monitor Argo workflow
monitor_workflow() {
    WORKFLOW_NAME=$(argo get @latest -n $NAMESPACE | grep -m 1 "Name:" | awk '{print $2}')
    echo "Monitoring Argo workflow..."

    # Counter to check the status after a certain time interval (default: 10 seconds)
    # Prints current status when counter exceeds the print interval (default: 300 seconds)
    COUNTER=0
    CHECK_INTERVAL=10
    PRINT_INTERVAL=300

    while true; do
        STATUS=$(argo get $WORKFLOW_NAME -n $NAMESPACE | grep "Status:" | awk '{print $2}')
        
        if [[ $STATUS == "Succeeded" ]]; then
            echo -e "\nWorkflow completed successfully."
            WF_TIME=$(argo get @latest -n $NAMESPACE | grep -m 1 "Duration:" | awk '{$1=""; print $0}')
            echo "Workflow took $WF_TIME to complete."
            echo -e "\e[32m`date +%r`\e[39m\n"
            break
        elif [[ $STATUS == "Failed" || $STATUS == "Error" ]]; then
            echo "Workflow failed with status: $STATUS"
            echo -e "\e[32m`date +%r`\e[39m\n"
            break
        elif (( COUNTER >= PRINT_INTERVAL )); then
            # Print status and current time
            echo -e "\nCurrent status: $STATUS"
            echo -e "\e[32m`date +%r`\e[39m\n"
            # Monitor resource usage
            kubectl top nodes
            kubectl get pods -o wide -n $NAMESPACE | grep runpfnano | awk '$3 == "Running" {print $7}' | sort | uniq -c | awk '{print  $1" job(s) running on: "$2}'
            # Reset counter
            COUNTER=0
        fi
        # Wait for a bit before rechecking the status
        sleep $CHECK_INTERVAL
        COUNTER=$((COUNTER+CHECK_INTERVAL))
    done
}

# Recording potentially useful workflow details
log_workflow_details() {
    OUTPUT_DIR="outputs"
    mkdir -p "${OUTPUT_DIR}"

    # Get the generated string for the pfnano process to use as filename
    # to store the config info/logs
    FILENAME=$(echo $WORKFLOW_NAME | awk -F '-' '{print $NF}')
    LOG_FILE="${OUTPUT_DIR}/${FILENAME}_logs.txt"
    CONFIG_FILE="${OUTPUT_DIR}/${FILENAME}_cluster_config.txt"

    echo "Logging workflow details..."
    
    # Get the complete logs for all pods (might be too much when processing a whole dataset)
    ARGO_LOGS=$(argo logs -n $NAMESPACE $WORKFLOW_NAME)
    ARGO_WF=$(argo get -n $NAMESPACE $WORKFLOW_NAME)

    # Extract job duration and timestamps for archiving to bucket from pod logs
    JOB_TIMES=$(echo "$ARGO_LOGS" | grep -A 1 "Job duration:")
    ARCHIVING_TIMES=$(echo "$ARGO_LOGS" | grep -A 1 "level=info msg=\"Taring")

    # Save the job duration and archiving information separately
    echo -e "Time taken for argo start workflow & pod initialisation: $START_WF_TIME\n" > $LOG_FILE
    echo -e "Job duration per job:\n" >> $LOG_FILE
    echo "$JOB_TIMES" >> $LOG_FILE

    echo -e "\nArchiving step after job completion:\n" >> $LOG_FILE
    echo "$ARCHIVING_TIMES" >> $LOG_FILE

    # Append the full logs
    echo -e "\nFull logs:\n" >> $LOG_FILE
    echo "$ARGO_LOGS" >> $LOG_FILE

    # Store workflow and cluster information
    echo -e "Cluster configuration:\n" > $CONFIG_FILE
    echo -e "Workflow: $WORKFLOW_FILE" >> $CONFIG_FILE
    echo "project_id=$PROJECT_ID" >> $CONFIG_FILE
    echo "region=$REGION" >> $CONFIG_FILE
    echo "name=$TIMESTAMP" >> $CONFIG_FILE
    echo "gke_num_nodes=$NUM_NODES" >> $CONFIG_FILE
    echo "gke_machine_type=$MACHINE_TYPE" >> $CONFIG_FILE
    echo "gke_node_disk_type=$NODE_DISK_TYPE" >> $CONFIG_FILE
    echo "gke_node_disk_size=$NODE_DISK_SIZE" >> $CONFIG_FILE
    echo "persistent_disk_type=${NFS_DISK_TYPE:-}" >> $CONFIG_FILE
    echo "service_acc=${SERVICE_ACC_FILE:-}" >> $CONFIG_FILE

    # Get workflow info
    echo -e "\n" >> $CONFIG_FILE
    echo "$ARGO_WF" >> $CONFIG_FILE
}

# Destroy resources using terraform
destroy_resources() {
    echo "Destroying resources with Terraform..."
    argo delete --all -n $NAMESPACE
    kubectl delete all --all
    terraform destroy -auto-approve \
    -var "project_id=$PROJECT_ID" \
    -var "region=$REGION" \
    -var "name=$TIMESTAMP" \
    -var "gke_num_nodes=$NUM_NODES" \
    -var "gke_machine_type=$MACHINE_TYPE" \
    -var "gke_node_disk_type=$NODE_DISK_TYPE" \
    -var "gke_node_disk_size=$NODE_DISK_SIZE" \
    -var "persistent_disk_type=${NFS_DISK_TYPE:-}" \
    -var "service_acc=${SERVICE_ACC_FILE:-}" \
    || { echo "Terraform destroy failed"; return 1; }
}

# Main script execution

# The start workflow is optional, but it's advisable to run it to initialise pods
# resulting in more consistent comparisons for the actual run afterwards

# Move to the directory with the terraform configuration files
cd "${TERRAFORM_DIR}"

deploy_resources
prepare_cluster
run_start_workflow
monitor_workflow
# Save the duration of the start workflow
START_WF_TIME=$WF_TIME
run_argo_workflow
monitor_workflow
log_workflow_details
destroy_resources
cd ".."

echo "Automation script finished."