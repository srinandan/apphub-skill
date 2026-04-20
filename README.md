# Google Cloud App Hub Skill

[![CI](https://github.com/srinandan/apphub-skill/actions/workflows/ci.yml/badge.svg)](https://github.com/srinandan/apphub-skill/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/srinandan/apphub-skill)](https://github.com/srinandan/apphub-skill/releases)
[![License](https://img.shields.io/github/license/srinandan/apphub-skill)](LICENSE)

A skill for Gemini and AI agents to manage Google Cloud App Hub resources using `gcloud apphub` commands and Terraform.

## Features

- **Automated Setup**: Verifies `apphub.googleapis.com` API and project boundary configuration at the start of every session.
- **Resource Management**: Create, list, describe, and delete App Hub Applications, Services, and Workloads.
- **Interactive Application Creation**: Guides you through selecting regional vs. global applications and collecting optional attributes (owners, environment, criticality).
- **Automated Cleanup**: Intelligently deletes all associated services and workloads before attempting to delete an application.
- **Terraform Support**: Generates HCL code for App Hub resources based on your requirements.
- **Project Boundaries**: Proactively assists in setting or updating project boundaries.

## Installation

### Method 1: GitHub CLI (Recommended)

Install the skill using the GitHub CLI (`gh`):

```bash
gh skill install srinandan/apphub-skill --agent gemini
```

During installation, you will be guided through the following options:

```text
Select skill(s) to install: [root] apphub-skill - Manage Google Cloud App Hub resources and write Terraform configs for App Hub. Use this skill when asked to list applications, register services/w...
```

```text
? Installation scope: Global: install in home directory (available everywhere) 
```

### Method 2: Manual Installation

1. Download the source code for the desired release (e.g., `v0.5.0`):

```bash
curl -OL https://github.com/srinandan/apphub-skill/archive/refs/tags/v0.5.0.zip
```

2. Unzip and move the folder to your skills directory:

```bash
unzip v0.5.0.zip
mkdir -p ~/.gemini/skills
mv apphub-skill-0.5.0 ~/.gemini/skills/apphub-skill
rm v0.5.0.zip
```

## Usage Examples

Once installed, you can talk to Gemini in natural language:

-   *"List my App Hub applications in the global region"*
-   *"Create a global application called instavibe-prod"*
-   *"Show me a dashboard for discovered resources in app hub"*
-   *"Onboard all discovered services in us-central1 that match 'api-*' into the ecommerce-app"*
-   *"Delete the payment-service from the checkout application"*
-   *"Delete the entire legacy-app application"* (This will automatically clean up its services and workloads first)
-   *"Show me the boundary configuration for my project"*
-   *"Generate Terraform for a regional App Hub application with environment set to STAGING"*

## Prerequisites

- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) version **450.0.0** or higher.
- `apphub.googleapis.com` API enabled in your project.
- An App Hub boundary configured for the project or organization.

## Permissions

The following IAM roles are recommended to interact with App Hub:

| Role | Access Level |
|------|--------------|
| `roles/apphub.admin` | Full administrative access |
| `roles/apphub.editor` | Editor access |
| `roles/apphub.viewer` | Read only access |

## Contributing

Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## Support

This demo is NOT endorsed by Google or Google Cloud. The repo is intended for educational/hobbyists use only.

## License

This project is licensed under the terms of the [LICENSE](LICENSE) file.
