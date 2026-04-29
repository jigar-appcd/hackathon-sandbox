# Additional variables added during StackGen Terraform conversion

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "amd_ami_id" {
  description = "AMI ID for AMD/x86_64 worker nodes"
  type        = string
  default     = null
}

variable "arm_ami_id" {
  description = "AMI ID for ARM/Graviton worker nodes"
  type        = string
  default     = null
}

variable "subnets" {
  description = "List of subnet IDs for EKS worker nodes"
  type        = list(string)
  default     = []
}
