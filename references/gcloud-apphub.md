# Google Cloud App Hub - gcloud Reference

App Hub provides an application-centric view of Google Cloud infrastructure. It allows organizing resources into logical applications.

## Key Concepts
*   **Applications:** The primary container for organizing services and workloads.
*   **Services:** Logical representations of network-based capabilities (e.g., forwarding rules).
*   **Workloads:** Logical representations of computing binary executions (e.g., instance groups, GKE deployments).
*   **Discovered Services/Workloads:** Unregistered infrastructure assets automatically detected by App Hub that can be onboarded.
*   **Service Projects:** Projects attached to a host project to share their resources with App Hub.

## Common `gcloud apphub` Commands

Use `gcloud apphub` to manage these resources.

### Applications
App Hub applications can be either **regional** (supporting resources from one region) or **global** (supporting resources from multiple regions).

*   **Create Global Application:** `gcloud apphub applications create <APP_ID> --location=global --scope=GLOBAL --display-name="<NAME>"`
*   **Create Regional Application:** `gcloud apphub applications create <APP_ID> --location=<REGION> --scope=REGIONAL --display-name="<NAME>"`
*   **Create with Attributes:**
    ```bash
    gcloud apphub applications create <APP_ID> \
        --location=global \
        --display-name="My App" \
        --environment-type=PRODUCTION \
        --criticality-type=HIGH \
        --business-owners=display-name="Business Team",email="biz@example.com" \
        --developer-owners=display-name="Dev Team",email="dev@example.com"
    ```
*   `gcloud apphub applications list --location=<LOCATION>`
*   `gcloud apphub applications describe <APP_ID> --location=<LOCATION>`
*   `gcloud apphub applications delete <APP_ID> --location=<LOCATION>`

### Services
*   `gcloud apphub applications services create <SERVICE_ID> --application=<APP_ID> --location=<LOCATION> --discovered-service=<DISCOVERED_SERVICE_ID>`
*   **Example:** `gcloud apphub applications services create my-service --application=my-app --location=us-central1 --discovered-service=apphub-00000000-0000-0000-0f5a-15d1c21f4100 --project=apphub-srinandans-test`
*   `gcloud apphub applications services list --application=<APP_ID> --location=<LOCATION>`

### Workloads
*   `gcloud apphub applications workloads create <WORKLOAD_ID> --application=<APP_ID> --location=<LOCATION> --discovered-workload=<DISCOVERED_WORKLOAD_ID>`
*   `gcloud apphub applications workloads list --application=<APP_ID> --location=<LOCATION>`

### Discovered Assets
*   `gcloud apphub discovered-services list --location=<LOCATION>`
*   `gcloud apphub discovered-workloads list --location=<LOCATION>`

#### Lookup Assets
You can look up a discovered service or workload by providing its underlying Google Cloud resource URI.

*   **Service Lookup Example:**
    ```bash
    gcloud apphub discovered-services lookup \
        --location=us-central1 \
        --uri="//run.googleapis.com/projects/my-project/locations/us-central1/services/my-service"
    ```

*   **Workload Lookup Example:**
    ```bash
    gcloud apphub discovered-workloads lookup \
        --location=us-central1 \
        --uri="//spanner.googleapis.com/projects/432423772502/instances/instavibe-graph-instance"
    ```

#### Advanced Filtering
You can search for discovered services by their underlying service reference (CAIS URI format).

Example: Search for services with "emailservice" in their name:
```bash
gcloud apphub discovered-services list \
    --location=us-central1 \
    --project=my-project \
    --filter="SERVICE_REFERENCE:*emailservice"
```

Example: Search for workloads by functional type (`AGENT` or `MCP_SERVER`):
```bash
gcloud apphub discovered-workloads list \
    --location=us-central1 \
    --project=my-project \
    --filter="workloadProperties.functionalType:AGENT"
```

The `serviceReference` follows the CAIS (Cloud Asset Inventory Service) convention.
Format: `//<SERVICE_NAME>.googleapis.com/projects/<PROJECT_ID>/locations/<LOCATION>/services/<SERVICE_ID>`
Example: `//run.googleapis.com/projects/432423772502/locations/us-central1/services/sri-test-adc-cloudrun`

### Service Projects
*   `gcloud apphub service-projects create <PROJECT_ID>` (Attaches a service project to the host project)
*   `gcloud apphub service-projects list`
