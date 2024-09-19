#!/bin/bash
time gsutil -m cp -r gs://bucket-europe-north1-finland/200.txt .
time gsutil -m cp -r gs://bucket-europe-north1-finland/300.txt .
time gsutil -m cp -r gs://bucket-europe-north1-finland/512.txt .
time gsutil -m cp -r gs://bucket-europe-north1-finland/700.txt .
time gsutil -m cp -r gs://bucket-europe-north1-finland/1GB.zip .
time gsutil -m cp -r gs://bucket-europe-north1-finland/1_5GB .
time gsutil -m cp -r gs://bucket-europe-north1-finland/2GB .
time gsutil -m cp -r gs://bucket-europe-north1-finland/2_5GB .
time gsutil -m cp -r gs://bucket-europe-north1-finland/5GB .
time gsutil -m cp -r gs://bucket-europe-north1-finland/7_5GB .
time gsutil -m cp -r gs://bucket-europe-north1-finland/10GB .


time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/512MB.zip.crdownload .
time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/1GB.zip .
time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/1_5GB/ .
time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/2GB/ .
time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/2_5GB/ .
time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/5GB/ .
time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/7_5GB/ .
time gcloud storage cp -r gs://nano-data-output-europe-north-1-finland/10GB/ .