# EC2 --> Get most recent Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Create security group for VPN Server
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"

  name   = var.name
  vpc_id = module.vpc.vpc_id

  ingress_with_cidr_blocks = [
    # Allow port 51820, for Wireguard from anywhere
    {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = "0.0.0.0/0"
    }, 
    # Allow all access from VPC, Hybrid Node Network, Hybrid Pod Network, and K8s Service Network
    {
    rule        = "all-all"
    cidr_blocks = "${var.vpc_cidr},${var.remote_node_cidr},${var.remote_pod_cidr},172.16.0.0/16"
  }]

  # Allow all traffic from self
  ingress_with_self = [{ rule = "all-all" }]


  # Allow all outbound
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]
}

# Create VPN Server
module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.7.1"

  name = "${var.name}-vpn-server"

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  create_iam_instance_profile = true
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # Disabled source destination checking --> needed for VPN/routing
  source_dest_check = false

  # Install and start SSM Agent
  user_data = <<-EOT
    #!/bin/bash
    snap install amazon-ssm-agent --classic
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  EOT
}


# Create routing table entries to Hybrid Node & Pod Network from Private & Public Subnets
resource "aws_route" "private_route_table_node" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = var.remote_node_cidr
  network_interface_id   = module.ec2_instance.primary_network_interface_id
}

resource "aws_route" "public_route_table_node" {
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = var.remote_node_cidr
  network_interface_id   = module.ec2_instance.primary_network_interface_id
}

resource "aws_route" "private_route_table_pod" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = var.remote_pod_cidr
  network_interface_id   = module.ec2_instance.primary_network_interface_id
}

resource "aws_route" "remote_pod_cidr_pod" {
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = var.remote_pod_cidr
  network_interface_id   = module.ec2_instance.primary_network_interface_id
}

# Add route for Kubernetes service CIDR
resource "aws_route" "k8s_service_cidr" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "172.16.0.0/16"
  network_interface_id   = module.ec2_instance.primary_network_interface_id
}

resource "aws_route" "k8s_service_cidr_public" {
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = "172.16.0.0/16"
  network_interface_id   = module.ec2_instance.primary_network_interface_id
}
