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

`apphub-skill` is an AI Agent Skill that can be used with your favorite CLI. Run this script to download and install the latest version:

```bash
curl -L https://raw.githubusercontent.com/srinandan/apphub-skill/main/installSkill.sh | sh -
```

To install a specific version or branch, set the `SKILL_VERSION` environment variable:

```bash
curl -L https://raw.githubusercontent.com/srinandan/apphub-skill/main/installSkill.sh | SKILL_VERSION=v1.0.0 sh -
```

## Usage Examples

Once installed, you can talk to Gemini in natural language:

-   *"List my App Hub applications in the global region"*
-   *"Create a global application called instavibe-prod"*
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
