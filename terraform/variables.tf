variable "name" {
  description = "VPC, EKS Cluster name."
  type        = string
  default     = "hybrid-nodes-demo-pi"
}

variable "region" {
  description = "region"
  default     = "ap-southeast-1"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/24"
}

variable "eks_cluster_version" {
  description = "CIDR block for VPC"
  type    = string
  default = "1.32"
}

variable "remote_node_cidr" {
  description = "CIDR for on-prem hybrid nodes"
  type    = string
  default = "192.168.3.0/24"
}

variable "remote_pod_cidr" {
  description = "CIDR for on-prem hybrid pods"
  type    = string
  default = "192.168.5.0/24"
}
