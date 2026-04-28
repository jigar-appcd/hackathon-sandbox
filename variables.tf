variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "The VPC for the environment"
}

variable "application_name" {
  type        = string
  description = "The application name as per AWS on-boarding"
}

variable "resource_id" {
  type        = string
  description = "Unique resource identifier"
}

variable "eks_version" {
  type        = string
  description = "Kubernetes version"
  default     = ""
}

variable "eks_admin_arns" {
  type        = map(string)
  description = "ARN for the IAM role which needs additional admin access"
}

variable "kms_cmk_arn" {
  type        = string
  description = "ARN for the KMS key to permit for EKS"
}

variable "key_name" {
  type        = string
  description = "SSH key"
  default     = ""
}

variable "ami_id" {
  type        = string
  description = "Bakery AMI ID"
}

variable "node_groups" {
  type = map(object({
    subnets                 = list(string)
    instance_type           = string
    desired_capacity        = number
    override_instance_types = optional(list(string), [])
    max_size                = number
    min_size                = number
    node_labels             = optional(string, "")
    node_taints             = optional(string, "")
    max_pods                = number
    asg_cooldown            = optional(number, 180)
    volume_size             = optional(number, 200)
    ami_id                  = optional(string)
    windows                 = optional(bool, false)
    block_device_name       = optional(string, "/dev/xvda")
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  type        = map(string)
  description = "Tags all eks-base module resources"
  default     = {}
}

variable "cluster_endpoint_public_access" {
  type        = bool
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  default     = false
}

variable "public_access_cidrs" {
  type        = list(string)
  default     = []
  description = "List of cidr blocks that can access public endpoint"
}

variable "worker_role" {
  type        = string
  description = "Pass in existing worker role instead of creating one in automation"
  default     = ""
}

variable "spot_node_groups" {
  type = map(object({
    subnets                 = list(string)
    instance_type           = string
    desired_capacity        = number
    override_instance_types = optional(list(string), [])
    max_size                = number
    min_size                = number
    node_labels             = optional(string, "")
    node_taints             = optional(string, "")
    max_pods                = number
    asg_cooldown            = optional(number, 180)
    volume_size             = optional(number, 200)
    ami_id                  = optional(string)
    windows                 = optional(bool, false)
    block_device_name       = optional(string, "/dev/xvda")
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "dual_node_groups" {
  type = map(object({
    subnets                 = list(string)
    instance_type           = string
    desired_capacity        = number
    override_instance_types = optional(list(string), [])
    max_size                = number
    min_size                = number
    node_labels             = optional(string, "")
    node_taints             = optional(string, "")
    max_pods                = number
    asg_cooldown            = optional(number, 180)
    volume_size             = optional(number, 200)
    ami_id                  = optional(string)
    windows                 = optional(bool, false)
    block_device_name       = optional(string, "/dev/xvda")
    tags                    = optional(map(string), {})
  }))
  default = {}
}

variable "fargate_enabled" {
  type    = bool
  default = false
}

variable "enable_eks_logs" {
  type    = bool
  default = true
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = null
}

variable "lt_metadata_options" {
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "disabled")
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }
}

variable "warm_node_groups" {
  type = map(object({
    subnets          = list(string)
    instance_type    = string
    desired_capacity = number
    max_size         = number
    min_size         = number
    node_labels      = optional(string, "")
    node_taints      = optional(string, "")
    max_pods         = number
    asg_cooldown     = optional(number, 180)
    volume_size      = optional(number, 200)
    ami_id           = optional(string)
    windows          = optional(bool, false)
    warm_pool = optional(object({
      reuse_on_scale_in           = bool
      max_group_prepared_capacity = number
      min_size                    = number
      pool_state                  = string
    }))
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "authentication_mode" {
  type    = string
  default = "API_AND_CONFIG_MAP"
}

variable "bootstrap_cluster_creator_admin_permissions" {
  type    = string
  default = "true"
}

variable "service_ipv4_cidr" {
  type    = string
  default = "172.20.0.0/16"
}

variable "cloudwatch_retention" {
  type    = string
  default = "7"
}

## EKS Addons
variable "eks_addons" {
  description = "Map of EKS add-on configurations to enable for the cluster. Add-on name can be the map keys or set with `name`"
  type        = any
  default     = {}
}

variable "eks_addons_timeouts" {
  description = "Create, update, and delete timeout configurations for the EKS add-ons"
  type        = map(string)
  default     = {}
}
