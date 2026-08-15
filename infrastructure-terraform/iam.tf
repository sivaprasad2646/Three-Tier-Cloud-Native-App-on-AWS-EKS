# IAM Role for EKS Control Plane to manage worker nodes

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Role for EKS Worker Nodes to allow them to join the cluster and access AWS resources
resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Nodes need these 3 policies to function

resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}
# ── IAM Policy — allows reading taskmanager secrets only
resource "aws_iam_policy" "eso_secrets_policy" {
  name        = "taskmanager-eso-secrets-policy"
  description = "Allows ESO to read TaskManager secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        # Restrict to ONLY taskmanager secrets — not all secrets in account
        Resource = "arn:aws:secretsmanager:ap-south-1:${var.aws_account_id}:secret:taskmanager/*"
      }
    ]
  })
}

# ── IAM Role for ESO — uses IRSA (IAM Roles for Service Accounts)
# IRSA = pods get AWS permissions via IAM role, NO access keys needed
resource "aws_iam_role" "eso_role" {
  name = "taskmanager-eso-role"

  # Trust policy — only the ESO service account can assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/${local.oidc_provider}"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_provider}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          "${local.oidc_provider}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eso_policy_attach" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_secrets_policy.arn
}

# ── Local value — extract OIDC provider URL from EKS cluster
locals {
  oidc_provider = replace(
    data.aws_eks_cluster.main.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
}

data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.main.name
}