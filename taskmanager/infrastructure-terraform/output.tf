output "eks_cluster_name" {
  value = aws_eks_cluster.main.name
}

output  "eks_cluster_endpoint" {
    value = aws_eks_cluster.main.endpoint
}

output "rds_endpoint" {
    value = aws_db_instance.postgres.endpoint
}

output "rds_name" {
    value = aws_db_instance.postgres.db_name
}