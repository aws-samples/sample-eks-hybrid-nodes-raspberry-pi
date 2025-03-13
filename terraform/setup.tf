resource "local_file" "setup_vpn" {
  content = templatefile("${path.module}/templates/SETUP_VPN.md.tpl", {
    remote_node_cidr = var.remote_node_cidr
    remote_pod_cidr  = var.remote_pod_cidr
  })
  filename = "${path.module}/SETUP_VPN.md"
}

resource "local_file" "setup_node" {
  content = templatefile("${path.module}/templates/SETUP_NODE.md.tpl", {
    cluster_name    = module.eks.cluster_name
    region          = var.region
    activation_code = aws_ssm_activation.this.activation_code
    activation_id   = aws_ssm_activation.this.id
    version = var.eks_cluster_version
  })
  filename = "${path.module}/SETUP_NODE.md"
}

resource "local_file" "setup_cilium" {
  content = templatefile("${path.module}/templates/cilium-values.yaml.tpl", {
    remote_pod_cidr  = var.remote_pod_cidr
    k8s_service_host = trimprefix(module.eks.cluster_endpoint, "https://")
  })
  filename = "${path.module}/cilium-values.yaml"
}
