include {
  path = find_in_parent_folders()
}

terraform {
  source = "git::ssh://git@gitlab.com/nielsen-media/platforms/tools-devops/apaas/kubernetes-mesh/eks-base.git//resource?ref=9.0.0"
}

locals {
  region                = "us-east-1"
  eks_version           = "1.33"
  env                   = "dev-qa-uat"
  vpc_id                = "vpc-0bbcc02b96d05c78c"
  amd_ami_id            = "ami-033f6caef470f7011"
  arm_ami_id            = "ami-057b8a3abd94810c2"
  subnets               = [
    "subnet-0db2ffecddbd7a25d", // Private subnet
    "subnet-0b091b3ed8a11e5fa", // Private subnet
    "subnet-02ca0a6cac30cded3"  // Private subnet
  ]
  kms_cmk_arn           = "arn:aws:kms:us-east-1:324683867184:key/86a1e1b1-4114-43e3-967c-7e7330c8e94c"
}

inputs = {
  aws_region          = local.region
  vpc_id              = local.vpc_id
  application_name    = "MBO-RESOLUTION"
  resource_id         = local.env
  eks_admin_arns      = {
    "Admin"    = "arn:aws:iam::374782863296:role/MPTDEVOPS-ADMIN", 
    "DevAdmin" = "arn:aws:iam::324683867184:role/DEVADMIN"
  }
  kms_cmk_arn         = local.kms_cmk_arn
  ami_id              = local.arm_ami_id
  eks_version         = local.eks_version
  stack               = "MBO-RESOLUTION"

  tags = {
    ApplicationName  = "MBO-RESOLUTION"
    Stack            = "MBO-RESOLUTION-EKS"
    Application      = "EKS"
    Version          = local.eks_version
    Owner            = "Resolution"
    DistributionList = "mboresolutionteam@nielsen.com"
    Region           = local.region
    Environment      = local.env
    CostCenter       = "7501303"
    Product          = "MBO"
  }
   
  map_roles = [
    {
      rolearn  = "arn:aws:iam::324683867184:role/cnc_airflow_dag_assumption_role"
      username = "airflow"
      groups   = ["system:masters"]
    },
    {
      rolearn  = "arn:aws:iam::324683867184:role/CREDITING-DEVELOPER"
      username = "resolution-developer"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::324683867184:role/CREDITING-DEVADMIN"
      username = "resolution-devadmin"
      groups   = ["developer"]
    },
    {
      rolearn  = "arn:aws:iam::324683867184:role/CNC-READONLY"
      username = "resolution-readonly"
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
      node_labels                      = "type=worker,addons=mbo-addons-m5xlarge,worker=m5xlarge,worker=mbo-loki,kubernetes.io/arch=amd64,kubernetes.io/os=linux"
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
      node_labels                      = "type=worker,addons=mbo-addons,worker=xlarge,worker=mbo-loki,kubernetes.io/arch=arm64,kubernetes.io/os=linux"
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