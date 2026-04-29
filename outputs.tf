
output "aws_region" {
  value = var.aws_region
}

output "cluster_name" {
  value = local.resource_name
}

output "application_name" {
  value = var.application_name
}

output "openid_arn" {
  value     = aws_iam_openid_connect_provider.eks_openid.arn
  sensitive = true
}

output "kms_cmk_arn" {
  value     = var.kms_cmk_arn
  sensitive = true
}

output "oidc_url" {
  value = replace(aws_eks_cluster.eks_master.identity[0].oidc[0].issuer, "https://", "")
}

output "eks_worker_role" {
  value     = var.worker_role == "" ? aws_iam_role.eks_worker_role[0].arn : data.aws_iam_role.eks_worker_role[0].arn
  sensitive = true
}

output "cluster_autoscaler_role" {
  value     = aws_iam_role.cluster_autoscaler.arn
  sensitive = true
}

output "subnet_id" {
  value = data.aws_subnets.eks_subnets.ids
}

output "security_group" {
  value = aws_security_group.eks_master.id
}

output "worker_security_group" {
  value = aws_security_group.eks_worker.id
}

output "eks_vpc_cidr_block" {
  value = data.aws_vpc.eks_vpc.cidr_block
}


output "trust_relationship" {
  value = <<JSON
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
            "${replace(aws_eks_cluster.eks_master.identity[0].oidc[0].issuer, "https://", "")}:sub": "system:serviceaccount:<NAMESPACE>:<SERVICE_ACCOUNT_NAME>"
          }
        }
      }
    ]
}
JSON
}
