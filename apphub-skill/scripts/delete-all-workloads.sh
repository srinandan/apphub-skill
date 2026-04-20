#!/bin/bash

# Check if required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <PROJECT_ID> <APPLICATION_ID>"
    exit 1
fi

PROJECT_ID=$1
APPLICATION_ID=$2
LOCATION="global" # Default to global as per skill context

echo "Listing all workloads for application: ${APPLICATION_ID} in project: ${PROJECT_ID}..."

# Get the list of workload IDs
# We use name.segment(-1) to get only the workload ID from the full resource name
WORKLOAD_IDS=$(gcloud apphub applications workloads list \
    --application="${APPLICATION_ID}" \
    --location="${LOCATION}" \
    --project="${PROJECT_ID}" \
    --format="value(name.segment(-1))")

if [ -z "${WORKLOAD_IDS}" ]; then
    echo "No workloads found for application: ${APPLICATION_ID}."
    exit 0
fi

echo "Deleting workloads..."
for WORKLOAD_ID in ${WORKLOAD_IDS}; do
    echo "Deleting workload: ${WORKLOAD_ID}..."
    gcloud apphub applications workloads delete "${WORKLOAD_ID}" \
        --application="${APPLICATION_ID}" \
        --location="${LOCATION}" \
        --project="${PROJECT_ID}" \
        --quiet
done

echo "All workloads deleted for application: ${APPLICATION_ID}."
