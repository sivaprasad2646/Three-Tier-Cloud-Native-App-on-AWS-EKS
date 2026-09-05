# ============================================================
# IAM Role for EKS Control Plane
# ============================================================

resource "aws_iam_role" "eks_cluster" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}


# ============================================================
# IAM Role for EKS Worker Nodes
# ============================================================

resource "aws_iam_role" "eks_nodes" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}


# ============================================================
# EKS Worker Node Policies
# ============================================================

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


# ============================================================
# EKS Cluster OIDC
# ============================================================

data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.main.name
}

data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
}


# ============================================================
# Terraform-managed IAM OIDC Provider
# ============================================================

resource "aws_iam_openid_connect_provider" "eks" {
  url = data.aws_eks_cluster.main.identity[0].oidc[0].issuer

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    data.tls_certificate.eks.certificates[0].sha1_fingerprint
  ]

  depends_on = [
    aws_eks_cluster.main
  ]
}


# ============================================================
# External Secrets Operator - IAM Policy
# ============================================================

resource "aws_iam_policy" "eso_secrets_policy" {
  name        = "taskmanager-eso-secrets-policy"
  description = "Allows ESO to read TaskManager secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]

      Resource = "arn:aws:secretsmanager:ap-south-1:${var.aws_account_id}:secret:taskmanager/*"
    }]
  })
}


# ============================================================
# External Secrets Operator - IAM Role
# ============================================================

resource "aws_iam_role" "eso_role" {
  name = "taskmanager-eso-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "${trimprefix(aws_iam_openid_connect_provider.eks.url, "https://")}:sub" = "system:serviceaccount:external-secrets:external-secrets"

          "${trimprefix(aws_iam_openid_connect_provider.eks.url, "https://")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  depends_on = [
    aws_iam_openid_connect_provider.eks
  ]
}


# ============================================================
# Attach ESO Policy
# ============================================================

resource "aws_iam_role_policy_attachment" "eso_policy_attach" {
  role       = aws_iam_role.eso_role.name
  policy_arn = aws_iam_policy.eso_secrets_policy.arn
}


# ============================================================
# AI Assistant - Bedrock IAM Policy
# ============================================================

resource "aws_iam_policy" "ai_assistant_bedrock_policy" {
  name = "taskmanager-ai-assistant-bedrock-policy"

  description = "Allows AI assistant pod to invoke Amazon Bedrock Nova Lite"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Action = [
        "bedrock:InvokeModel"
      ]

      Resource = "arn:aws:bedrock:ap-south-1::foundation-model/amazon.nova-lite-v1:0"
    }]
  })
}


# ============================================================
# AI Assistant - IAM Role / IRSA
# ============================================================

resource "aws_iam_role" "ai_assistant_role" {
  name = "taskmanager-ai-assistant-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Federated = aws_iam_openid_connect_provider.eks.arn
      }

      Action = "sts:AssumeRoleWithWebIdentity"

      Condition = {
        StringEquals = {
          "${trimprefix(aws_iam_openid_connect_provider.eks.url, "https://")}:sub" = "system:serviceaccount:taskmanager:ai-assistant-service-account"

          "${trimprefix(aws_iam_openid_connect_provider.eks.url, "https://")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  depends_on = [
    aws_iam_openid_connect_provider.eks
  ]
}


# ============================================================
# Attach Bedrock Policy to AI Assistant Role
# ============================================================

resource "aws_iam_role_policy_attachment" "ai_assistant_bedrock_attach" {
  role       = aws_iam_role.ai_assistant_role.name
  policy_arn = aws_iam_policy.ai_assistant_bedrock_policy.arn
}