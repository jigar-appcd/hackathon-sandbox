#https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html

resource "aws_iam_role" "fargate" {
  count = var.fargate_enabled ? 1 : 0
  name = "${local.resource_name}-fargate"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks-fargate-pods.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
  ]
}
EOF

}

#https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonEKSFargatePodExecutionRolePolicy.html
resource "aws_iam_role_policy_attachment" "lambda" {
  count = var.fargate_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role = aws_iam_role.fargate[0].id
}

data "aws_security_group" "eks_security_group" {
  count = var.fargate_enabled ? 1 : 0
  tags = {
    "aws:eks:cluster-name" = local.resource_name
  }
}

resource "aws_security_group_rule" "eks_worker_ingress_fargate" {
  count = var.fargate_enabled ? 1 : 0
  description              = "Allow worker Kubelets access from fargate"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_worker.id
  source_security_group_id = data.aws_security_group.eks_security_group[0].id
  to_port                  = 0
  type                     = "ingress"
}

resource "aws_eks_fargate_profile" "example" {
  count = var.fargate_enabled ? 1 : 0
  cluster_name           = aws_eks_cluster.eks_master.name
  fargate_profile_name   = "fargate"
  pod_execution_role_arn = aws_iam_role.fargate[0].arn
  subnet_ids             = data.aws_subnets.eks_subnets.ids

  selector {
    namespace = "*"
    labels = {
      fargate-profile = "fargate"
    }
  }
}
