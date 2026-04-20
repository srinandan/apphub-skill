#!/bin/bash

# service-dashboard.sh - Generates a markdown table of App Hub services in the project

PROJECT=$(gcloud config get-value project 2>/dev/null)
LOCATION=$(gcloud config get-value compute/region 2>/dev/null)

while [[ $# -gt 0 ]]; do
  case $1 in
    --project=*)
      PROJECT="${1#*=}"
      shift
      ;;
    --location=*)
      LOCATION="${1#*=}"
      shift
      ;;
    *)
      shift
      ;;
  esac
done

if [ -z "$PROJECT" ]; then
  echo "Error: Project not set. Use --project=PROJECT_ID"
  exit 1
fi

if [ -z "$LOCATION" ]; then
  LOCATION="us-central1"
fi

echo "Fetching App Hub services for project: $PROJECT (locations: global, $LOCATION)..." >&2

# Get all applications in both global and regional
APPS_GLOBAL=$(gcloud apphub applications list --location=global --project="$PROJECT" --format="value(name)" --quiet 2>/dev/null)
APPS_REGIONAL=$(gcloud apphub applications list --location="$LOCATION" --project="$PROJECT" --format="value(name)" --quiet 2>/dev/null)

ALL_APPS=$(echo "$APPS_GLOBAL" "$APPS_REGIONAL" | tr ' ' '\n' | sort -u)

ALL_SERVICES="[]"

for APP_FULL_NAME in $ALL_APPS; do
    APP_ID=$(echo "$APP_FULL_NAME" | awk -F'/' '{print $NF}')
    LOC=$(echo "$APP_FULL_NAME" | awk -F'/' '{print $4}')
    
    # echo "Checking services for app $APP_ID in $LOC..." >&2
    SERVICES=$(gcloud apphub applications services list --application="$APP_ID" --location="$LOC" --project="$PROJECT" --format=json --quiet 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$SERVICES" ] && [ "$SERVICES" != "[]" ]; then
        # Add app name and location context to each service entry
        SERVICES_WITH_CONTEXT=$(echo "$SERVICES" | jq --arg app "$APP_ID" --arg loc "$LOC" 'map(. + {application: $app, appLocation: $loc})')
        ALL_SERVICES=$(echo "$ALL_SERVICES $SERVICES_WITH_CONTEXT" | jq -s 'add')
    fi
done

# Check if we have services
COUNT=$(echo "$ALL_SERVICES" | jq '. | length')

if [ "$COUNT" -eq 0 ]; then
  echo "No App Hub services found in global or $LOCATION."
  exit 0
fi

# Format for the table
echo "$ALL_SERVICES" | jq 'map({
  name: (.name | split("/") | last),
  application: .application,
  location: .appLocation,
  environment: (.attributes.environment.type // "-"),
  criticality: (.attributes.criticality.type // "-"),
  discoveredService: (.discoveredService | split("/") | last)
})' > /tmp/services_combined.json

# Output Markdown Table
echo ""
echo "## App Hub Services Dashboard"
echo ""
echo "| Service Name | Application | Location | Environment | Criticality | Discovered Resource |"
echo "|--------------|-------------|----------|-------------|-------------|---------------------|"
jq -r '.[] | "| \(.name) | \(.application) | \(.location) | \(.environment) | \(.criticality) | \(.discoveredService) |"' /tmp/services_combined.json
echo ""
