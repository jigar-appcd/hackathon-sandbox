locals {
  region      = var.region
  env         = var.environment
  vpc_id      = var.vpc_id
  amd_ami_id  = var.amd_ami_id
  arm_ami_id  = var.arm_ami_id
  subnets     = var.subnets
  kms_cmk_arn = var.kms_cmk_arn
  tags = merge(var.tags, {
    Environment = local.env
    Region      = local.region
    ManagedBy   = "terraform"
  })
}
