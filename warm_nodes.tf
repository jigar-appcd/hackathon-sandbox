data "template_file" "warm_eks_worker_userdata" {
  for_each = var.warm_node_groups

  template = lookup(each.value, "windows", false) == true ? file("${path.module}/templates/eks-worker-userdata-windows.sh.tpl") : file("${path.module}/templates/eks-worker-userdata-warm.sh.tpl")

  vars = {
    resource_name   = local.resource_name
    aws_region      = var.aws_region
    master_endpoint = aws_eks_cluster.eks_master.endpoint
    cluster_ca      = aws_eks_cluster.eks_master.certificate_authority[0].data
    node_group      = each.key
    node_labels     = lookup(each.value, "node_labels", "")
    node_taints     = lookup(each.value, "node_taints", "")
    max_pods        = lookup(each.value, "max_pods", "")
    dns_cluster_ip  = "${trimsuffix(split("/", var.service_ipv4_cidr)[0],".0")}.10"
    cluster_cidr       = data.aws_vpc.eks_vpc.cidr_block
  }
}

# EKS ASG
resource "aws_launch_template" "warm_eks_worker_template" {
  for_each = var.warm_node_groups

  name_prefix            = "${local.resource_name}-${upper(each.key)}"
  image_id               = lookup(each.value, "ami_id", var.ami_id)
  instance_type          = lookup(each.value, "instance_type", "")
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.eks_worker.id]
  user_data              = base64encode(data.template_file.warm_eks_worker_userdata[each.key].rendered)

  monitoring {
    enabled = true
  }

  metadata_options {
    http_endpoint               = var.lt_metadata_options.http_endpoint
    http_tokens                 = var.lt_metadata_options.http_tokens
    http_put_response_hop_limit = var.lt_metadata_options.http_put_response_hop_limit
    instance_metadata_tags      = var.lt_metadata_options.instance_metadata_tags
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      volume_size           = lookup(each.value, "volume_size", 200)
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

resource "random_shuffle" "warm_az" {
  for_each = var.warm_node_groups

  input        = data.aws_subnets.eks_subnets.ids
  result_count = 1
}

resource "aws_autoscaling_group" "warm_eks_worker_asg" {
  for_each = var.warm_node_groups

  desired_capacity      = lookup(each.value, "desired_capacity", "")
  max_size              = lookup(each.value, "max_size", "")
  min_size              = lookup(each.value, "min_size", "")
  name                  = "${local.resource_name}-${upper(each.key)}"
  vpc_zone_identifier   = length(lookup(each.value, "subnets", [])) > 0 ? lookup(each.value, "subnets", []) : random_shuffle.warm_az[each.key].result
  protect_from_scale_in = true
  force_delete          = true
  suspended_processes   = ["AZRebalance"]
  enabled_metrics       = ["GroupDesiredCapacity"]
  default_cooldown      = lookup(each.value, "asg_cooldown", 180)

  launch_template {
    id      = aws_launch_template.warm_eks_worker_template[each.key].id
    version = "$Latest"
  }

  initial_lifecycle_hook {
    name                 = "finish_user_data"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  dynamic "warm_pool" {
    for_each = lookup(each.value, "warm_pool", null) != null ? [each.value.warm_pool] : []
    content {
      instance_reuse_policy {
        reuse_on_scale_in = warm_pool.value.reuse_on_scale_in
      }
      max_group_prepared_capacity = warm_pool.value.max_group_prepared_capacity 
      min_size = warm_pool.value.min_size
      pool_state = warm_pool.value.pool_state
    }
  }

  tag {
    key = "Name"
    value = "${local.resource_name}-${upper(each.key)}"
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
    for_each = lookup(each.value, "node_labels", "") != "" ? split(",", lookup(each.value, "node_labels", "")) : []
    content {
      key                 = "k8s.io/cluster-autoscaler/node-template/label/${split("=", tag.value)[0]}"
      value               = split("=", tag.value)[1]
      propagate_at_launch = true
    }
  }

  dynamic "tag" {
    for_each = lookup(each.value, "node_taints", "") != "" ? split(",", lookup(each.value, "node_taints", "")) : []
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