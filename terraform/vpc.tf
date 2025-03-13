locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 2, k)]
  public_subnets = [for k, v in local.azs : cidrsubnet(var.vpc_cidr, 3, k + 4)]
  
  enable_nat_gateway = true
  single_nat_gateway = true
}
