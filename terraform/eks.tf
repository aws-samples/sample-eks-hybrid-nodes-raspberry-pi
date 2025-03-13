module "eks_hybrid_node_role" {
  source  = "terraform-aws-modules/eks/aws//modules/hybrid-node-role"
  version = "20.33.1"

  name = var.name
}

resource "aws_ssm_activation" "this" {
  name               = var.name
  iam_role           = module.eks_hybrid_node_role.name
  registration_limit = 10
  expiration_date    = timeadd(timestamp(), "720h")
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.33.1"

  cluster_name                   = var.name
  cluster_version                = var.eks_cluster_version
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = false

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_cluster_creator_admin_permissions = true
  access_entries = {
    admin = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Admin"
      policy_associations = {
        AmazonEKSClusterAdminPolicy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    hybrid = {
      principal_arn = module.eks_hybrid_node_role.arn
      type          = "HYBRID_LINUX"
    }
  }

  cluster_remote_network_config = {
    remote_node_networks = { cidrs = [var.remote_node_cidr] }
    remote_pod_networks  = { cidrs = [var.remote_pod_cidr] }
  }

  create_node_security_group = false
  cluster_security_group_additional_rules = {
    hybrid = {
      cidr_blocks = [var.vpc_cidr, var.remote_node_cidr, var.remote_pod_cidr]
      description = "Allow all traffic from vpc and remote node/pod networks"
      from_port   = 0
      to_port     = 0
      protocol    = "all"
      type        = "ingress"
    }
  }
}
