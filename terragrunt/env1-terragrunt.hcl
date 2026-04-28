include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::ssh://git@gitlab.com/redacted-org-x7k/platform-iac/cluster-modules/eks-base.git//resource?ref=9.0.0"
}

locals {
  region                = "us-east-1"
  eks_version           = "1.33"
  env                   = "env-a9f2-load"
  vpc_id                = "vpc-0d7a4b21f9c6e3812"
  amd_ami_id            = "ami-0f2a9d1c3b4e6a7d8"
  arm_ami_id            = "ami-0c7b2a1d9e4f6a3b5"
  subnets               = [
    "subnet-0123ab45cd67ef890",
    "subnet-0987fe65dc43ba210",
    "subnet-0a1b2c3d4e5f67890",
    "subnet-0f9e8d7c6b5a43210"
  ]
  kms_cmk_arn           = "arn:aws:kms:us-east-1:111122223333:key/6f4b8a91-c2d3-4e5f-8a7b-1c2d3e4f5a6b"
}

inputs = {
  aws_region       = local.region
  vpc_id           = local.vpc_id
  application_name = "APP-RND-X91"
  resource_id      = local.env
  eks_admin_arns   = {
    "Admin"    = "arn:aws:iam::111122223333:role/PLATFORM-ADMIN-RND",
    "DevAdmin" = "arn:aws:iam::111122223333:role/DEV-ADMIN-RND"
  }
  kms_cmk_arn      = local.kms_cmk_arn
  ami_id           = local.arm_ami_id
  eks_version      = local.eks_version
  tags = {
    ApplicationName  = "APP-RND-X91"
    Stack                = "APP-RND-X91-EKS"
    Application          = "EKS-RND"
    Version              = local.eks_version
    Owner                = "team-rnd-q4"
    DistributionList     = "team-rnd-q4@example.com"
    Region               = local.region
    Environment          = local.env
    CostCenter           = "9482"
    Product              = "PRD-RND"
  }

  map_roles = [
    {
      rolearn  = "arn:aws:iam::111122223333:role/automation-runner-rnd"
      username = "svc-automation-rnd"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::111122223333:role/ENGINEERING-DEVELOPER-RND"
      username = "team-developer-rnd"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::111122223333:role/ENGINEERING-DEVADMIN-RND"
      username = "team-devadmin-rnd"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::111122223333:role/PLATFORM-READONLY-RND"
      username = "team-readonly-rnd"
      groups   = ["readonly"]
    }
  ]

  node_groups = {
    master-node = {
      group_id             = "master-node"
      subnets              = local.subnets
      instance_type        = "r6g.xlarge"
      desired_capacity     = 1
      max_size             = 1
      min_size             = 1
      node_labels          = "type=master"
      max_pods             = 30
      ami_id               = local.arm_ami_id
    }

    worker-small-spot = {
      group_id             = "worker-small-spot"
      subnets              = local.subnets
      instance_type        = "m5.xlarge"
      desired_capacity     = 0
      max_size             = 300
      min_size             = 0
      node_labels          = "type=worker,addons=addons-rnd,worker=small,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints          = ""
      max_pods             = "50"
      override_instance_types = ["r6i.xlarge","r5.xlarge","r7i.xlarge","m6i.2xlarge","m5.2xlarge","m7i.2xlarge"]
      
      # These fields are allowed in node_groups but rejected in spot_node_groups
      on_demand_allocation_strategy            = "lowest-price"
      on_demand_base_capacity                  = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy                 = "price-capacity-optimized"
      ami_id               = local.amd_ami_id
    }

    worker-medium-spot = {
      group_id             = "worker-medium-spot"
      subnets              = local.subnets
      instance_type        = "m5.4xlarge"
      desired_capacity     = 2
      max_size             = 100
      min_size             = 0
      node_labels          = "type=worker,worker=medium,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints          = ""
      max_pods             = "50"
      override_instance_types = ["r6i.2xlarge","r5.2xlarge","r7i.2xlarge","r6a.2xlarge","r7a.2xlarge"]

      on_demand_allocation_strategy            = "lowest-price"
      on_demand_base_capacity                  = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy                 = "price-capacity-optimized"
      ami_id               = local.amd_ami_id
    }

    worker-large-ondemand = {
      group_id             = "worker-large-ondemand"
      subnets              = ["subnet-0b3c4d5e6f708192a"]
      instance_type        = "r5.8xlarge"
      desired_capacity     = 0
      max_size             = 400
      min_size             = 0
      node_labels          = "type=worker,worker=large,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints          = "worker=large:NoSchedule"
      max_pods             = "50"
      override_instance_types = ["r6i.8xlarge","r7i.8xlarge"]
      
      on_demand_allocation_strategy            = "lowest-price"
      on_demand_base_capacity                  = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy                 = "price-capacity-optimized"
      ami_id               = local.amd_ami_id
    }

    worker-xlarge-ondemand = {
      group_id             = "worker-xlarge-ondemand"
      subnets              = ["subnet-0c4d5e6f708192a3b"]
      instance_type        = "r5.24xlarge"
      desired_capacity     = 0
      max_size             = 200
      min_size             = 0
      node_labels          = "type=worker,worker=xlarge,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints          = "worker=xlarge:NoSchedule"
      max_pods             = "50"
      override_instance_types = ["r6i.24xlarge","r7i.24xlarge","r6i.16xlarge","r5.16xlarge","r7i.16xlarge","r6i.32xlarge"]
      
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy                 = "price-capacity-optimized"
      ami_id               = local.amd_ami_id
    }

    admin-loki-ondemand = {
      group_id             = "admin-loki-ondemand"
      subnets              = local.subnets
      instance_type        = "m7g.4xlarge"
      desired_capacity     = 0
      max_size             = 50
      min_size             = 0
      node_labels          = "type=admin,worker=ops-logs-rnd,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
      node_taints          = "worker=ops-logs-rnd:NoSchedule"
      max_pods             = "50"
      override_instance_types = ["r6g.xlarge","r7g.xlarge"]
      
      on_demand_allocation_strategy            = "lowest-price"
      on_demand_base_capacity                  = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy                 = "price-capacity-optimized"
      ami_id               = local.arm_ami_id
    }

    admin-addons-ondemand = {
      group_id             = "admin-addons-ondemand"
      subnets              = local.subnets
      instance_type        = "m5.4xlarge"
      desired_capacity     = 1
      max_size             = 3
      min_size             = 1
      node_labels          = "type=admin,addons=addons-rnd-m5xlarge,worker=m54xlarge,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints          = "worker=admin:NoSchedule"
      max_pods             = "50"
      override_instance_types = ["r6i.xlarge","r7i.xlarge","r5.xlarge"]
      
      on_demand_allocation_strategy            = "lowest-price"
      on_demand_base_capacity                  = "0"
      on_demand_percentage_above_base_capacity = "0"
      spot_allocation_strategy                 = "price-capacity-optimized"
      ami_id               = local.amd_ami_id
    }
  }
}