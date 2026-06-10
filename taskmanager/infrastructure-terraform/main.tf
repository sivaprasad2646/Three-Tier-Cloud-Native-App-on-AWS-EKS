terraform{
    required_version = ">= 1.6.0"
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
     # ── Remote state in S3 (CRITICAL — never use local state in real projects)
  # Create this bucket manually once before running terraform init

    backend "s3" {
        bucket = "taskmanager-tfstate-942088612648"
        key    = "infrastructure/terraform.tfstate"
        region = "ap-south-1"
        encrypt = true
        dynamodb_table = "taskmanager-tfstate-lock"
  }
}

provider "aws" {
    region = var.aws_region
}
