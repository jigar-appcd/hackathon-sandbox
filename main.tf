# AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "random" {
}

locals {
  worker_role_name = var.worker_role == "" ? aws_iam_role.eks_worker_role[0].name : data.aws_iam_role.eks_worker_role[0].id
  worker_role_arn = var.worker_role == "" ? aws_iam_role.eks_worker_role[0].arn : data.aws_iam_role.eks_worker_role[0].arn
  resource_name = upper(
    var.resource_id != "" ? "${var.application_name}-${var.resource_id}" : var.application_name,
  )
  resource_tags = merge(var.tags, {
    Name                                           = local.resource_name
    ApplicationName                                = var.application_name
    "kubernetes.io/cluster/${local.resource_name}" = "owned"
  })
}

data "aws_vpc" "eks_vpc" {
  id = var.vpc_id
}

# EKS IAM Role
resource "aws_iam_role" "eks_master_role" {
  name                  = "${local.resource_name}-EKSMasterRole"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

tags = local.resource_tags

}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_master_role.name
}

resource "aws_kms_grant" "eks_master_cmk_grant" {
  name              = "${local.resource_name}-EKS-Master-Grant"
  key_id            = var.kms_cmk_arn
  grantee_principal = aws_iam_role.eks_master_role.arn
  operations        = ["Decrypt", "GenerateDataKeyWithoutPlaintext","CreateGrant"]
}

# EKS Security Group
resource "aws_security_group" "eks_master" {
  name        = "${local.resource_name}-EKS-MASTER"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.resource_tags
}

resource "aws_security_group_rule" "eks_master_ingress_https" {
  description       = "Allow VPC resources to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.eks_master.id
  cidr_blocks       = ["10.0.0.0/8","172.16.0.0/12","100.64.0.0/10"]
  to_port           = 443
  type              = "ingress"
}

data "aws_subnets" "eks_subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

  tags = {
    EKS = "supported"
  }

  filter {
    name   = "tag:Network"
    values = ["PRIVATE", "Private"]
  }
}

# EKS CloudWatch
resource "aws_cloudwatch_log_group" "eks_cloudwatch_log" {
  name              = "/aws/eks/${local.resource_name}/cluster"
  retention_in_days = var.cloudwatch_retention
}

# EKS Cluster
resource "aws_eks_cluster" "eks_master" {
  name                      = local.resource_name
  role_arn                  = aws_iam_role.eks_master_role.arn
  version                   = var.eks_version
  enabled_cluster_log_types = var.enable_eks_logs ? ["api", "scheduler", "controllerManager", "audit", "authenticator"] : []

  access_config {
    authentication_mode = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = var.bootstrap_cluster_creator_admin_permissions
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
  }

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.eks_master.id]
    subnet_ids              = data.aws_subnets.eks_subnets.ids
    public_access_cidrs     = var.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = var.kms_cmk_arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    aws_cloudwatch_log_group.eks_cloudwatch_log,
  ]

  tags = local.resource_tags
}

## Adding eks addons
data "aws_eks_addon_version" "this" {
  for_each = var.eks_addons

  addon_name         = try(each.value.name, each.key)
  kubernetes_version = var.eks_version
  most_recent        = try(each.value.most_recent, true)
}

resource "aws_eks_addon" "this" {
  for_each = var.eks_addons

  cluster_name = local.resource_name
  addon_name   = try(each.value.name, each.key)

  addon_version               = try(each.value.addon_version, data.aws_eks_addon_version.this[each.key].version)
  configuration_values        = try(each.value.configuration_values, null)
  preserve                    = try(each.value.preserve, true)
  resolve_conflicts_on_create = try(each.value.resolve_conflicts_on_create, "OVERWRITE")
  resolve_conflicts_on_update = try(each.value.resolve_conflicts, "OVERWRITE")
  service_account_role_arn    = try(each.value.service_account_role_arn, null)

  timeouts {
    create = try(each.value.timeouts.create, var.eks_addons_timeouts.create, null)
    update = try(each.value.timeouts.update, var.eks_addons_timeouts.update, null)
    delete = try(each.value.timeouts.delete, var.eks_addons_timeouts.delete, null)
  }

  tags = var.tags
  depends_on = [
    aws_eks_cluster.eks_master
  ]
  # depends_on = [
  #   module.cert_manager.name,
  #   module.cert_manager.namespace,
  # ]
}

# EKS OpenID
resource "aws_iam_openid_connect_provider" "eks_openid" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.eks_master.identity[0].oidc[0].issuer
}

# EKS ASG IAM
resource "aws_iam_role" "eks_worker_role" {
  count                 = var.worker_role == "" ? 1 : 0
  name                  = "${local.resource_name}-EKSWorkerRole"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = local.resource_tags

}

data "aws_iam_role" "eks_worker_role" {
  count                 = var.worker_role == "" ? 0 : 1
  name                  = var.worker_role
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = local.worker_role_name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = local.worker_role_name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  role       = local.worker_role_name
}

resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = local.worker_role_name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = local.worker_role_name
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = local.worker_role_name
}

data "template_file" "eks_worker_policy_json" {
  template = file("${path.module}/templates/eks-worker-policy.json.tpl")

  vars = {
    application_name   = var.application_name
  }
}

resource "aws_iam_role_policy" "eks_worker_policy" {
  name = "${local.resource_name}-EKS-WorkerPolicy"
  role = local.worker_role_name

  policy = data.template_file.eks_worker_policy_json.rendered
}

resource "aws_iam_role" "cluster_autoscaler" {
  name        = "${local.resource_name}-AutoScaler-Role"
  description = "autoscaler role for ${local.resource_name}"

  force_detach_policies = true

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.eks_openid.arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${aws_iam_openid_connect_provider.eks_openid.url}:sub": "system:serviceaccount:kube-system:cluster-autoscaler-aws-cluster-autoscaler"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "cluster_autoscaler" {
  name = "${local.resource_name}-AutoScaler-Policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions",
                "ec2:DescribeInstanceTypes"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

resource "aws_kms_grant" "eks_worker_cmk_grant" {
  name              = "${local.resource_name}-EKS-Worker-Grant"
  key_id            = var.kms_cmk_arn
  grantee_principal = local.worker_role_arn
  operations        = ["Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext", "ReEncryptFrom", "ReEncryptTo", "DescribeKey"]
}

resource "aws_iam_instance_profile" "eks_worker_ec2_profile" {
  name = "${local.resource_name}-EKS-WorkerEC2Policy"
  role = local.worker_role_name
}

# EKS ASG Security Group
resource "aws_security_group" "eks_worker" {
  name        = "${local.resource_name}-EKS-WORKER"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.resource_tags
}

resource "aws_security_group_rule" "eks_worker_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker.id
  source_security_group_id = aws_security_group.eks_worker.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_worker_ingress_master_default" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker.id
  source_security_group_id = aws_security_group.eks_master.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_worker_ingress_master_https" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_worker.id
  source_security_group_id = aws_security_group.eks_master.id
  to_port                  = 443
  type                     = "ingress"
}

locals {
  aws_auth_cm = templatefile("${path.module}/templates/aws-auth-cm.yaml.tpl", { eks_worker_role_arn = local.worker_role_arn, eks_admin_arns = var.eks_admin_arns, map_roles = var.map_roles })
}

resource "null_resource" "apply_permissions" {
  triggers = {
    aws_auth = local.aws_auth_cm
  }
  
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
aws eks --region ${var.aws_region} update-kubeconfig --name ${local.resource_name}
echo $KUBECONFIG
kubectl config current-context
export KUBECONFIG=$KUBECONFIG
cat << EOF | kubectl apply -f -
${local.aws_auth_cm}
EOF
    NODES=""
    timebox=$((SECONDS+300))
    while [ $SECONDS -lt $timebox ]; do
      NODES=$(kubectl get nodes | tail -n +2 | awk '{print "nodes/"$1}')
      if [ -z "$NODES" ]; then
        sleep 15
      else
        break
      fi
    done
    kubectl wait --for=condition=Ready --timeout=300s $NODES
EOT

  }

  depends_on = [aws_autoscaling_group.eks_worker_asg, aws_autoscaling_group.eks_worker_asg_spot, aws_autoscaling_group.eks_worker_asg_dual, aws_autoscaling_group.warm_eks_worker_asg]
}
