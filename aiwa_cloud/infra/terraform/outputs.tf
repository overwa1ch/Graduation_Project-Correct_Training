output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3.bucket_arn
}

output "reinfer_queue_url" {
  description = "URL of the REINFER queue"
  value       = module.sqs.reinfer_queue_url
}

output "reinfer_queue_arn" {
  description = "ARN of the REINFER queue"
  value       = module.sqs.reinfer_queue_arn
}

output "advice_queue_url" {
  description = "URL of the ADVICE queue"
  value       = module.sqs.advice_queue_url
}

output "advice_queue_arn" {
  description = "ARN of the ADVICE queue"
  value       = module.sqs.advice_queue_arn
}

output "reinfer_dlq_url" {
  description = "URL of the REINFER Dead-Letter Queue"
  value       = module.sqs.reinfer_dlq_url
}

output "advice_dlq_url" {
  description = "URL of the ADVICE Dead-Letter Queue"
  value       = module.sqs.advice_dlq_url
}

