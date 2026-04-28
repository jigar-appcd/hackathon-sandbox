# hackathon-sandbox

This repository contains Terraform configuration for provisioning and configuring AWS EKS.

## Key files
- `main.tf`
- `variables.tf`
- `outputs.tf`
- `versions.tf`
- `nodes.tf`
- `spot_nodes.tf`
- `dual_nodes.tf`
- `warm_nodes.tf`
- `fargate.tf`

## Directories
- `templates/`
- `terragrunt/`

The configuration supports multiple worker-node strategies and optional Fargate components.
