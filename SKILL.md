---
name: apphub-skill
description: Manage Google Cloud App Hub resources and write Terraform configs for App Hub. Use this skill when asked to list applications, register services/workloads, discover assets, or generate Terraform code for App Hub.
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
   gcloud services list --enabled --filter="name:apphub.googleapis.com" 2>/dev/null
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
     - **Location Selection**:
       - **Stop** and ask: _"Would you like to create a **regional** or **global** application?"_
       - **Explain**: _"Regional applications support workloads and services from a single region. Global applications support resources from multiple regions and the GCP global region."_
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
7. **Application Deletion Flow**:
   - If the user asks to delete an App Hub application:
     - **Pre-cleanup**: You must delete all services and workloads within the application first.
     - **Execute Scripts**: Run the following scripts in order before deleting the application:
       ```bash
       ./scripts/delete-all-services.sh ${SESSION_PROJECT} ${APP_ID}
       ./scripts/delete-all-workloads.sh ${SESSION_PROJECT} ${APP_ID}
       ```
     - **Final Deletion**: Only after the scripts complete successfully, proceed with the `gcloud apphub applications delete` command.

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
*   **Listing Discovered Assets:** Run `gcloud apphub discovered-services list --location=<LOCATION>` to find services that can be onboarded to App Hub.
*   **Filtering Discovered Assets:** Search for services by service reference using `--filter="SERVICE_REFERENCE:*<PATTERN>"`.
*   **Filtering Workloads by Functional Type:** Search for workloads by functional type (e.g., `AGENT`, `MCP_SERVER`) using `--filter="workloadProperties.functionalType:<TYPE>"`.
*   **Looking up Discovered Assets:** Find exactly which App Hub asset corresponds to a Google Cloud resource URI using `gcloud apphub discovered-workloads lookup --uri=<URI>`.
*   **Creating Applications:** An application acts as a container. Create it using `gcloud apphub applications create`. Follow the **Application Creation Interaction** guidelines for selecting the location and attributes.
*   **Registering Workloads/Services:** Register workloads and services into an application, pointing to discovered workloads/services.
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
