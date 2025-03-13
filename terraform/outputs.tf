output "eks_update_kubeconfig" {
  value = "aws --region ${var.region} eks update-kubeconfig --name ${module.eks.cluster_name} --role-arn arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Admin"
}

output "connect_vpn_server" {
  description = "Command to connect to VPN Server using SSM"
  value       = "aws ssm start-session --target ${module.ec2_instance.id} --region ${var.region}"
}

output "vpn_server_public_ip" {
  description = "Public IP address of the VPN server"
  value       = module.ec2_instance.public_ip
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint without https://"
  value = trimprefix(module.eks.cluster_endpoint, "https://")
}
