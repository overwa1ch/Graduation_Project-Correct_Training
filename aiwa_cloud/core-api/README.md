# AIWA Core API

Cloud-based API service for AIWA training analysis platform. Provides JWT authentication, session management, job orchestration, and result retrieval.

## Features

- **JWT RS256 Authentication**: Secure token-based auth with refresh tokens
- **Session Management**: Create sessions and generate presigned S3 URLs
- **Job Orchestration**: Trigger REINFER and ADVICE jobs via SQS
- **Result Retrieval**: Fetch analysis results from S3

## Tech Stack

- **Framework**: Fastify
- **Database**: PostgreSQL (via Prisma ORM)
- **Cloud**: AWS (S3, SQS)
- **Language**: TypeScript

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env` and fill in your configuration:

```bash
cp .env.example .env
```

### 3. Setup Database

```bash
# Generate Prisma client
npm run prisma:generate

# Run migrations
npm run prisma:migrate

# Or push schema directly (dev only)
npm run prisma:push
```

### 4. Generate RSA Keys for JWT

```bash
# Generate private key
openssl genrsa -out private.pem 2048

# Generate public key
openssl rsa -in private.pem -pubout -out public.pem
```

Update `.env` with the key paths or inline keys.

### 5. Start Development Server

```bash
npm run dev
```

Server will start on `http://localhost:3000`

## API Endpoints

### Authentication

- `POST /v1/auth/register` - Register new user
- `POST /v1/auth/login` - Login and get JWT tokens
- `POST /v1/auth/refresh` - Refresh access token

### Sessions

- `POST /v1/sessions` - Create session and get presigned URLs
- `POST /v1/sessions/:id/finalize` - Bind uploaded assets
- `GET /v1/sessions/:id` - Get session details

### Jobs

- `POST /v1/sessions/:id/jobs/reinfer` - Trigger REINFER job
- `POST /v1/sessions/:id/jobs/advice` - Trigger ADVICE job
- `GET /v1/jobs/:id` - Poll job status

### Results

- `GET /v1/sessions/:id/results` - Get all results (local/cloud/advice)

## Development

```bash
# Run in watch mode
npm run dev

# Build for production
npm run build

# Start production server
npm start

# Run linter
npm run lint

# Open Prisma Studio
npm run prisma:studio
```

## Deployment

See `../infra/` for Terraform configuration and deployment guides.

## License

MIT

