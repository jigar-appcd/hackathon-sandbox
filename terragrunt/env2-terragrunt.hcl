include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::ssh://git@gitlab.com/nielsen-media/platforms/tools-devops/apaas/kubernetes-mesh/eks-base.git//resource?ref=9.0.0"
}

locals {
  region        = "us-east-1"
  eks_version   = "1.33"
  env           = "prod-reprocess"
  vpc_id        = "vpc"
  amd_ami_id    = "ami-0"
  arm_ami_id    = "ami-1"
  subnets       = [
    "subnet-id",
    "subnet-id2"
  ]
  kms_cmk_arn   = "arn:aws:kms:us-east-1:accountid:key/423da438-4faf-491d-872c-1944e1462877"

  // Define the global tags here in the locals block
  tags = {
    Application      = "Resolution"
    Process          = "Resolution"
    Stack            = "MBO-RESOLUTION-EKS"
    Application      = "EKS"
    Version          = local.eks_version
    Owner            = "Resolution"
    DistributionList = "mailid"
    Region           = local.region
    Environment      = local.env
    CostCenter       = "7501303"
    Product          = "MBO"
  }
}

inputs = {
  aws_region        = local.region
  vpc_id            = local.vpc_id
  application_name  = "MBO-RESOLUTION"
  resource_id       = local.env
  service_ipv4_cidr = "10.100.0.0/16"
  eks_admin_arns    = {
    "Admin"    = "arn:aws:iam::accountid:role/MPTDEVOPS-ADMIN",
    "DevAdmin" = "arn:aws:iam::accountid:role/DEVADMIN"
  }
  kms_cmk_arn       = local.kms_cmk_arn
  ami_id            = local.arm_ami_id
  eks_version       = local.eks_version
  tags              = local.tags // Pass the local tags to the module

  map_roles = [
    {
      rolearn  = "arn:aws:iam::accountid:role/cnc_airflow_prod_dag_assumption_role"
      username = "airflow"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::accountid:role/EKS-MANAGED-ROLE"
      username = "resolution-developer"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::accountid:role/CNC-READONLY"
      username = "resolution-readonly"
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
        Application = "Resolution",
        Process     = "Resolution"
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
        Application = "Resolution",
        Process     = "Resolution"
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
        Application = "Resolution",
        Process     = "Resolution"
      })
    }
    
    worker-large-ondemand = {
      group_id         = "worker-large-ondemand"
      subnets          = ["subnet-id"]
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
        Application = "Resolution",
        Process     = "Resolution"
      })
    }
    
    worker-xlarge-ondemand = {
      group_id         = "worker-xlarge-ondemand"
      subnets          = ["subnet-id"]
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
        Application = "Resolution",
        Process     = "Resolution"
      })
    }
    
    admin-loki-ondemand = {
      group_id         = "admin-loki-ondemand"
      subnets          = local.subnets
      instance_type    = "m7g.4xlarge"
      desired_capacity = 0
      max_size         = 50
      min_size         = 0
      node_labels      = "type=worker,worker=mbo-loki,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
      node_taints      = "worker=mbo-loki:NoSchedule"
      max_pods         = "50"
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.arm_ami_id
      tags = merge(local.tags, {
        Application = "Resolution",
        Process     = "Resolution"
      })
    }
    
    admin-addons-ondemand = {
      group_id         = "admin-addons-ondemand"
      subnets          = local.subnets
      instance_type    = "m5.4xlarge"
      desired_capacity = 0
      max_size         = 2
      min_size         = 1
      node_labels      = "type=worker,addons=mbo-addons-m5xlarge,worker=m5xlarge,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
      node_taints      = "worker=admin:NoSchedule"
      max_pods         = "50"
      override_instance_types                  = ["r6i.xlarge", "r5.xlarge", "r7i.xlarge"]
      on_demand_allocation_strategy            = "lowest-price"
      ami_id           = local.amd_ami_id
      tags = merge(local.tags, {
        Application = "Resolution",
        Process     = "Resolution"
      })
    }
  }

  // Spot instance configuration map initialized empty
  spot_node_groups = {}
}