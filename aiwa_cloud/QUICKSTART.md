# AIWA Cloud - Quick Start Guide

Get the AIWA Cloud Platform running locally in 10 minutes.

## Prerequisites

- Docker & Docker Compose installed
- Node.js 20+ (for local Core API development)
- Python 3.11+ (for local Worker development)
- AWS account (for S3 and SQS)

## Step 1: Clone and Setup (2 min)

```bash
# Navigate to aiwa_cloud directory
cd aiwa_cloud

# Create environment files
cp core-api/.env.example core-api/.env
cp workers/.env.example workers/.env
```

## Step 2: Configure AWS (3 min)

### Option A: Use Existing AWS Resources

If you have S3 bucket and SQS queues already:

1. Edit `core-api/.env`:
```bash
AWS_S3_BUCKET=your-bucket-name
AWS_SQS_REINFER_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789/your-reinfer-queue
AWS_SQS_ADVICE_QUEUE_URL=https://sqs.us-east-1.amazonaws.com/123456789/your-advice-queue
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
```

2. Copy same AWS config to `workers/.env`

### Option B: Create AWS Resources

Follow: `infra/manuals/AWS_SETUP.md` (15-20 minutes)

## Step 3: Start Services (2 min)

```bash
# Start PostgreSQL, Core API, and ADVICE Worker
docker-compose up -d

# Check services are running
docker-compose ps

# View logs
docker-compose logs -f core-api
```

## Step 4: Initialize Database (1 min)

```bash
# Run migrations
cd core-api
npm install
npx prisma migrate deploy

# (Optional) Seed test data
npx prisma db seed
```

## Step 5: Test API (2 min)

### Register a user:
```bash
curl -X POST http://localhost:3000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

### Login:
```bash
curl -X POST http://localhost:3000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Save the `access_token` from the response.

### Create a session:
```bash
curl -X POST http://localhost:3000/v1/sessions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "client_session_id": "test-session-1",
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "consent": "keypoints"
  }'
```

You'll get presigned URLs for uploading keypoints!

## Common Tasks

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f core-api
docker-compose logs -f advice-worker
```

### Restart Services

```bash
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart core-api
```

### Stop Services

```bash
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

### Access Database

```bash
# Using Prisma Studio
cd core-api
npx prisma studio

# Using psql
docker exec -it aiwa-postgres psql -U aiwa -d aiwa_cloud
```

## Development Workflow

### Core API Development

```bash
cd core-api

# Install dependencies
npm install

# Run in watch mode
npm run dev

# Build for production
npm run build

# Run tests (when implemented)
npm test
```

### Worker Development

```bash
cd workers

# Install dependencies
pip install -r requirements.txt

# Run REINFER worker
python inference/consumer.py

# Run ADVICE worker
python advice/consumer.py

# Run health endpoint
python app.py
```

## Troubleshooting

### Issue: Core API can't connect to database

**Solution**: Check PostgreSQL is running:
```bash
docker-compose ps postgres
docker-compose logs postgres
```

### Issue: Workers can't access S3/SQS

**Solution**: Verify AWS credentials:
```bash
# Test AWS CLI
aws s3 ls s3://your-bucket-name
aws sqs list-queues
```

### Issue: Port 3000 already in use

**Solution**: Change port in `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Use port 3001 instead
```

### Issue: REINFER worker needs GPU

**Solution**: 
1. For local dev, use CPU version (slower)
2. For production, deploy to ECS with GPU instance
3. Uncomment GPU config in `docker-compose.yml`

## Next Steps

1. **Read the docs**: `docs/07-cloud/`
2. **Test the full flow**: Upload keypoints → Trigger jobs → Get results
3. **Deploy to AWS**: Follow `infra/manuals/AWS_SETUP.md`
4. **Integrate with mobile app**: See `docs/07-cloud/APP_INTEGRATION_GUIDE.md`

## Useful Links

- **API Docs**: `docs/07-cloud/CLOUD_CORE_API.md`
- **Architecture**: `docs/07-cloud/ARCHITECTURE_OVERVIEW.md`
- **AWS Setup**: `infra/manuals/AWS_SETUP.md`
- **Full README**: `README.md`

## Support

- Check logs first: `docker-compose logs -f`
- Review documentation in `docs/07-cloud/`
- Check GitHub issues
- Contact: support@aiwa.dev

---

**Happy coding! 🚀**

