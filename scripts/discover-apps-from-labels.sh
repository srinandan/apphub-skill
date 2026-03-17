#!/bin/bash

# ==============================================================================
# discover-apps-from-labels.sh
# ------------------------------------------------------------------------------
# Discovers resources using Cloud Asset Inventory (CAI) based on a label key,
# groups them by the label's value, validates them via App Hub lookup,
# and manages corresponding App Hub Applications.
# ==============================================================================

set -e

# Default values
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")
LABEL_KEY="appid"
LOCATION="global"
DRY_RUN=true

usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  --project PROJECT_ID    The Google Cloud project ID (default: current gcloud project)"
  echo "  --label-key KEY        The label key to search for (default: $LABEL_KEY)"
  echo "  --location LOCATION     The App Hub application location (default: $LOCATION)"
  echo "  --apply                Commit changes (default: dry-run mode)"
  echo "  --help                 Show this help message"
  exit 1
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --project)
      if [[ "$1" == *=* ]]; then PROJECT_ID="${1#*=}"; shift; else PROJECT_ID="$2"; shift; shift; fi ;;
    --project=*)
      PROJECT_ID="${1#*=}"; shift ;;
    --label-key)
      if [[ "$1" == *=* ]]; then LABEL_KEY="${1#*=}"; shift; else LABEL_KEY="$2"; shift; shift; fi ;;
    --label-key=*)
      LABEL_KEY="${1#*=}"; shift ;;
    --location)
      if [[ "$1" == *=* ]]; then LOCATION="${1#*=}"; shift; else LOCATION="$2"; shift; shift; fi ;;
    --location=*)
      LOCATION="${1#*=}"; shift ;;
    --apply)
      DRY_RUN=false; shift ;;
    --help) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  echo "Error: PROJECT_ID not specified and no default project found in gcloud config."
  exit 1
fi

echo "--- App Hub Discovery Journey ---"
echo "Project:   $PROJECT_ID"
echo "Label Key: $LABEL_KEY"
echo "Location:  $LOCATION"
echo "Mode:      $( [ "$DRY_RUN" = true ] && echo 'DRY-RUN' || echo 'APPLY' )"
echo "---------------------------------"

# Helper function to validate resource via lookup
validate_resource() {
  local uri="$1"
  local project="$2"
  
  # Determine lookup location from URI
  local lookup_location="global"
  if [[ "$uri" =~ /locations/([^/]+)/ ]]; then
    lookup_location="${BASH_REMATCH[1]}"
  elif [[ "$uri" =~ /global/ ]]; then
    lookup_location="global"
  fi

  # Try service lookup
  if gcloud apphub discovered-services lookup --uri="$uri" --project="$project" --location="$lookup_location" &>/dev/null; then
    return 0
  fi
  
  # Try workload lookup
  if gcloud apphub discovered-workloads lookup --uri="$uri" --project="$project" --location="$lookup_location" &>/dev/null; then
    return 0
  fi
  
  return 1
}

# 1. Search for resources
echo "[1/3] Searching for resources with label '$LABEL_KEY'..."
RESOURCES_JSON=$(gcloud asset search-all-resources \
    --scope="projects/$PROJECT_ID" \
    --query="labels.$LABEL_KEY:*" \
    --format="json(name, assetType, labels.$LABEL_KEY)")

if [[ -z "$RESOURCES_JSON" || "$RESOURCES_JSON" == "[]" ]]; then
  echo "No resources found with label key '$LABEL_KEY'."
  exit 0
fi

# 2. Group and process
echo "[2/3] Processing resource groups..."

# Extract unique app_ids
APP_IDS=$(echo "$RESOURCES_JSON" | jq -r '.[].labels.'$LABEL_KEY'' | sort -u)

for APP_ID in $APP_IDS; do
  echo ""
  echo "Group: $APP_ID"
  echo "----------------------------------------------------"
  
  # Filter resources for this app_id
  RAW_RESOURCES=$(echo "$RESOURCES_JSON" | jq -c "[.[] | select(.labels.$LABEL_KEY == \"$APP_ID\")]")
  RAW_COUNT=$(echo "$RAW_RESOURCES" | jq '. | length')
  
  echo "Found $RAW_COUNT candidates in CAIS. Validating with App Hub lookup..."
  
  VALID_RESOURCES="[]"
  
  # Iterate and validate each resource
  while read -r resource; do
    NAME=$(echo "$resource" | jq -r '.name')
    TYPE=$(echo "$resource" | jq -r '.assetType')
    
    printf " - Validating %s... " "$NAME"
    if validate_resource "$NAME" "$PROJECT_ID"; then
      echo "[OK]"
      VALID_RESOURCES=$(echo "$VALID_RESOURCES" | jq -c ". + [$resource]")
    else
      echo "[IGNORED - Not found in App Hub]"
    fi
  done < <(echo "$RAW_RESOURCES" | jq -c '.[]')

  VALID_COUNT=$(echo "$VALID_RESOURCES" | jq '. | length')
  
  if [[ "$VALID_COUNT" -eq 0 ]]; then
    echo ">> No eligible App Hub resources found for group '$APP_ID'. Skipping."
    continue
  fi

  echo "Eligible resources: $VALID_COUNT"

  # Constraint check: Global resources in regional apps
  if [[ "$LOCATION" != "global" ]]; then
    GLOBAL_RESOURCES=$(echo "$VALID_RESOURCES" | jq -r '.[].name | select(contains("/locations/global/") or contains("/global/"))')
    if [[ -n "$GLOBAL_RESOURCES" ]]; then
      echo ">> WARNING: Found global resources in this group, but target location is '$LOCATION'."
      echo ">> App Hub requires global resources to be registered in a 'global' application."
      echo ">> Skipping application check/creation for this group."
      continue
    fi
  fi

  # Check if App Hub application exists
  echo "Checking App Hub status for '$APP_ID'..."
  set +e
  EXISTS=$(gcloud apphub applications describe "$APP_ID" --location="$LOCATION" --project="$PROJECT_ID" 2>/dev/null)
  set -e
  
  if [[ -z "$EXISTS" ]]; then
    echo ">> Application '$APP_ID' does NOT exist."
    if [ "$DRY_RUN" = false ]; then
      echo ">> Creating Application '$APP_ID'..."
      gcloud apphub applications create "$APP_ID" --location="$LOCATION" --scope-type="$LOCATION" --display-name="$APP_ID" --project="$PROJECT_ID"
    else
      echo ">> [DRY RUN] Would run: gcloud apphub applications create $APP_ID --location=$LOCATION --scope-type=$LOCATION --project=$PROJECT_ID"
    fi
  else
    echo ">> Application '$APP_ID' already exists."
  fi
done

echo ""
echo "[3/3] Done."
if [ "$DRY_RUN" = true ]; then
  echo "Tip: Run with --apply to create the applications."
fi
