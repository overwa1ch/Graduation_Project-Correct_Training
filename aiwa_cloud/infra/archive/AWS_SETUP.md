# AWS Manual Setup Guide

This guide provides step-by-step instructions for manually setting up AWS resources for the AIWA Cloud Platform.

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Basic understanding of AWS services

## Table of Contents

1. [S3 Bucket Setup](#1-s3-bucket-setup)
2. [SQS Queues Setup](#2-sqs-queues-setup)
3. [RDS PostgreSQL Setup](#3-rds-postgresql-setup)
4. [IAM Roles and Policies](#4-iam-roles-and-policies)
5. [ECS Cluster Setup](#5-ecs-cluster-setup)
6. [Environment Variables](#6-environment-variables)

---

## 1. S3 Bucket Setup

### Create S3 Bucket

1. Go to AWS Console → S3
2. Click "Create bucket"
3. **Bucket name**: `aiwa-cloud-storage-{env}` (e.g., `aiwa-cloud-storage-prod`)
4. **Region**: `us-east-1` (or your preferred region)
5. **Block Public Access**: Keep all blocks enabled (default)
6. **Bucket Versioning**: Disabled (optional: enable for audit trail)
7. **Server-side encryption**: Enable with SSE-S3 (or SSE-KMS for audit)
8. Click "Create bucket"

### Configure Lifecycle Policy

1. Select your bucket → Management → Lifecycle rules
2. Click "Create lifecycle rule"
3. **Rule name**: `delete-old-sessions`
4. **Rule scope**: Apply to all objects
5. **Lifecycle rule actions**:
   - ✅ Expire current versions of objects
   - Days after object creation: **30**
6. Click "Create rule"

### Configure CORS (if needed for presigned URLs)

1. Select your bucket → Permissions → CORS
2. Add the following configuration:

```json
[
  {
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3000
  }
]
```

---

## 2. SQS Queues Setup

### Create REINFER Queue

1. Go to AWS Console → SQS
2. Click "Create queue"
3. **Type**: Standard
4. **Name**: `aiwa-reinfer-queue-{env}`
5. **Configuration**:
   - Visibility timeout: **2700 seconds** (45 minutes)
   - Message retention period: **1209600 seconds** (14 days)
   - Delivery delay: **0 seconds**
   - Maximum message size: **256 KB**
   - Receive message wait time: **20 seconds** (long polling)
6. **Dead-letter queue**:
   - ✅ Enable
   - Choose existing queue or create new: `aiwa-reinfer-dlq-{env}`
   - Maximum receives: **3**
7. Click "Create queue"

### Create ADVICE Queue

1. Repeat steps above with:
   - **Name**: `aiwa-advice-queue-{env}`
   - **Visibility timeout**: **600 seconds** (10 minutes)
   - **Dead-letter queue**: `aiwa-advice-dlq-{env}`

### Create Dead-Letter Queues

1. Create `aiwa-reinfer-dlq-{env}` (Standard queue, default settings)
2. Create `aiwa-advice-dlq-{env}` (Standard queue, default settings)

### Note Queue URLs

Copy the queue URLs from the Details tab:
- REINFER Queue URL: `https://sqs.us-east-1.amazonaws.com/{account-id}/aiwa-reinfer-queue-{env}`
- ADVICE Queue URL: `https://sqs.us-east-1.amazonaws.com/{account-id}/aiwa-advice-queue-{env}`

---

## 3. RDS PostgreSQL Setup

### Create RDS Instance

1. Go to AWS Console → RDS
2. Click "Create database"
3. **Engine options**:
   - Engine type: PostgreSQL
   - Version: PostgreSQL 15.x
4. **Templates**: Dev/Test (or Production for prod environment)
5. **Settings**:
   - DB instance identifier: `aiwa-cloud-db-{env}`
   - Master username: `aiwa_admin`
   - Master password: (generate secure password)
6. **Instance configuration**:
   - DB instance class: `db.t3.micro` (dev) or `db.t3.small` (prod)
7. **Storage**:
   - Storage type: General Purpose SSD (gp3)
   - Allocated storage: **20 GB**
   - ✅ Enable storage autoscaling (max: 100 GB)
8. **Connectivity**:
   - VPC: Default or custom VPC
   - Public access: **No** (access via ECS only)
   - VPC security group: Create new or use existing
9. **Database authentication**: Password authentication
10. **Additional configuration**:
    - Initial database name: `aiwa_cloud`
    - Backup retention period: **7 days**
    - ✅ Enable automated backups
11. Click "Create database"

### Configure Security Group

1. Go to EC2 → Security Groups
2. Find the RDS security group
3. Edit inbound rules:
   - Type: PostgreSQL
   - Protocol: TCP
   - Port: 5432
   - Source: ECS security group (or VPC CIDR)

### Note Connection Details

- Endpoint: `aiwa-cloud-db-{env}.xxxxxx.us-east-1.rds.amazonaws.com`
- Port: `5432`
- Database: `aiwa_cloud`
- Username: `aiwa_admin`
- Password: (from step 5)

Connection string:
```
postgresql://aiwa_admin:{password}@{endpoint}:5432/aiwa_cloud
```

---

## 4. IAM Roles and Policies

### Create ECS Task Execution Role

1. Go to IAM → Roles → Create role
2. **Trusted entity type**: AWS service
3. **Use case**: Elastic Container Service → Elastic Container Service Task
4. **Permissions**: Attach `AmazonECSTaskExecutionRolePolicy`
5. **Role name**: `aiwa-ecs-task-execution-role`
6. Click "Create role"

### Create ECS Task Role (for Core API and Workers)

1. Create role → AWS service → ECS Task
2. **Permissions**: Create custom policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::aiwa-cloud-storage-*",
        "arn:aws:s3:::aiwa-cloud-storage-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": [
        "arn:aws:sqs:*:*:aiwa-*-queue-*"
      ]
    }
  ]
}
```

3. **Role name**: `aiwa-ecs-task-role`
4. Click "Create role"

---

## 5. ECS Cluster Setup

### Create ECS Cluster

1. Go to ECS → Clusters → Create cluster
2. **Cluster name**: `aiwa-cloud-cluster-{env}`
3. **Infrastructure**: AWS Fargate (serverless)
4. Click "Create"

### Create Task Definitions

#### Core API Task Definition

1. ECS → Task Definitions → Create new task definition
2. **Task definition family**: `aiwa-core-api`
3. **Launch type**: Fargate
4. **Operating system**: Linux/X86_64
5. **Task size**:
   - CPU: 0.5 vCPU
   - Memory: 1 GB
6. **Task role**: `aiwa-ecs-task-role`
7. **Task execution role**: `aiwa-ecs-task-execution-role`
8. **Container**:
   - Name: `core-api`
   - Image URI: `{account-id}.dkr.ecr.{region}.amazonaws.com/aiwa-core-api:latest`
   - Port mappings: 3000 (TCP)
   - Environment variables: (see section 6)
9. Click "Create"

#### REINFER Worker Task Definition

1. Similar to above, but:
   - **Family**: `aiwa-reinfer-worker`
   - **Task size**: 4 vCPU, 8 GB (requires GPU instance for production)
   - **Container image**: `aiwa-reinfer-worker:latest`
   - No port mappings

#### ADVICE Worker Task Definition

1. Similar to above, but:
   - **Family**: `aiwa-advice-worker`
   - **Task size**: 0.5 vCPU, 1 GB
   - **Container image**: `aiwa-advice-worker:latest`

### Create ECS Services

1. Go to your cluster → Services → Create
2. **Launch type**: Fargate
3. **Task definition**: Select created task definition
4. **Service name**: `aiwa-core-api-service` (or worker name)
5. **Number of tasks**: 1 (or desired count)
6. **Deployment options**: Rolling update
7. **Networking**:
   - VPC: Same as RDS
   - Subnets: Private subnets (or public with auto-assign IP)
   - Security group: Allow inbound on port 3000 (for API)
8. **Load balancing** (for Core API only):
   - Type: Application Load Balancer
   - Create new or use existing ALB
   - Target group: Create new, port 3000
9. Click "Create"

---

## 6. Environment Variables

### Core API Environment Variables

```bash
DATABASE_URL=postgresql://aiwa_admin:{password}@{rds-endpoint}:5432/aiwa_cloud
JWT_ACCESS_SECRET={generate-random-string}
JWT_REFRESH_SECRET={generate-random-string}
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID={from-iam-user-or-use-task-role}
AWS_SECRET_ACCESS_KEY={from-iam-user-or-use-task-role}
AWS_S3_BUCKET=aiwa-cloud-storage-prod
AWS_SQS_REINFER_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/{account}/aiwa-reinfer-queue-prod
AWS_SQS_ADVICE_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/{account}/aiwa-advice-queue-prod
NODE_ENV=production
```

### Worker Environment Variables

```bash
DATABASE_URL=postgresql://aiwa_admin:{password}@{rds-endpoint}:5432/aiwa_cloud
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID={from-iam-user-or-use-task-role}
AWS_SECRET_ACCESS_KEY={from-iam-user-or-use-task-role}
AWS_S3_BUCKET=aiwa-cloud-storage-prod
AWS_SQS_REINFER_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/{account}/aiwa-reinfer-queue-prod
AWS_SQS_ADVICE_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/{account}/aiwa-advice-queue-prod
RTMPOSE_MODEL_PATH=/models/rtmpose-m-384x288.onnx
WORKER_TYPE=reinfer  # or advice
LOG_LEVEL=INFO
```

---

## Verification Checklist

- [ ] S3 bucket created with lifecycle policy
- [ ] SQS queues created (REINFER, ADVICE, DLQs)
- [ ] RDS PostgreSQL instance running and accessible
- [ ] IAM roles and policies configured
- [ ] ECS cluster created
- [ ] Task definitions created for all services
- [ ] ECS services running
- [ ] Environment variables configured
- [ ] Core API health check returns 200: `curl http://{alb-url}/health`
- [ ] Database migrations applied: `npx prisma migrate deploy`

---

## Next Steps

1. Build and push Docker images to ECR
2. Deploy services to ECS
3. Run integration tests
4. Monitor CloudWatch logs
5. Set up CloudWatch alarms for queue depth, task failures

## Troubleshooting

### Common Issues

1. **Task fails to start**: Check CloudWatch logs for errors
2. **Database connection fails**: Verify security group rules
3. **S3 access denied**: Check IAM role permissions
4. **SQS messages not processing**: Check visibility timeout and worker logs

### Useful Commands

```bash
# Check ECS task logs
aws logs tail /ecs/aiwa-core-api --follow

# Check SQS queue depth
aws sqs get-queue-attributes --queue-url {queue-url} --attribute-names ApproximateNumberOfMessages

# Test database connection
psql postgresql://aiwa_admin:{password}@{endpoint}:5432/aiwa_cloud
```

