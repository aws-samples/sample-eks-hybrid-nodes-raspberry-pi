#---------------------------------------------------------------
# Ultrasonic Demo Resources
# IAM Role and Pod Identity Association for DynamoDB access
#---------------------------------------------------------------

#---------------------------------------------------------------
# IAM Role for Ultrasonic Demo Pods
#---------------------------------------------------------------
resource "aws_iam_role" "ultrasonic_demo_role" {
  name = "${module.eks.cluster_name}-ultrasonic-demo-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })

  tags = {
    Name        = "EKS Ultrasonic Demo Role"
    Environment = "demo"
    Project     = "eks-hybrid-nodes"
  }
}

#---------------------------------------------------------------
# IAM Policy for DynamoDB Access
#---------------------------------------------------------------
resource "aws_iam_role_policy" "ultrasonic_demo_dynamodb" {
  name = "ultrasonic-demo-dynamodb-policy"
  role = aws_iam_role.ultrasonic_demo_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:DescribeTable",
          "dynamodb:BatchGetItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.region}:${local.account_id}:table/eks-timeseries",
          "arn:aws:dynamodb:${var.region}:${local.account_id}:table/eks-timeseries/*"
        ]
      }
    ]
  })
}

#---------------------------------------------------------------
# Pod Identity Association
#---------------------------------------------------------------
resource "aws_eks_pod_identity_association" "ultrasonic_demo" {
  cluster_name    = module.eks.cluster_name
  namespace       = "default"
  service_account = "eks-dynamo-writer-sa"
  role_arn        = aws_iam_role.ultrasonic_demo_role.arn

  tags = {
    Name        = "EKS Ultrasonic Demo Pod Identity"
    Environment = "demo"
    Project     = "eks-hybrid-nodes"
  }
}
