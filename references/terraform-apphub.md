# Google Cloud App Hub - Terraform Reference

App Hub can be managed via Terraform using the `google` provider.

## Common Resources

### `google_apphub_application`
Creates a logical application. App Hub applications can be **regional** (supporting resources from one region) or **global** (supporting resources from multiple regions, including the GCP global region).

> [!IMPORTANT]
> **Global Application Constraint**: Global resources (e.g., Global Forwarding Rules) must be registered with a global application (`location = "global"`). Refer to the `google_apphub_service` and `google_apphub_workload` sections for details.

```hcl
resource "google_apphub_application" "example" {
  location       = "us-central1" # Use "global" for global applications
  application_id = "my-app-id"
  display_name   = "My Application"
  description    = "A sample application for testing"

  scope {
    type = "REGIONAL" # Or "GLOBAL"
  }

  attributes {
    environment {
      type = "STAGING" # PRODUCTION, STAGING, TEST, DEVELOPMENT
    }
    criticality {
      type = "HIGH" # MISSION_CRITICAL, HIGH, MEDIUM, LOW
    }
    developer_owners {
      display_name = "Dev Team"
      email        = "dev-team@example.com"
    }
  }
}
```

### `google_apphub_service`
Registers a network service to an application.

```hcl
resource "google_apphub_service" "example" {
  location       = "us-central1"
  service_id     = "my-service"
  
  # Constraint: If the underlying resource is global, the application must be global.
  # location must match the application's location.
  
  discovered_service = "projects/.../locations/us-central1/discoveredServices/..."
  display_name       = "My Service"
}
```

### `google_apphub_workload`
Registers a computing workload to an application.

```hcl
resource "google_apphub_workload" "example" {
  location       = "us-central1"
  application_id = google_apphub_application.example.application_id
  workload_id    = "my-workload"
  
  discovered_workload = "projects/.../locations/us-central1/discoveredWorkloads/..."
  display_name        = "My Workload"
}
```

### `google_apphub_service_project_attachment`
Attaches a service project to the host project.

```hcl
resource "google_apphub_service_project_attachment" "example" {
  service_project_attachment_id = "my-attached-project"
  service_project               = "projects/my-service-project"
}

```
```
