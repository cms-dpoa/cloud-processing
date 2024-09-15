#!/bin/bash

# Move this file to the folder containing terraform.tfvars!
# Also ensure the argo workflow is in the correct path as below

# The following variables can be customised
# some of them, like the project id, are required

# The following contains paths for the terraform config files,
# workflow file and namespace to use
TERRAFORM_DIR="standard-gke-cluster-gcs"
WORKFLOW_FILE="argo/argo_bucket_run.yaml"
NAMESPACE="argo"

# Cluster variables
# Cluster name should be unique for better cost monitoring
# In this case it is kept unique via including the timestamp
PROJECT_ID=""
REGION="europe-north1-b"
TIMESTAMP=$(date +'%y%m%d-%H-%M')
CLUSTER_NAME="cluster-$TIMESTAMP"
NUM_NODES="3"
MACHINE_TYPE="e2-standard-4"
NODE_DISK_TYPE="pd-ssd"

# Dataset variables
RECID="30544"
NUM_EVENTS="30000"
NUM_JOBS="12"

# Set a value for nfs disk type if using the nfs cluster, e.g. "pd-standard" or "pd-ssd"
# If using the gcs (google cloud storage) bucket workflow, enter the name of your bucket
NFS_DISK_TYPE=""
BUCKET_NAME=""
SERVICE_ACC_FILE=""

# From this point, the actual script starts, first filling in variables from above into terraform.tfvars
# and the argo workflow, to customise the number of jobs and how many events should be processed

# Change the directory to the one containing the terraform configuration files
cd "${TERRAFORM_DIR}"

# Insert the variable values into the placeholders in terraform.tfvars
sed -i.bak -e "s/<PROJECT_ID>/$PROJECT_ID/" -e "s/<REGION>/$REGION/" -e "s/<NAME>/$TIMESTAMP/" \
    -e "s/<NUM_NODES>/$NUM_NODES/" -e "s/<MACHINE_TYPE>/$MACHINE_TYPE/" \
    -e "s/<NODE_DISK_TYPE>/$NODE_DISK_TYPE/" -e "s/<NFS_DISK_TYPE>/$NFS_DISK_TYPE/" \
    -e "s/<SERVICE_ACCOUNT_FILE>/$SERVICE_ACC_FILE/" "terraform.tfvars"

# Insert the variable values into the argo workflow
sed -i.bak -e "s/<NAME>/$TIMESTAMP/" -e "s/<RECID>/$RECID/" \
    -e "s/<N_EVENTS>/$NUM_EVENTS/" -e "s/<N_JOBS>/$NUM_JOBS/" \
    -e "s/<BUCKET_NAME>/$BUCKET_NAME/" "${WORKFLOW_FILE}"

# Function to deploy the cluster and other cloud resources using Terraform
deploy_resources() {
    echo "Deploying resources with Terraform..."
    terraform init
    terraform apply -auto-approve
}

prepare_cluster() {
    echo "Setting up cluster..."
    echo "Current timestamp: $TIMESTAMP"
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

# Function to run Argo workflow
run_argo_workflow() {
    echo "Submitting Argo workflow..."
    argo submit -n $NAMESPACE $WORKFLOW_FILE
}

# Function to monitor Argo workflow
monitor_workflow() {
    WORKFLOW_NAME=$(argo list -n $NAMESPACE | tail -n 1 | awk '{print $1}')
    echo "Monitoring Argo workflow..."

    # Counter to check the status after a certain time interval (default: 10 seconds)
    # Prints current status when counter exceeds the print interval (default: 300 seconds)
    COUNTER=0
    CHECK_INTERVAL=10  
    PRINT_INTERVAL=300

    while true; do
        STATUS=$(argo get $WORKFLOW_NAME -n argo | grep "Status:" | awk '{print $2}')
        
        if [[ $STATUS == "Succeeded" ]]; then
            echo "Workflow completed successfully."
            echo -e "\e[32m`date +%r`\e[39m\n"
            break
        elif [[ $STATUS == "Failed" || $STATUS == "Error" ]]; then
            echo "Workflow failed with status: $STATUS"
            echo -e "\e[32m`date +%r`\e[39m\n"
            break
        elif (( COUNTER >= PRINT_INTERVAL )); then

            # Print status and current time
            echo "Current status: $STATUS"
            echo -e "\e[32m`date +%r`\e[39m\n"

            # Reset counter
            COUNTER=0
        fi
    
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

    # Extract job duration and timestamps for archiving to bucket from pod logs
    JOB_TIMES=$(echo "$ARGO_LOGS" | grep -A 1 "of processing time.")
    ARCHIVING_TIMES=$(echo "$ARGO_LOGS" | grep -A 1 "level=info msg=\"Taring")

    # Save the job duration and archiving information separately
    echo -e "Job duration per job:\n" > $LOG_FILE
    echo "$JOB_TIMES" >> $LOG_FILE

    echo -e "\nArchiving step after job completion:\n" >> $LOG_FILE
    echo "$ARCHIVING_TIMES" >> $LOG_FILE

    # Append the full logs
    echo -e "\nFull logs:\n" >> $LOG_FILE
    echo "$ARGO_LOGS" >> $LOG_FILE

    # Store workflow and cluster information
    echo -e "Cluster configuration:\n" > $CONFIG_FILE
    echo -e "Workflow: $WORKFLOW_FILE" >> $CONFIG_FILE
    cat "terraform.tfvars" >> $CONFIG_FILE

    # Get workflow info
    echo -e "\n" >> $CONFIG_FILE
    argo get -n $NAMESPACE $WORKFLOW_NAME >> $CONFIG_FILE
}

# Destroy resources using terraform
destroy_resources() {
    echo "Destroying resources with Terraform..."
    argo delete -n $NAMESPACE @latest
    kubectl delete all --all
    terraform destroy -auto-approve
}

# Revert terraform.tfvars and argo workflow to the original state
# to restore the placeholders
reset_files() {
    # Restore original terraform file and argo workflow file from backups
    cp "terraform.tfvars.bak" "terraform.tfvars"
    cp "${WORKFLOW_FILE}.bak" "${WORKFLOW_FILE}"
    cd ".."
}

# Main script execution
deploy_resources
prepare_cluster
run_argo_workflow
monitor_workflow
log_workflow_details
destroy_resources
reset_files
echo "Automation script completed."