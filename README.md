# Terraform ArgoCD Provisioning

A reusable Terraform and Jenkins workflow for declaratively provisioning ArgoCD `Application` resources across isolated environments. It is a public-safe portfolio implementation based on a practical CI/CD provisioning pattern.

Terraform owns the ArgoCD resource lifecycle; ArgoCD remains responsible for reconciling the referenced Git configuration to Kubernetes or OpenShift. This repository does not deploy workload manifests directly to a cluster.

The problem addressed is repeatable, reviewable provisioning of ArgoCD Applications without creating them manually through the ArgoCD UI.

<p align="center">
  <img src="docs/GitOps%20Infrastructure%20Provisioning%20Workflow.png" alt="Conceptual GitOps infrastructure provisioning flow from Git through Jenkins, Terraform, ArgoCD, and Kubernetes" width="100%">
</p>

> The image is a conceptual GitOps workflow overview. This repository's implemented Terraform scope is ArgoCD `Application` provisioning, as described below.

## What it demonstrates

- Terraform-managed ArgoCD Applications using the `argoproj-labs/argocd` provider.
- Jenkins orchestration for plan, apply, and deliberately confirmed destroy workflows.
- Isolated state per ArgoCD project/environment outside the Jenkins workspace.
- A generic `development` / `staging` / `production` environment mapping.
- Runtime credential injection through Jenkins Credentials rather than source-controlled secrets.
- Reusable application metadata generated from pipeline parameters.

## Technology stack

- Terraform and the `argoproj-labs/argocd` provider
- Jenkins Declarative Pipeline (Groovy)
- ArgoCD and Helm application sources
- Kubernetes or OpenShift as the ArgoCD destination platform

## Responsibilities

| Component | Responsibility |
| --- | --- |
| Terraform | Declares and tracks ArgoCD `Application` resources. |
| Jenkins | Validates inputs, creates Terraform input, retrieves credentials, and runs the selected Terraform action. |
| ArgoCD | Watches the configured source repository and reconciles the application to its target cluster. |
| Kubernetes / OpenShift | Runs the workloads reconciled by ArgoCD. |

## Repository layout

```text
.
├── Jenkinsfile-argocd-terraform   # Parameterized PLAN/APPLY/DESTROY pipeline
├── argocd-environments.yml        # Public example environment-to-credential mapping
├── argocd/
│   ├── applications.tf            # ArgoCD Application resource
│   ├── providers.tf               # Provider configuration
│   ├── variables.tf               # Reusable input contract
│   └── terraform.tfvars.example   # Safe local configuration example
└── LICENSE
```

## Prerequisites

- Terraform and network access to the target ArgoCD API.
- An ArgoCD account or token-backed credential authorized to manage the selected project.
- Jenkins with Pipeline, Credentials Binding, and Pipeline Utility Steps (`readYaml`) plugins.
- A Jenkins agent with Terraform available and read/write access to the configured persistent state directory.
- An ArgoCD project, destination cluster, and Git repository containing the referenced Helm chart paths.

## Configuration

`argocd-environments.yml` is an intentionally non-secret public example. In a real deployment, replace its placeholder endpoint and credential ID values in your private deployment configuration:

```yaml
credentials:
  development:
    server: "https://argocd.development.example.com"
    credentialId: "argocd-development"
```

Create Jenkins **Username with password** credentials with IDs matching the mapping. The pipeline reads the selected ID at runtime and exports the resulting values only as `TF_VAR_argocd_username` and `TF_VAR_argocd_password`. Never put credentials in this repository, a `.tfvars` file, or Jenkins parameters.

For a local, non-production experiment, copy `argocd/terraform.tfvars.example` to a private ignored `.tfvars` file and provide credentials through environment variables:

```bash
cd argocd
cp terraform.tfvars.example terraform.tfvars
export TF_VAR_argocd_username='your-username'
export TF_VAR_argocd_password='your-password-or-token'
terraform init
terraform plan
```

The example uses placeholders only. Update the project, Git source, revision, namespace, destination server, chart paths, and values file to match your own ArgoCD setup.

## Jenkins workflow

The pipeline has one required `ACTION` choice and a target `ARGOCD_ENVIRONMENT`. It dynamically creates an ignored `jenkins.auto.tfvars.json` file for the selected generic applications, then removes it with any saved plans after the build.

### PLAN

Select `ACTION=PLAN`. Jenkins validates inputs, initializes and validates Terraform, creates the input file, and runs a saved `terraform plan`. No ArgoCD resource is changed.

```text
ACTION=PLAN
ARGOCD_ENVIRONMENT=development
PROJECT=platform-development
SERVICE_API=true
```

### APPLY

Select `ACTION=APPLY`. Jenkins first runs the same saved plan, then applies that exact plan. This creates or updates only the ArgoCD Applications represented in the state and selected pipeline input.

```text
ACTION=APPLY
ARGOCD_ENVIRONMENT=staging
PROJECT=platform-staging
SERVICE_API=true
```

### DESTROY

Select `ACTION=DESTROY` **and** set `CONFIRM_DESTROY=true`. The pipeline otherwise fails before Terraform starts. A destroy plan is generated and then applied only in this explicit branch; a normal PLAN or APPLY can never destroy resources. Review the environment, project/state key, selected services, and generated destroy plan before starting this action.

The included confirmation is an intentional safety guard. Teams that require an additional human approval can protect the Jenkins job or add a Jenkins `input` approval step under their own change-control policy.

```text
ACTION=DESTROY
CONFIRM_DESTROY=true
ARGOCD_ENVIRONMENT=development
PROJECT=platform-development
```

## Multi-environment and state design

The public mapping exposes `development`, `staging`, and `production`. Each entry resolves to an ArgoCD server and a Jenkins credential ID. The `PROJECT` parameter also becomes a sanitized state key, producing an isolated local state path:

```text
STATE_BASE_DIR/<project>/terraform.tfstate
```

`STATE_BASE_DIR` defaults to `/var/lib/jenkins/terraform-state/argocd` and must be persistent storage outside the Jenkins workspace. This implementation deliberately uses a local persistent backend; it does not claim remote backend locking or cross-agent state coordination. For a highly available Jenkins setup, use a shared, lock-capable backend appropriate to your platform.

## Security considerations

- `.gitignore` excludes Terraform state, plans, generated inputs, private `.tfvars`, local environment files, and common key material.
- No actual endpoints, credential IDs, usernames, passwords, tokens, clusters, or repositories are included.
- Terraform state can contain infrastructure metadata and must never be committed or uploaded as a public build artifact.
- The configured ArgoCD identity should have only the permissions required for the project and destination it manages.
- Placeholder values in this repository are not deployable configuration.

## Current status

Implemented: ArgoCD Application provisioning through Terraform; Jenkins PLAN, APPLY, and explicit DESTROY operations; generated application input; environment mapping; local persistent state-path handling; and Jenkins credential injection.

Not implemented here: provisioning ArgoCD itself, workload manifests, ArgoCD projects/repositories/RBAC, remote Terraform backends, automated policy checks, or an application source repository. Those are deliberately outside this repository’s demonstrated scope.

## Roadmap

- Add CI validation and formatting checks for pull requests.
- Support a remote Terraform backend with state locking.
- Add policy-as-code and plan review gates.
- Add automated tests for the generated Terraform input contract.
- Parameterize application catalogues outside the Jenkinsfile for larger deployments.

## License

Released under the [MIT License](LICENSE).
