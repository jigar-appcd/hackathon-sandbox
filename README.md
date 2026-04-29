# EKS Base — StackGen Terraform

Converted from Terragrunt to StackGen-compatible Terraform.

Original module source:
`git::ssh://git@gitlab.com/redacted-org-x7k/platform-iac/cluster-modules/eks-base.git//resource`

## Environments
- dev
- staging
- prod

## Usage

Initialize with environment-specific backend:

```bash
terraform init -backend-config=env/<env>_backend.tf
terraform plan
```

## File Structure
- `main.tf` — Core infrastructure resources
- `variables.tf` — Input variable definitions
- `locals.tf` — Derived local values
- `outputs.tf` — Module outputs
- `provider.tf` — AWS + AWSCC provider configuration
- `env/` — Per-environment backend configurations
