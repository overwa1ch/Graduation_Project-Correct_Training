# Terraform Infrastructure as Code

This directory contains Terraform configurations for provisioning AWS resources for the AIWA Cloud Platform.

## Resources Created

- **S3 Bucket**: `aiwa-cloud-storage-{env}`
  - Server-side encryption (SSE-S3)
  - Lifecycle policy (30-day expiration)
  - CORS configuration for presigned URLs
  - Public access blocked

- **SQS Queues**:
  - `aiwa-reinfer-queue-{env}` (45 min visibility timeout)
  - `aiwa-advice-queue-{env}` (10 min visibility timeout)
  - `aiwa-reinfer-dlq-{env}` (Dead-letter queue)
  - `aiwa-advice-dlq-{env}` (Dead-letter queue)

## Prerequisites

1. AWS CLI installed and configured
2. Terraform >= 1.0 installed
3. Appropriate AWS IAM permissions

## Usage

### 1. Initialize Terraform

```bash
cd aiwa_cloud/infra/terraform
terraform init
```

### 2. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
environment   = "dev"
aws_region    = "us-east-1"
lifecycle_days = 30
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Apply Configuration

```bash
terraform apply
```

When prompted, type `yes` to confirm.

### 5. View Outputs

After successful deployment, view the created resource identifiers:

```bash
terraform output
```

You'll see:
- S3 bucket name
- SQS queue URLs (for REINFER and ADVICE)
- Queue ARNs

### 6. Use Outputs in Environment Variables

Copy the output values to your `.env` files:

```bash
# For core-api/.env
AWS_S3_BUCKET=$(terraform output -raw s3_bucket_name)
AWS_SQS_REINFER_QUEUE_URL=$(terraform output -raw reinfer_queue_url)
AWS_SQS_ADVICE_QUEUE_URL=$(terraform output -raw advice_queue_url)
```

## Module Structure

```
terraform/
├── main.tf                 # Main configuration
├── variables.tf            # Variable definitions
├── outputs.tf              # Output definitions
├── terraform.tfvars.example # Example variables
└── modules/
    ├── s3/
    │   └── main.tf         # S3 bucket module
    └── sqs/
        └── main.tf         # SQS queues module
```

## Destroy Resources

To tear down all created resources:

```bash
terraform destroy
```

⚠️ **Warning**: This will delete all resources including data in S3 buckets and messages in queues.

## Environment-Specific Deployments

To deploy to different environments:

```bash
# Development
terraform apply -var="environment=dev"

# Production
terraform apply -var="environment=prod"
```

Or use workspace management:

```bash
terraform workspace new dev
terraform workspace new prod
terraform workspace select dev
terraform apply
```

## Troubleshooting

### Error: Bucket name already exists
S3 bucket names are globally unique. Try a different name or append a unique suffix.

### Error: Insufficient permissions
Ensure your AWS credentials have permissions for:
- S3: CreateBucket, PutBucketPolicy, PutBucketLifecycleConfiguration, PutBucketCorsConfiguration
- SQS: CreateQueue, GetQueueAttributes, SetQueueAttributes

### Error: Module not found
Run `terraform init` to download module dependencies.

## Next Steps

After creating these resources:

1. Configure IAM roles (see `../manuals/AWS_SETUP.md` section 4)
2. Set up RDS instance (see `../manuals/AWS_SETUP.md` section 3)
3. Create ECS cluster and task definitions (see `../manuals/AWS_SETUP.md` section 5)
4. Configure environment variables in your applications

