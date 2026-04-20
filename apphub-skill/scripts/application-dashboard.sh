#!/bin/bash

# application-dashboard.sh - Generates a markdown table of App Hub applications in the project

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

echo "Fetching App Hub applications for project: $PROJECT..." >&2

# Get all applications in both global and regional
APPS_GLOBAL=$(gcloud apphub applications list --location=global --project="$PROJECT" --format=json --quiet 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$APPS_GLOBAL" ]; then
  APPS_GLOBAL="[]"
fi

APPS_REGIONAL=$(gcloud apphub applications list --location="$LOCATION" --project="$PROJECT" --format=json --quiet 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$APPS_REGIONAL" ]; then
  APPS_REGIONAL="[]"
fi

# Combine and format
echo "$APPS_GLOBAL $APPS_REGIONAL" | jq -s 'add | unique_by(.name) | map({
  name: (.name | split("/") | last),
  displayName: .displayName,
  location: (.name | split("/") | .[3]),
  environment: (.attributes.environment.type // "-"),
  criticality: (.attributes.criticality.type // "-"),
  scope: .scope.type
})' > /tmp/apps_combined.json

# Check if we have applications
COUNT=$(jq '. | length' /tmp/apps_combined.json)

if [ "$COUNT" -eq 0 ]; then
  echo "No App Hub applications found in global or $LOCATION."
  exit 0
fi

# Output Markdown Table
echo ""
echo "## App Hub Applications Dashboard"
echo ""
echo "| Name | Display Name | Location | Scope | Environment | Criticality |"
echo "|------|--------------|----------|-------|-------------|-------------|"
jq -r '.[] | "| \(.name) | \(.displayName // "-") | \(.location) | \(.scope) | \(.environment) | \(.criticality) |"' /tmp/apps_combined.json
echo ""
