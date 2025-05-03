variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "demo-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for the subnets"
  type        = map(string)
  default     = {
    "a" = "10.0.1.0/24"
    "b" = "10.0.2.0/24"
  }
}

variable "availability_zones" {
  description = "Availability zones for the subnets"
  type        = map(string)
  default     = {
    "a" = "us-east-1a"
    "b" = "us-east-1b"
  }
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "demo-node-group"
}

variable "node_instance_types" {
  description = "EC2 instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {
    Environment = "demo"
    ManagedBy   = "terraform"
  }
}