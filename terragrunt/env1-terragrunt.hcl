include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::ssh://git@gitlab.com/nielsen-media/platforms/tools-devops/apaas/kubernetes-mesh/eks-base.git//resource?ref=9.0.0"
}

locals {
  region                = "us-east-1"
  eks_version           = "1.33"
  env                   = "perf-parallel-load"
  vpc_id                = "vpc"
  amd_ami_id            = "ami-1"
  arm_ami_id            = "ami-2"
  subnets               = [
    "subnet-0",
    "subnet-1",
    "subnet-2",
    "subnet-3"
  ]
  kms_cmk_arn           = "arn:aws:kms:us-east-1:accountid:key/86a1e1b1-4114-43e3-967c-7e7330c8e94c"
}

inputs = {
  aws_region       = local.region
  vpc_id           = local.vpc_id
  application_name = "MBO-RESOLUTION"
  resource_id      = local.env
  eks_admin_arns   = {
    "Admin"    = "arn:aws:iam::accountid:role/MPTDEVOPS-ADMIN", 
    "DevAdmin" = "arn:aws:iam::accountid:role/DEVADMIN"
  }
  kms_cmk_arn      = local.kms_cmk_arn
  ami_id           = local.arm_ami_id
  eks_version      = local.eks_version
  tags = {
    ApplicationName  = "MBO-RESOLUTION"
    Stack                = "MBO-RESOLUTION-EKS"
    Application          = "EKS"
    Version              = local.eks_version
    Owner                = "Resolution"
    DistributionList     = "mailid"
    Region               = local.region
    Environment          = local.env
    CostCenter           = "6666"
    Product              = "MBO"
  }

  map_roles = [
    {
      rolearn  = "arn:aws:iam::accountid:role/cnc_airflow_dag_assumption_role"
      username = "airflow"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::accountid:role/CREDITING-DEVELOPER"
      username = "resolution-developer"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::accountid:role/CREDITING-DEVADMIN"
      username = "resolution-devadmin"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::accountid:role/CNC-READONLY"
      username = "resolution-readonly"
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
      node_labels          = "type=worker,addons=mbo-addons,worker=small,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
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
      subnets              = ["subnet-id"]
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
      subnets              = ["subnet-id"]
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
      node_labels          = "type=admin,worker=mbo-loki,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
      node_taints          = "worker=mbo-loki:NoSchedule"
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
      node_labels          = "type=admin,addons=mbo-addons-m5xlarge,worker=m54xlarge,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
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