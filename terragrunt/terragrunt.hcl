include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::ssh://git@gitlab.com/redacted-org-x7k/platform-iac/cluster-modules/eks-base.git//resource?ref=9.0.0"
}

locals {
  region                = "us-east-1"
  eks_version           = "1.33"
  env                   = "env-d4q8-uat"
  vpc_id                = "vpc-01d2c3b4a5e6f7890"
  amd_ami_id            = "ami-0a1c3e5f7b9d2f4a6"
  arm_ami_id            = "ami-0b2d4f6a8c1e3a5d7"
  subnets               = [
    "subnet-0aa1bb2cc3dd4ee55", // Private subnet
    "subnet-0667aa8bb9cc0dd11", // Private subnet
    "subnet-0223cc4dd5ee6ff77"  // Private subnet
  ]
  kms_cmk_arn           = "arn:aws:kms:us-east-1:777788889999:key/1b2c3d4e-5f6a-4789-b1c2-d3e4f5a6b7c8"
}

inputs = {
  aws_region          = local.region
  vpc_id              = local.vpc_id
  application_name    = "APP-RND-D4"
  resource_id         = local.env
  eks_admin_arns      = {
    "Admin"    = "arn:aws:iam::777788889999:role/PLATFORM-ADMIN-RND",
    "DevAdmin" = "arn:aws:iam::777788889999:role/DEV-ADMIN-RND"
  }
  kms_cmk_arn         = local.kms_cmk_arn
  ami_id              = local.arm_ami_id
  eks_version         = local.eks_version
  stack               = "APP-RND-D4"

  tags = {
    ApplicationName  = "APP-RND-D4"
    Stack            = "APP-RND-D4-EKS"
    Application      = "EKS-RND"
    Version          = local.eks_version
    Owner            = "team-rnd-d4"
    DistributionList = "team-rnd-d4@example.com"
    Region           = local.region
    Environment      = local.env
    CostCenter       = "4205179"
    Product          = "PRD-RND"
  }
   
  map_roles = [
    {
      rolearn  = "arn:aws:iam::777788889999:role/automation-runner-rnd"
      username = "svc-automation-rnd"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::777788889999:role/ENGINEERING-DEVELOPER-RND"
      username = "team-developer-rnd"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::777788889999:role/ENGINEERING-DEVADMIN-RND"
      username = "team-devadmin-rnd"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::777788889999:role/PLATFORM-READONLY-RND"
      username = "team-readonly-rnd"
      groups   = ["readonly"]
    }
  ]

  node_groups = {
    # 1. Master Node
    "master-node" = {
      group_id         = "master-node"
      subnets          = local.subnets
      instance_type    = "r6g.xlarge"
      desired_capacity = 1
      max_size         = 2
      min_size         = 1
      node_labels      = "type=master"
      max_pods         = 30
      ami_id           = local.arm_ami_id
      override_instance_types = [] 
    },

    "worker-m5xlarge-amd" = {
      group_id                         = "worker-m5xlarge-amd"
      subnets                          = local.subnets
      instance_type                    = "m5.xlarge"
      desired_capacity                 = 2
      max_size                         = 15
      min_size                         = 2
      node_labels                      = "type=worker,addons=addons-rnd-m5xlarge,worker=m5xlarge,worker=ops-logs-rnd,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      on_demand_base_capacity          = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy         = "price-capacity-optimized"
      max_pods                         = "50"
      override_instance_types          = [ "r6i.xlarge", "m6i.xlarge", "r6a.xlarge", "m6a.xlarge", "r5.xlarge", "r4.xlarge", "m4.xlarge", "r5a.xlarge", "m5a.xlarge", "r5d.xlarge" ]
      ami_id                           = local.amd_ami_id
    },

    "worker-small-spot" = {
      group_id                         = "worker-small-spot"
      subnets                          = local.subnets
      instance_type                    = "r6g.xlarge"
      desired_capacity                 = 1
      max_size                         = 50
      min_size                         = 0
      node_labels                      = "type=worker,addons=addons-rnd,worker=xlarge,worker=ops-logs-rnd,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
      max_pods                         = "50"
      override_instance_types          = ["r7g.xlarge", "r6gd.xlarge", "r6a.xlarge", "r5a.xlarge", "r5.xlarge", "r5d.xlarge","m7g.xlarge", "m5.xlarge"]      
      on_demand_base_capacity          = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy         = "price-capacity-optimized"
      ami_id                           = local.arm_ami_id
    },

    "worker-medium-spot" = {
      group_id                         = "worker-medium-spot"
      subnets                          = local.subnets
      instance_type                    = "r6g.2xlarge"
      desired_capacity                 = 1
      max_size                         = 50
      min_size                         = 0
      node_labels                      = "type=worker,worker=2xlarge,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
      max_pods                         = "50"
      override_instance_types          = ["r7g.2xlarge","r6a.2xlarge","r5a.2xlarge","m6g.4xlarge","r5.2xlarge","m5.4xlarge"]
      
      on_demand_base_capacity          = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy         = "price-capacity-optimized"
      ami_id                           = local.arm_ami_id
    },

    "worker-xlarge-spot" = {
      group_id                         = "worker-xlarge-spot"
      subnets                          = local.subnets
      instance_type                    = "r7gd.metal"
      desired_capacity                 = 0
      max_size                         = 50
      min_size                         = 0
      node_labels                      = "type=worker,worker=16xlarge,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
      max_pods                         = "50"
      override_instance_types          = ["r6g.16xlarge","r6gd.16xlarge","r7g.16xlarge","r6a.16xlarge","r5a.16xlarge","r5.16xlarge"]
      
      on_demand_base_capacity          = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy         = "price-capacity-optimized"
      ami_id                           = local.arm_ami_id
    }
  }

}