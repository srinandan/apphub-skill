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

## Advanced Example: Registering Discovered Assets

When you know the resource URI of the underlying Google Cloud resource (e.g., a GKE service or deployment) but don't know the exact App Hub Discovered Service or Discovered Workload ID, you can use data sources to look them up.

```hcl
locals {
  services = [
    "//container.googleapis.com/projects/my-project/locations/us-central1/clusters/my-cluster/k8s/namespaces/default/services/frontend",
    "//container.googleapis.com/projects/my-project/locations/us-central1/clusters/my-cluster/k8s/namespaces/default/services/backend"
  ]
  workloads = [
    "//container.googleapis.com/projects/my-project/locations/us-central1/clusters/my-cluster/k8s/namespaces/default/apps/deployments/frontend",
    "//container.googleapis.com/projects/my-project/locations/us-central1/clusters/my-cluster/k8s/namespaces/default/apps/deployments/backend"
  ]
}

data "google_apphub_application" "my_app" {
  project        = "my-management-project"
  application_id = "my-app-id"
  location       = "global"
}

# Lookup discovered services by their underlying resource URI
data "google_apphub_discovered_service" "discovered_services" {
  for_each    = { for s in local.services : s => s }
  location    = "us-central1"
  project     = "my-management-project"
  service_uri = each.value
}

# Lookup discovered workloads by their underlying resource URI
data "google_apphub_discovered_workload" "discovered_workloads" {
  for_each     = { for w in local.workloads : w => w }
  location     = "us-central1"
  project      = "my-management-project"
  workload_uri = each.value
}

# Register the discovered services to the application
resource "google_apphub_service" "app_services" {
  for_each       = { for s in local.services : s => s }
  location       = "global"
  project        = "my-management-project"
  application_id = data.google_apphub_application.my_app.application_id
  service_id     = replace(element(split("/", each.value), length(split("/", each.value)) - 1), "_", "-")
  
  discovered_service = data.google_apphub_discovered_service.discovered_services[each.key].name
  
  attributes {
    environment {
      type = "STAGING"
    }
    criticality {
      type = "MISSION_CRITICAL"
    }
  }
}

# Register the discovered workloads to the application
resource "google_apphub_workload" "app_workloads" {
  for_each       = { for w in local.workloads : w => w }
  location       = "global"
  project        = "my-management-project"
  application_id = data.google_apphub_application.my_app.application_id
  workload_id    = element(split("/", each.value), length(split("/", each.value)) - 1)
  
  discovered_workload = data.google_apphub_discovered_workload.discovered_workloads[each.key].name
  
  attributes {
    environment {
      type = "STAGING"
    }
    criticality {
      type = "MISSION_CRITICAL"
    }
  }
}
```
```
