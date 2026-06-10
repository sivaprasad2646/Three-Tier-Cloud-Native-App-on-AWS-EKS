variable "aws_region"{
    description = "AWS region to deploy resources in"
    type        = string
    default     = "ap-south-1"
}

variable "vpc_cidr" {
    description = "CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "project_name" {
    description = "Name of the project for tagging resources"
    type        = string
    default     = "taskmanager"
}

variable "public_subnet_cidrs" {
    description = "List of CIDR blocks for public subnets"
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    description = "List of CIDR blocks for private subnets"
    type = list(string)
    default = ["10.0.3.0/24", "10.0.4.0/24"]
}
variable "availability_zones" {
    description = "List of availability zones for subnets"
    type = list(string)
    default = ["ap-south-1a", "ap-south-1b"]
}

variable "eks_node_instance_type" {
    description = "List of EC2 instance types for EKS worker nodes"
    type = list(string)
    default = ["t3.medium"]
}

variable "eks_desired_nodes" {
    description = "Desired number of worker nodes in the EKS node group"
    type        = number
    default     = 2
}

variable "eks_max_nodes" {
    description = "Maximum number of worker nodes in the EKS node group"
    type        = number
    default     = 4
}
variable "eks_min_nodes" {
    description = "Minimum number of worker nodes in the EKS node group"
    type        = number
    default     = 1
}

variable "db_insatance_class" {
    description = "Instance class for RDS database"
    type        = string
    default     = "db.t3.micro"

}

variable "db_name" {
    description = "Name of the RDS database"
    type        = string
    default     = "taskmanagerdb"
}

variable "db_username" {
    description = "Master username for RDS database"
    type        = string
    sensitive = true
}

variable "db_password" {
    description = "Master password for RDS database"
    type        = string
    sensitive = true
}
