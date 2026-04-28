include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::ssh://git@gitlab.com/redacted-org-x7k/platform-iac/cluster-modules/eks-base.git//resource?ref=9.0.0"
}

locals {
  region        = "us-east-1"
  eks_version   = "1.33"
  env           = "env-p7k3-reprocess"
  vpc_id        = "vpc-0a6d2f4b8c1e97350"
  amd_ami_id    = "ami-0b4e6c8a1d3f5e7a9"
  arm_ami_id    = "ami-0d9a7c5e3b1f4a6c8"
  subnets       = [
    "subnet-01ab23cd45ef67890",
    "subnet-09fe87dc65ba43210"
  ]
  kms_cmk_arn   = "arn:aws:kms:us-east-1:444455556666:key/2a3b4c5d-6e7f-4819-a2b3-c4d5e6f7a8b9"

  // Define the global tags here in the locals block
  tags = {
    Application      = "team-rnd-z9"
    Process          = "process-rnd-z9"
    Stack            = "APP-RND-Z9-EKS"
    Application      = "EKS-RND"
    Version          = local.eks_version
    Owner            = "owner-rnd-z9"
    DistributionList = "alerts-rnd-z9@example.com"
    Region           = local.region
    Environment      = local.env
    CostCenter       = "5310248"
    Product          = "PRD-RND"
  }
}

inputs = {
  aws_region        = local.region
  vpc_id            = local.vpc_id
  application_name  = "APP-RND-Z9"
  resource_id       = local.env
  service_ipv4_cidr = "10.100.0.0/16"
  eks_admin_arns    = {
    "Admin"    = "arn:aws:iam::444455556666:role/PLATFORM-ADMIN-RND",
    "DevAdmin" = "arn:aws:iam::444455556666:role/DEV-ADMIN-RND"
  }
  kms_cmk_arn       = local.kms_cmk_arn
  ami_id            = local.arm_ami_id
  eks_version       = local.eks_version
  tags              = local.tags // Pass the local tags to the module

  map_roles = [
    {
      rolearn  = "arn:aws:iam::444455556666:role/automation-prod-runner-rnd"
      username = "svc-automation-prod-rnd"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::444455556666:role/EKS-MANAGED-ROLE-RND"
      username = "team-developer-rnd"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::444455556666:role/PLATFORM-READONLY-RND"
      username = "team-readonly-rnd"
      groups   = ["readonly"]
    }
  ]

  /* Provide required ASG specs */
  node_groups = {
    master-node = {
      group_id         = "master-node"
      subnets          = local.subnets
      instance_type    = "m5.xlarge"
      desired_capacity = 1
      max_size         = 3
      min_size         = 1
      node_labels      = "type=master"
      max_pods         = 25
      ami_id           = local.amd_ami_id
      tags = merge(local.tags, {
        Application = "team-rnd-z9",
        Process     = "process-rnd-z9"
      })
    }
    
    worker-small-spot = {
      group_id         = "worker-small-spot"
      subnets          = local.subnets
      instance_type    = "m5.2xlarge"
      desired_capacity = 0
      max_size         = 200
      min_size         = 1
      node_labels      = "type=worker,worker=small,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints      = ""
      max_pods         = "50"
      override_instance_types                  = ["r6i.xlarge", "r5.xlarge", "r7i.xlarge", "m6i.2xlarge", "m7i.2xlarge"]
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.amd_ami_id
      tags = merge(local.tags, {
        Application = "team-rnd-z9",
        Process     = "process-rnd-z9"
      })
    }
    
    worker-medium-spot = {
      group_id         = "worker-medium-spot"
      subnets          = local.subnets
      instance_type    = "m5.4xlarge"
      desired_capacity = 0
      max_size         = 0
      min_size         = 0
      node_labels      = "type=worker,worker=medium,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints      = ""
      max_pods         = "50"
      override_instance_types                  = []
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.amd_ami_id
      tags = merge(local.tags, {
        Application = "team-rnd-z9",
        Process     = "process-rnd-z9"
      })
    }
    
    worker-large-ondemand = {
      group_id         = "worker-large-ondemand"
      subnets          = ["subnet-0aa11bb22cc33dd44"]
      instance_type    = "r5.8xlarge"
      desired_capacity = 0
      max_size         = 40
      min_size         = 0
      node_labels      = "type=worker,worker=large,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints      = "worker=large:NoSchedule"
      max_pods         = "50"
      override_instance_types                  = ["r6i.8xlarge", "r7i.8xlarge", "r6i.16xlarge", "r5.16xlarge", "r7i.16xlarge", "r6i.24xlarge", "r5.24xlarge", "r7i.24xlarge", "r6i.32xlarge", "r7i.48xlarge"]
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.amd_ami_id
      tags = merge(local.tags, {
        Application = "team-rnd-z9",
        Process     = "process-rnd-z9"
      })
    }
    
    worker-xlarge-ondemand = {
      group_id         = "worker-xlarge-ondemand"
      subnets          = ["subnet-05566aa77bb88cc99"]
      instance_type    = "r5.24xlarge"
      desired_capacity = 0
      max_size         = 90
      min_size         = 0
      node_labels      = "type=worker,worker=xlarge,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints      = "worker=xlarge:NoSchedule"
      max_pods         = "50"
      override_instance_types                  = ["r6i.24xlarge", "r7i.24xlarge", "r6i.16xlarge", "r5.16xlarge", "r7i.16xlarge", "r6i.32xlarge"]
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.amd_ami_id
      tags = merge(local.tags, {
        Application = "team-rnd-z9",
        Process     = "process-rnd-z9"
      })
    }
    
    admin-loki-ondemand = {
      group_id         = "admin-loki-ondemand"
      subnets          = local.subnets
      instance_type    = "m7g.4xlarge"
      desired_capacity = 0
      max_size         = 50
      min_size         = 0
      node_labels      = "type=worker,worker=ops-logs-rnd,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
      node_taints      = "worker=ops-logs-rnd:NoSchedule"
      max_pods         = "50"
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.arm_ami_id
      tags = merge(local.tags, {
        Application = "team-rnd-z9",
        Process     = "process-rnd-z9"
      })
    }
    
    admin-addons-ondemand = {
      group_id         = "admin-addons-ondemand"
      subnets          = local.subnets
      instance_type    = "m5.4xlarge"
      desired_capacity = 0
      max_size         = 2
      min_size         = 1
      node_labels      = "type=worker,addons=addons-rnd-m5xlarge,worker=m5xlarge,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints      = "worker=admin:NoSchedule"
      max_pods         = "50"
      override_instance_types                  = ["r6i.xlarge", "r5.xlarge", "r7i.xlarge"]
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.amd_ami_id
      tags = merge(local.tags, {
        Application = "team-rnd-z9",
        Process     = "process-rnd-z9"
      })
    }
  }

  // Spot instance configuration map initialized empty
  spot_node_groups = {}
}