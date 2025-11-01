terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "lifecycle_days" {
  description = "Number of days before S3 objects expire"
  type        = number
  default     = 30
}

provider "aws" {
  region = var.aws_region
}

# S3 Bucket
module "s3" {
  source = "./modules/s3"

  bucket_name    = "aiwa-cloud-storage-${var.environment}"
  environment    = var.environment
  lifecycle_days = var.lifecycle_days
}

# SQS Queues
module "sqs" {
  source = "./modules/sqs"

  environment               = var.environment
  reinfer_visibility_timeout = 2700 # 45 minutes
  advice_visibility_timeout  = 600  # 10 minutes
  max_receive_count         = 3
}

