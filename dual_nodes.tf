data "template_file" "eks_worker_userdata_dual" {
  for_each = var.dual_node_groups
  template = each.value.windows == true ? file("${path.module}/templates/eks-worker-userdata-windows.sh.tpl") : file("${path.module}/templates/eks-worker-userdata.yml.tpl")
  vars = {
    resource_name   = local.resource_name
    aws_region      = var.aws_region
    master_endpoint = aws_eks_cluster.eks_master.endpoint
    cluster_ca      = aws_eks_cluster.eks_master.certificate_authority[0].data
    node_group      = each.key
    node_labels     = each.value.node_labels
    node_taints     = each.value.node_taints
    max_pods        = each.value.max_pods
    dns_cluster_ip  = "${trimsuffix(split("/", var.service_ipv4_cidr)[0],".0")}.10"
    cluster_cidr       = data.aws_vpc.eks_vpc.cidr_block
  }
}

# EKS ASG
resource "aws_launch_template" "eks_worker_template_x86" {
  for_each = var.dual_node_groups

  name_prefix            = "${local.resource_name}-${upper(each.key)}"
  image_id               = each.value["x86_ami_id"]
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.eks_worker.id]
  user_data              = base64encode(data.template_file.eks_worker_userdata_dual[each.key].rendered)

  metadata_options {
    http_endpoint               = var.lt_metadata_options.http_endpoint
    http_tokens                 = var.lt_metadata_options.http_tokens
    http_put_response_hop_limit = var.lt_metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.lt_metadata_options.instance_metadata_tags
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = each.value.volume_size
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags          = merge(local.resource_tags, lookup(each.value, "tags", {}))
  }

  tag_specifications {
    resource_type = "volume"

    tags          = merge(local.resource_tags, lookup(each.value, "tags", {}))
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_worker_ec2_profile.name
  }

  tags          = merge(local.resource_tags, lookup(each.value, "tags", {}))  
}

resource "aws_launch_template" "eks_worker_template_arm" {
  for_each = var.dual_node_groups

  name_prefix            = "${local.resource_name}-${upper(each.key)}"
  image_id               = each.value.arm_ami_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.eks_worker.id]
  user_data              = base64encode(data.template_file.eks_worker_userdata_dual[each.key].rendered)

  metadata_options {
    http_endpoint               = var.lt_metadata_options.http_endpoint
    http_tokens                 = var.lt_metadata_options.http_tokens
    http_put_response_hop_limit = var.lt_metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.lt_metadata_options.instance_metadata_tags
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = each.value.volume_size
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = local.resource_tags
  }

  tag_specifications {
    resource_type = "volume"

    tags = local.resource_tags
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.eks_worker_ec2_profile.name
  }

  tags = local.resource_tags
}

resource "random_shuffle" "az_dual" {
  for_each = var.dual_node_groups
  input        = data.aws_subnets.eks_subnets.ids
  result_count = 1
}

resource "aws_autoscaling_group" "eks_worker_asg_dual" {
  for_each = var.dual_node_groups

  desired_capacity      = each.value.desired_capacity
  max_size              = each.value.max_size
  min_size              = each.value.min_size
  name                  = "${local.resource_name}-${upper(each.key)}"
  vpc_zone_identifier   = length(each.value.subnets) > 0 ? each.value.subnets : random_shuffle.az_dual[each.key].result
  protect_from_scale_in = true
  force_delete          = true
  suspended_processes   = ["AZRebalance"]
  enabled_metrics       = ["GroupDesiredCapacity"]
  default_cooldown      = each.value.asg_cooldown

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = endswith(split(".", each.value.instance_type)[0], "g") ? aws_launch_template.eks_worker_template_arm[each.key].id : aws_launch_template.eks_worker_template_x86[each.key].id
        version            = "$Latest"
      }
      dynamic "override" {
        for_each = [each.value.instance_type]
        content {
          instance_type = override.value
        }
      }
      dynamic "override" {
        for_each = each.value.override_instance_types
        content {
          instance_type = override.value
        }
      }
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.resource_name}-${upper(each.key)}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${local.resource_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${local.resource_name}"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = each.value.node_labels != "" ? split(",", each.value.node_labels) : []
    content {
      key                 = "k8s.io/cluster-autoscaler/node-template/label/${split("=", tag.value)[0]}"
      value               = split("=", tag.value)[1]
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = each.value.node_taints != "" ? split(",", each.value.node_taints) : []
    content {
      key                 = "k8s.io/cluster-autoscaler/node-template/taint/${split("=", tag.value)[0]}"
      value               = split("=", tag.value)[1]
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, lookup(each.value, "tags", {}))
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
  depends_on = [aws_eks_cluster.eks_master]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, target_group_arns]
  }
}
