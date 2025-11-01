terraform {
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
}

variable "reinfer_visibility_timeout" {
  description = "Visibility timeout for REINFER queue in seconds"
  type        = number
  default     = 2700 # 45 minutes
}

variable "advice_visibility_timeout" {
  description = "Visibility timeout for ADVICE queue in seconds"
  type        = number
  default     = 600 # 10 minutes
}

variable "max_receive_count" {
  description = "Maximum number of receives before moving to DLQ"
  type        = number
  default     = 3
}

# Dead-letter queues
resource "aws_sqs_queue" "reinfer_dlq" {
  name                       = "aiwa-reinfer-dlq-${var.environment}"
  message_retention_seconds  = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB

  tags = {
    Environment = var.environment
    Purpose     = "REINFER Dead-Letter Queue"
  }
}

resource "aws_sqs_queue" "advice_dlq" {
  name                       = "aiwa-advice-dlq-${var.environment}"
  message_retention_seconds  = 1209600 # 14 days
  max_message_size          = 262144  # 256 KB

  tags = {
    Environment = var.environment
    Purpose     = "ADVICE Dead-Letter Queue"
  }
}

# REINFER Queue
resource "aws_sqs_queue" "reinfer" {
  name                       = "aiwa-reinfer-queue-${var.environment}"
  visibility_timeout_seconds = var.reinfer_visibility_timeout
  message_retention_seconds  = 1209600 # 14 days
  delivery_delay_seconds     = 0
  max_message_size          = 262144  # 256 KB
  receive_wait_time_seconds = 20      # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.reinfer_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Environment = var.environment
    Purpose     = "REINFER Processing Queue"
  }
}

# ADVICE Queue
resource "aws_sqs_queue" "advice" {
  name                       = "aiwa-advice-queue-${var.environment}"
  visibility_timeout_seconds = var.advice_visibility_timeout
  message_retention_seconds  = 1209600 # 14 days
  delivery_delay_seconds     = 0
  max_message_size          = 262144  # 256 KB
  receive_wait_time_seconds = 20      # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.advice_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Environment = var.environment
    Purpose     = "ADVICE Processing Queue"
  }
}

output "reinfer_queue_url" {
  description = "URL of the REINFER queue"
  value       = aws_sqs_queue.reinfer.url
}

output "reinfer_queue_arn" {
  description = "ARN of the REINFER queue"
  value       = aws_sqs_queue.reinfer.arn
}

output "advice_queue_url" {
  description = "URL of the ADVICE queue"
  value       = aws_sqs_queue.advice.url
}

output "advice_queue_arn" {
  description = "ARN of the ADVICE queue"
  value       = aws_sqs_queue.advice.arn
}

output "reinfer_dlq_url" {
  description = "URL of the REINFER DLQ"
  value       = aws_sqs_queue.reinfer_dlq.url
}

output "advice_dlq_url" {
  description = "URL of the ADVICE DLQ"
  value       = aws_sqs_queue.advice_dlq.url
}

