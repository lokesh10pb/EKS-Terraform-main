variable "project_name" {
  description = "Prefix for AWS resource names"
  type        = string
  default     = "my-project"
}

variable "ec2_instance_type" {
  description = "Instance type for the three standalone Ubuntu servers (use x86_64 types with this AMI)"
  type        = string
  default     = "t3.medium"
}

variable "ssh_allowed_cidr" {
  description = "Your public IPv4 address with /32, allowed to SSH to the standalone servers"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr)) && can(regex("/32$", var.ssh_allowed_cidr))
    error_message = "Set ssh_allowed_cidr to your public IPv4 address followed by /32."
  }
}

variable "eks_instance_types" {
  description = "Instance types for EKS workers (use x86_64 types with AL2023_x86_64_STANDARD)"
  type        = list(string)
  default     = ["t3.medium"]

  validation {
    condition     = length(var.eks_instance_types) > 0
    error_message = "Provide at least one EKS instance type."
  }
}

variable "eks_capacity_type" {
  description = "EKS worker purchasing option; ON_DEMAND is the project default"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.eks_capacity_type)
    error_message = "Use ON_DEMAND or SPOT."
  }
}

variable "eks_node_count" {
  description = "Fixed number of managed EKS workers; this does not configure workload autoscaling"
  type        = number
  default     = 3

  validation {
    condition     = var.eks_node_count >= 1 && floor(var.eks_node_count) == var.eks_node_count
    error_message = "eks_node_count must be a positive whole number."
  }
}
