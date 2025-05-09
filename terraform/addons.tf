#---------------------------------------------------------------
# EKS Blueprints Addons
#---------------------------------------------------------------
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.2"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  #---------------------------------------
  # Amazon EKS Managed Add-ons
  #---------------------------------------
  eks_addons = {
    coredns = {
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    eks-pod-identity-agent = {}
    # VPC CNI uses worker node IAM role policies and should only run on cloud nodes
    vpc-cni = {
      configuration_values = jsonencode({
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [{
                matchExpressions = [{
                  key = "topology.kubernetes.io/region"
                  operator = "In"
                  values = [var.region]
                }]
              }]
            }
          }
        }
      })
    }
  }
  
  #---------------------------------------
  # AWS Load Balancer Controller Add-on
  #---------------------------------------
  enable_aws_load_balancer_controller = true
  # turn off the mutating webhook for services because we are using
  # service.beta.kubernetes.io/aws-load-balancer-type: external
  aws_load_balancer_controller = {
    set = [
      {
        name  = "enableServiceMutatorWebhook"
        value = "false"
      },
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      },
      {
        name  = "tolerations[0].key"
        value = "karpenter.sh/controller"
      },
      {
        name  = "tolerations[0].operator"
        value = "Exists"
      },
      {
        name  = "tolerations[0].effect"
        value = "NoSchedule"
      }
    ]
  }
}
