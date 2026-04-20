#!/bin/bash

# Check if required arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <PROJECT_ID> <APPLICATION_ID>"
    exit 1
fi

PROJECT_ID=$1
APPLICATION_ID=$2
LOCATION="global" # Default to global as per skill context

echo "Listing all services for application: ${APPLICATION_ID} in project: ${PROJECT_ID}..."

# Get the list of service IDs
# We use name.segment(-1) to get only the service ID from the full resource name
SERVICE_IDS=$(gcloud apphub applications services list \
    --application="${APPLICATION_ID}" \
    --location="${LOCATION}" \
    --project="${PROJECT_ID}" \
    --format="value(name.segment(-1))")

if [ -z "${SERVICE_IDS}" ]; then
    echo "No services found for application: ${APPLICATION_ID}."
    exit 0
fi

echo "Deleting services..."
for SERVICE_ID in ${SERVICE_IDS}; do
    echo "Deleting service: ${SERVICE_ID}..."
    gcloud apphub applications services delete "${SERVICE_ID}" \
        --application="${APPLICATION_ID}" \
        --location="${LOCATION}" \
        --project="${PROJECT_ID}" \
        --quiet
done

echo "All services deleted for application: ${APPLICATION_ID}."
