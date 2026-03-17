# Google Cloud App Hub - gcloud Reference

App Hub provides an application-centric view of Google Cloud infrastructure. It allows organizing resources into logical applications.

### Key Concepts
- **Applications**: Logical containers that group services and workloads to represent a business function.
- **Services**: Logical representations of network-based capabilities (e.g., Forwarding Rules) used to access an application.
- **Workloads**: Logical representations of computing binary executions (e.g., Instance Groups, GKE Deployments) that perform specific tasks.
*   **Service Projects:** Projects attached to a host project to share their resources with App Hub.

## Infrastructure Mapping (Service vs Workload)

App Hub categorizes Google Cloud resources into either **Services** or **Workloads**.

### Support as Services
Services represent network-based capabilities used to access an application.

| Product | Resource Types |
|---------|----------------|
| **Networking** | Forwarding Rules, Virtual Services (Istio), API Gateways |
| **Compute** | Backend Services |
| **Databases** | AlloyDB (Cluster/Instance), Bigtable (Instance/Table/View), Firestore, Spanner (Instance/DB), Cloud SQL |
| **Serverless** | Cloud Run (Service), Cloud Functions (v1/v2) |
| **AI/ML** | Vertex AI (Dataset, Endpoint, Model, MetadataStore, Tensorboard) |
| **Messaging** | Pub/Sub (Topic, Subscription) |
| **Storage** | Cloud Storage Buckets |
| **Other** | Cloud Tasks, Dataproc Metastore, Secret Manager, Workflows |

### Support as Workloads
Workloads represent computing binary executions that perform specific tasks.

| Product | Resource Types |
|---------|----------------|
| **Compute** | Compute Engine Instance Groups |
| **Container** | **GKE**: Deployments, StatefulSets, DaemonSets, CronJobs |
| **Serverless** | Cloud Run Jobs |
| **AI/ML** | Vertex AI (BatchPredictionJob, ReasoningEngine, TuningJob) |
| **Tools** | Cloud Build (WorkerPool), Cloud Scheduler Jobs, Infrastructure Manager Deployments |

> [!NOTE]
> For the most up-to-date and exhaustive list, refer to the [official App Hub documentation](https://cloud.google.com/app-hub/docs/supported-resources).

## Best Practices for Application Management

Follow these principles to create operable, governable, and efficient App Hub applications.

### 1. Define Clear Boundaries
Categorize your Google Cloud projects logically. The App Hub boundary should group resources that share a joint operational lifecycle or business value.
- **Tip**: Align your App Hub boundary with your **Google Cloud Observability scopes** (Log/Metric/Trace) to ensure a consistent view across management and monitoring.

### 2. Reflect Business Capabilities
Define your applications around **business functions** or end-to-end workflows (e.g., "Payment Processing") rather than technical architecture layers (e.g., "Backend Services"). Each App Hub application should represent a distinct value stream.

### 3. Establish Clear Ownership
Always assign mutable **attributes** to your applications, services, and workloads:
- **Environment**: Track lifecycle stages (Production, Staging, etc.).
- **Criticality**: Inform incident response priorities (Mission Critical, High, etc.).
- **Owners**: Assign accountability for business, development, and operations teams.

---

## Common `gcloud apphub` Commands

Use `gcloud apphub` to manage these resources.

### Applications
App Hub applications can be either **regional** (supporting resources from one region) or **global** (supporting resources from multiple regions, including the GCP global region).

> [!IMPORTANT]
> **Global Application Required for Global Resources**: Any Google Cloud resource that is globally scoped (e.g., Global Forwarding Rules, Global Cloud Run services) can **ONLY** be registered within an App Hub application that is also globally scoped (`--location=global`).

*   **Create Global Application:** `gcloud apphub applications create <APP_ID> --location=global --scope-type=GLOBAL --display-name="<NAME>"`
*   **Create Regional Application:** `gcloud apphub applications create <APP_ID> --location=<REGION> --scope-type=REGIONAL --display-name="<NAME>"`
*   **Create with Attributes:**
    ```bash
    gcloud apphub applications create <APP_ID> \
        --location=global \
        --scope-type=GLOBAL \
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
*   **Constraint**: Global resources must be registered with global applications.
*   **Example:** `gcloud apphub applications services create my-service --application=my-app --location=us-central1 --discovered-service=apphub-00000000-0000-0000-0f5a-15d1c21f4100 --project=apphub-srinandans-test`
*   `gcloud apphub applications services list --application=<APP_ID> --location=<LOCATION>`

### Workloads
*   `gcloud apphub applications workloads create <WORKLOAD_ID> --application=<APP_ID> --location=<LOCATION> --discovered-workload=<DISCOVERED_WORKLOAD_ID>`
*   `gcloud apphub applications workloads list --application=<APP_ID> --location=<LOCATION>`

### Service Projects
*   `gcloud apphub service-projects create <PROJECT_ID>` (Attaches a service project to the host project)
*   `gcloud apphub service-projects list`
