# ARCHITECTURE_OVERVIEW.md
**Cloud Platform – Architecture & Component Boundaries**  
**Version:** v1.0

---

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Mobile App (Android/iOS)                 │
│  ┌──────────────────┐         ┌──────────────────────────┐      │
│  │  Local Inference │         │   Cloud Integration      │      │
│  │  (MLKit/MoveNet) │         │   (API Client)           │      │
│  └──────────────────┘         └──────────────────────────┘      │
└─────────────────────────────┬───────────────────────────────────┘
                              │ HTTPS
                              │ JWT (RS256)
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│                    Core API Service                              │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Domain: api.aiwa.dev / api.aiwa.stage / api.aiwa.app │     │
│  │  Routes: /v1/auth/*, /v1/sessions/*, /v1/jobs/*        │     │
│  │  Auth: JWT Bearer (RS256), Refresh Token Flow          │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │  Auth Handler│  │Session Manager│  │  Job Manager │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└──────┬──────────────────┬──────────────────┬────────────────────┘
       │                  │                  │
       │                  │                  │
┌──────▼──────────┐ ┌─────▼─────────────┐ ┌──▼───────────────────┐
│  PostgreSQL     │ │  AWS S3           │ │  AWS SQS             │
│  (Supabase)     │ │  (Object Storage) │ │  (Job Queue)         │
│                 │ │                   │ │                      │
│  - users        │ │  - keypoints.json │ │  - REINFER Queue     │
│  - sessions     │ │  - video.mp4      │ │  - ADVICE Queue      │
│  - assets       │ │  - result*.json   │ │  - DLQ (7 days)      │
│  - consents     │ │  - advice.json    │ │                      │
│  - jobs         │ │                   │ │                      │
│                 │ │  SSE-S3/SSE-KMS  │ │  Visibility Timeout  │
│  (Separate from │ │                   │ │  - REINFER: 45min     │
│   admin-*)      │ │  Retention: 30d  │ │  - ADVICE: 10min     │
└─────────────────┘ └───────────────────┘ └──────┬────────────────┘
                                                  │
                                                  │ Messages
                                                  │
┌─────────────────────────────────────────────────▼──────────────┐
│                    Worker Services                             │
│  ┌──────────────────────┐  ┌──────────────────────┐             │
│  │  REINFER Worker      │  │  ADVICE Worker       │             │
│  │                      │  │                      │             │
│  │  - Heavy Model       │  │  - AI Model          │             │
│  │  - Timeout: 30min    │  │  - Timeout: 5min     │             │
│  │  - Output:           │  │  - Output:           │             │
│  │    result_cloud.json │  │    advice.json       │             │
│  └──────────────────────┘  └──────────────────────┘             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Admin Console (Next.js)                      │
│  ┌────────────────────────────────────────────────────────┐     │
│  │  Domain: admin.aiwa.dev / admin.aiwa.stage / ...     │     │
│  │  Routes: /signin, /signup, /admin-users/*             │     │
│  │  Auth: Cookie Session (7 days)                        │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐                            │
│  │  Auth Handler│  │Admin Manager  │                            │
│  │  (Cookie)    │  │              │                            │
│  └──────────────┘  └──────────────┘                            │
└──────┬──────────────────────────────────────────────────────────┘
       │
       │
┌──────▼──────────────────────────────────────────────────────────┐
│  PostgreSQL (Same DB, Separate Tables)                          │
│  - admin-users    (Admin accounts)                               │
│  - admin-session  (Admin sessions)                               │
│                                                                  │
│  Note: Admin tables are SEPARATE from App user tables            │
└──────────────────────────────────────────────────────────────────┘
```

---

## Component Boundaries & Responsibilities

### 1. Mobile App
- **Local Inference:** On-device ML (MLKit/MoveNet)
- **Cloud Integration:** API client for JWT auth, session management, job polling
- **Data Storage:** Local DB for sessions, token storage (Keychain/Keystore)
- **Fallback:** Always works locally; cloud enhancements are optional

### 2. Core API Service
- **Authentication:** JWT (RS256) with refresh token flow
- **Session Management:** Create sessions, presigned URLs, asset binding
- **Job Management:** Trigger REINFER/ADVICE jobs, poll status
- **Rate Limiting:** 60 rpm per user & per IP
- **Error Handling:** Standardized error responses with request IDs

### 3. PostgreSQL Database
- **App User Tables:** `users`, `sessions`, `assets`, `consents`, `jobs`
- **Admin Tables:** `admin-users`, `admin-session` (separate, not mixed)
- **Soft Delete:** `deleted_at` marker, 7-day retention
- **Cascades:** ON DELETE CASCADE with validation

### 4. AWS S3 Object Storage
- **Structure:** `users/{user_id}/sessions/{session_id}/{file}`
- **Encryption:** SSE-S3 (default) / SSE-KMS (optional)
- **Retention:** 30 days default, cascaded deletion on session delete
- **Presigned URLs:** ≤15 minutes, single-use

### 5. AWS SQS Job Queue
- **Queues:** REINFER, ADVICE, Dead-Letter Queue
- **Visibility Timeout:** REINFER 45min, ADVICE 10min (must exceed job timeout)
- **Retry:** Exponential backback, max 3 attempts
- **DLQ Retention:** 7 days

### 6. Worker Services
- **REINFER Worker:** Heavy model inference, 30min SLA
- **ADVICE Worker:** AI advice generation, 5min SLA
- **Output:** Write results to S3, update job status in DB

### 7. Admin Console
- **Authentication:** Cookie Session (7 days), separate from App JWT
- **Domain:** Separate subdomain (admin.aiwa.*)
- **Tables:** Separate admin tables, not mixed with App users
- **Future:** May add read-only API to view App user sessions (via restricted backend API)

---

## Authentication Boundaries

### Core API (App Users)
- **Method:** JWT (RS256) with refresh tokens
- **Access Token:** 15 minutes
- **Refresh Token:** 30 days (sliding expiration)
- **Revocation:** Refresh token blacklist (DB or Redis)
- **Domain:** `api.aiwa.*`

### Admin Console (Admins)
- **Method:** Cookie Session
- **Duration:** 7 days
- **Tables:** `admin-users`, `admin-session` (separate from App users)
- **Domain:** `admin.aiwa.*`
- **Note:** No JWT; separate authentication system

---

## Data Flow Examples

### 1. App User Upload Session
```
App → Core API (/v1/sessions) → Returns presigned URLs
App → S3 (PUT presigned URL) → Uploads keypoints.json
App → Core API (/v1/sessions/{id}/finalize) → Binds assets
Core API → Updates DB (sessions.status = "uploaded")
```

### 2. Job Processing
```
App → Core API (/v1/sessions/{id}/jobs/reinfer) → Creates job
Core API → SQS (enqueue message) → Worker picks up
Worker → S3 (download assets) → Process → S3 (upload result_cloud.json)
Worker → DB (update job.status = "succeeded")
App → Core API (/v1/jobs/{id}) → Polls until succeeded
```

### 3. Admin Login
```
Admin → Admin Console (/signin) → Cookie Session created
Admin Console → DB (admin-session table) → Session stored
Admin → Admin Console (/admin-users) → Cookie validated
```

---

## Security Boundaries

- **CORS:** Only allowed for mobile app bundles and approved web domains
- **Rate Limiting:** 60 rpm per user & per IP (429 response)
- **Token Storage:** Secure (Keychain/Keystore)
- **Encryption:** SSE-S3 (default) / SSE-KMS (optional)
- **Webhook Signing:** HMAC SHA-256 with timestamp and replay protection

---

## Deployment Boundaries

- **Core API:** Independent service (can be deployed separately)
- **Admin Console:** Independent Next.js app (can be deployed separately)
- **Workers:** Independent services (can scale independently)
- **Database:** Shared PostgreSQL (but tables are logically separated)
- **Storage:** Shared S3 bucket (but paths are isolated by user_id/session_id)

---

**End of ARCHITECTURE_OVERVIEW.md**

