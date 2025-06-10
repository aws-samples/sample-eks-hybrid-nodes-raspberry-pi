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
  default     = "10.129.0.0/16"
}

variable "eks_cluster_version" {
  description = "CIDR block for VPC"
  type    = string
  default = "1.32"
}

variable "remote_node_cidr" {
  description = "CIDR for on-prem hybrid nodes"
  type    = string
  default = "172.16.0.0/20"
}

variable "remote_pod_cidr" {
  description = "CIDR for on-prem hybrid pods"
  type    = string
  default = "10.130.0.0/17"
}

variable "cluster_service_ipv4_cidr" {
  description = "CIDR for EKS Service"
  type    = string
  default = "10.128.0.0/16"
}