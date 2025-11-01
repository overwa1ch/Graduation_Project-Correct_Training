variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "lifecycle_days" {
  description = "Number of days before S3 objects expire"
  type        = number
  default     = 30
}

