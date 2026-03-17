#!/bin/bash

# workload-dashboard.sh - Generates a markdown table of App Hub workloads in the project

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

echo "Fetching App Hub workloads for project: $PROJECT (locations: global, $LOCATION)..." >&2

# Get all applications in both global and regional
APPS_GLOBAL=$(gcloud apphub applications list --location=global --project="$PROJECT" --format="value(name)" --quiet 2>/dev/null)
APPS_REGIONAL=$(gcloud apphub applications list --location="$LOCATION" --project="$PROJECT" --format="value(name)" --quiet 2>/dev/null)

ALL_APPS=$(echo "$APPS_GLOBAL" "$APPS_REGIONAL" | tr ' ' '\n' | sort -u)

ALL_WORKLOADS="[]"

for APP_FULL_NAME in $ALL_APPS; do
    APP_ID=$(echo "$APP_FULL_NAME" | awk -F'/' '{print $NF}')
    LOC=$(echo "$APP_FULL_NAME" | awk -F'/' '{print $4}')
    
    # echo "Checking workloads for app $APP_ID in $LOC..." >&2
    WORKLOADS=$(gcloud apphub applications workloads list --application="$APP_ID" --location="$LOC" --project="$PROJECT" --format=json --quiet 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$WORKLOADS" ] && [ "$WORKLOADS" != "[]" ]; then
        # Add app name and location context to each workload entry
        WORKLOADS_WITH_CONTEXT=$(echo "$WORKLOADS" | jq --arg app "$APP_ID" --arg loc "$LOC" 'map(. + {application: $app, appLocation: $loc})')
        ALL_WORKLOADS=$(echo "$ALL_WORKLOADS $WORKLOADS_WITH_CONTEXT" | jq -s 'add')
    fi
done

# Check if we have workloads
COUNT=$(echo "$ALL_WORKLOADS" | jq '. | length')

if [ "$COUNT" -eq 0 ]; then
  echo "No App Hub workloads found in global or $LOCATION."
  exit 0
fi

# Format for the table
echo "$ALL_WORKLOADS" | jq 'map({
  name: (.name | split("/") | last),
  application: .application,
  location: .appLocation,
  environment: (.attributes.environment.type // "-"),
  criticality: (.attributes.criticality.type // "-"),
  discoveredWorkload: (.discoveredWorkload | split("/") | last)
})' > /tmp/workloads_combined.json

# Output Markdown Table
echo ""
echo "## App Hub Workloads Dashboard"
echo ""
echo "| Workload Name | Application | Location | Environment | Criticality | Discovered Resource |"
echo "|---------------|-------------|----------|-------------|-------------|---------------------|"
jq -r '.[] | "| \(.name) | \(.application) | \(.location) | \(.environment) | \(.criticality) | \(.discoveredWorkload) |"' /tmp/workloads_combined.json
echo ""
