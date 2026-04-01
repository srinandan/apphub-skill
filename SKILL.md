---
name: apphub-skill
description: Manage Google Cloud App Hub resources and write Terraform configs for App Hub. Use this skill when asked to list applications, register services/workloads, or generate Terraform code for App Hub.
metadata:
  author: srinandan
  version: "0.1"
---

# Google Cloud App Hub Skill

## Overview
This skill provides workflows and reference materials for managing Google Cloud App Hub resources, both via the `gcloud apphub` CLI and through Terraform (`google_apphub_*` resources).

### Key Concepts
- **Applications**: Logical containers that group services and workloads to represent a business function.
- **Services**: Logical representations of network-based capabilities (e.g., Forwarding Rules) used to access an application.
- **Workloads**: Logical representations of computing binary executions (e.g., Instance Groups, GKE Deployments) that perform specific tasks.

### Best Practices
- **Define clear boundaries**: Categorize projects logically. Group resources that share a joint operational lifecycle or business value.
- **Reflect business capabilities**: Define applications around business functions or end-to-end workflows, not just technical layers.
- **Sync with Observability**: Ensure your Google Cloud Observability scopes include the same projects as your App Hub boundary.
- **Assign clear ownership**: Always assign Owners, Environment, and Criticality attributes for discoverability and governance.

> [!TIP]
> Refer to [gcloud-apphub.md](./references/gcloud-apphub.md#infrastructure-mapping-service-vs-workload) for a detailed mapping of Google Cloud resources to Service and Workload types.

## Prerequisites

The App Hub skill requires the following conditions to be met to function correctly:

1.  **API Enabled**: The `apphub.googleapis.com` API must be enabled in the target project.
2.  **Boundary Configured**: An App Hub boundary must be configured for the project/organization. This can be verified by checking if the `crmNode` field is set in the boundary description.

If these are not met, most `gcloud apphub` commands will fail.

## Workflow

1. **Resolve session context and prerequisites** — at the start of each session, silently run:
   ```bash
   gcloud config get-value project 2>/dev/null
   gcloud config get-value compute/region 2>/dev/null
   gcloud services list --enabled --filter="name=apphub.googleapis.com" 2>/dev/null
   gcloud apphub boundary describe --location=global 2>/dev/null
   ```
   - Store the results as `SESSION_PROJECT` and `SESSION_LOCATION`.
   - **Verification**: Check if `apphub.googleapis.com` is enabled and if the boundary description contains a `crmNode` value.
   - **Action**:
     - If the API is disabled: Inform the user and ask if they would like to enable it (`gcloud services enable apphub.googleapis.com`).
     - If the boundary is missing `crmNode`: Ask the user: _"The App Hub boundary is not set for this project. Would you like to set it now? It is recommended to align this boundary with your Google Cloud Observability scopes."_
     - If they agree, run: `gcloud apphub boundary update --crm-node="projects/${SESSION_PROJECT}" --location=global --project=${SESSION_PROJECT}`.

2. **Parse** the user's request to identify the resource and action.
3. **Construct** the gcloud command using session defaults.
4. **Approval**:
   - For `list` and `describe` commands: Skip explicit approval and execute immediately.
   - For `create`, `delete`, or `update` commands: Show the command and ask for approval: _"Ready to run this command? (yes/no)"_
5. **Execute** and display the output.

6. **Application Creation Interaction**:
   - If the user asks to create an App Hub application:
     - **Scope Type (Mandatory)**: 
       - When creating an application, the `--scope-type` flag is **mandatory**.
       - If the location is "global", then `--scope-type=GLOBAL`.
       - If any other region, then `--scope-type=REGIONAL`.
     - **Location Selection**:
       - **Stop** and ask: _"Would you like to create a **regional** or **global** application?"_
       - **Explain**: _"Regional applications support workloads and services from a single region. Global applications support resources from multiple regions and the GCP global region."_
       - **Constraint**: **Global resources** (e.g., global forwarding rules, global Cloud Run services) can **only** be registered with **global applications**.
       - **If Regional**: State: _"I will use the region `${SESSION_LOCATION}`. Would you like to use a different region?"_
       - **If Global**: Use `--location=global`.
     - **Name Suggestion**: Suggest a name that reflects **business capability** (e.g., "Order Fulfillment") rather than technical layers.
     - **Attributes Selection**:
       - Ask: _"Would you like to provide optional attributes such as **business owners**, **criticality**, **developer owners**, or **environment type**?"_
       - If yes, collect details and include the relevant flags:
         - `--business-owners=[display-name=NAME],[email=EMAIL]` (foster accountability)
         - `--developer-owners=[display-name=NAME],[email=EMAIL]` (foster accountability)
         - `--criticality-type` (MISSION_CRITICAL, HIGH, MEDIUM, LOW; inform monitoring priorities)
         - `--environment-type` (PRODUCTION, STAGING, TEST, DEVELOPMENT; lifecycle stage)
7. **Service and Workload Registration Interaction**:
   - If the user asks to register a service or workload:
     - **Attribute Inheritance**:
       - Silently run `gcloud apphub applications describe [APP_ID]` to check for existing attributes.
       - If attributes (environment, criticality, owners) are set on the application:
         - **Ask**: _"The parent application has attributes set (e.g., Environment: PRODUCTION). Would you like to reuse these attributes for this [Service/Workload]?"_
         - If yes, use the application's attributes in the creation flags for the service/workload.
         - If no, proceed with standard registration without those specific flags (unless the user manually specified them).
     - **Bulk Registration Logic**:
       - If the user asks to register multiple resources (e.g., *"Onboard all services matching 'api-*'"*):
         1. **List and Filter**: Run `gcloud apphub discovered-services list` (or workloads) with the appropriate location and filter.
         2. **Propose Batch**: Present a concise list of found resources and their proposed registration IDs.
         3. **Attribute Inheritance**: Run the inheritance check above *once* for the entire batch. Ask: *"Would you like to apply the parent application's attributes to ALL of these resources?"*
         4. **Approval**: Obtain a single confirmation: *"Ready to register all [N] resources? (yes/no)"*
         5. **Execute**: Run the commands sequentially.


8. **Application Deletion Flow**:
   - If the user asks to delete an App Hub application:
     - **Pre-cleanup**: You must delete all services and workloads within the application first.
     - **Execute Scripts**: Run the following scripts in order before deleting the application:
       ```bash
       ./scripts/delete-all-services.sh ${SESSION_PROJECT} ${APP_ID}
       ./scripts/delete-all-workloads.sh ${SESSION_PROJECT} ${APP_ID}
       ```
     - **Final Deletion**: Only after the scripts complete successfully, proceed with the `gcloud apphub applications delete` command.

9. **Discovered Resources Dashboard Interaction**:
   - If the user uses keywords like **"dashboard"**, **"discovered"**, or **"onboard"** (e.g., *"show me a dashboard for discovered resources in app hub"*):
     - **Action**:
       1. Run `gcloud apphub discovered-services list --location=[LOCATION]` and `gcloud apphub discovered-workloads list --location=[LOCATION]`.
       2. **Consolidate** the output into a single Markdown table.
       3. **Formatting Rules**:
          - **ID**: Extract the short ID from the resource name (e.g., `apphub-008...`).
          - **Type**: "Service" or "Workload".
          - **Resource Name**: Extract the terminal segment of the underlying URI (e.g., if URI is `.../services/frontend`, use `frontend`).
          - **Location**: Use the region (e.g., `us-central1`).
       4. **Follow-up**: Ask the user: _"Would you like to register any of these resources? You can use the IDs from the table to register them individually or in bulk."_

## App Hub Dashboards

This skill provides scripts to generate markdown dashboards for App Hub resources. These are useful for getting a high-level overview of your application ecosystem.

### 1. Applications Dashboard
Shows all App Hub applications in the project (global and specified region).
```bash
./scripts/application-dashboard.sh [--project=PROJECT_ID] [--location=REGION]
```

### 2. Services Dashboard
Shows all registered services across all applications in the project.
```bash
./scripts/service-dashboard.sh [--project=PROJECT_ID] [--location=REGION]
```

### 3. Workloads Dashboard
Shows all registered workloads across all applications in the project.
```bash
./scripts/workload-dashboard.sh [--project=PROJECT_ID] [--location=REGION]
```

### Interaction Guideline
If the user asks for a **"dashboard"** or to **"list all services/workloads"** across the project, run the corresponding script and display the markdown output.

## Using gcloud for App Hub
When the user asks to manage App Hub resources directly (e.g., list applications, register a service, find discovered workloads), you should use the `mcp_gcloud_run_gcloud_command` tool if available, or the generic terminal command execution tool to run `gcloud apphub` commands.

For detailed command references, read [references/gcloud-apphub.md](references/gcloud-apphub.md).

## Generating Terraform for App Hub
When the user asks to generate Terraform code to manage App Hub infrastructure, use the `google` provider resources.

For detailed Terraform examples and available arguments, read [references/terraform-apphub.md](references/terraform-apphub.md).

## IAM Permissions

| Role | Access Level |
|------|--------------|
| `roles/apphub.admin` | Full administrative access |
| `roles/apphub.editor` | Editor access |
| `roles/apphub.viewer` | Read only access |

## Common Tasks
*   **Creating Applications:** An application acts as a container. Create it using `gcloud apphub applications create`. Follow the **Application Creation Interaction** guidelines for selecting the location and attributes.
*   **Registering Workloads/Services:** Register workloads and services into an application, pointing to discovered workloads/services. Follow the **Service and Workload Registration Interaction** guidelines for attribute inheritance.
    *   **Constraint**: Global resources must be registered with global applications. Regional resources can be registered with either regional (if in the same region) or global applications.
    *   **Example:** `gcloud apphub applications services create my-service --application=my-app --location=us-central1 --discovered-service=apphub-00000000-0000-0000-0f5a-15d1c21f4100 --project=apphub-srinandans-test`

## Error Handling

### Bug Reporting
If you encounter an unexpected problem, bug, or a failure that you cannot resolve:
1. Ask the user if they would like to create a GitHub issue for this bug.
2. If the user agrees, generate a descriptive title and body for the issue based on the error context.
3. Show the user the proposed issue content and the command to create it.
4. Ask for final approval before running the command.
5. Once approved, use the `gh` CLI to create the issue in the repository. For example:
   ```bash
   gh issue create --repo srinandan/apphub-skill --title "Title of the bug" --body "Description of the bug, including error messages and steps to reproduce."
   ```

## Auth & Setup

```bash
# Check auth
gcloud auth list

# Login
gcloud auth login

# Set project
gcloud config set project PROJECT_ID

# Enable App Hub API
gcloud services enable apphub.googleapis.com

# Check Boundary configuration
# Verify that 'crmNode' is present in the output
gcloud apphub boundary describe --location=global

# Set/Update Boundary configuration
gcloud apphub boundary update --crm-node="projects/PROJECT_ID" --location=global --project=PROJECT_ID
```
