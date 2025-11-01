# CLOUD_CORE_API.md
**Cloud Core API (P0) – Contract**  
**Version:** v1.0  
**Base URL:** `https://api.aiwa.dev` (production) / `https://api.aiwa.stage` (staging) / `https://api.aiwa.app` (development)  
**Auth:** JWT (Bearer, RS256), Refresh token flow  
**Idempotency:** `Idempotency-Key` header for POST endpoints  
**Formats:** JSON; time ISO8601; numbers in SI units  
**Rate Limits:** 60 requests per minute per user & per IP (429 when exceeded)

---

## 0) Conventions

- `session_id`: server UUID (string, `sess_...` optional prefix)
- `client_session_id`: app local sessionId (e.g., `20251028_101320_7f2c`)
- `asset.type`: `video | keypoints | result_local | result_cloud | advice`
- Presigned URLs are time-limited (≤15 minutes); client uploads directly to object storage
- **CORS:** Only allowed for mobile app bundles and approved web domains

---

## 1) Authentication

### JWT Token Details
- **Algorithm:** RS256 (RSA with SHA-256)
- **Access Token:** 15 minutes validity
- **Refresh Token:** 30 days validity (sliding expiration)
- **Revocation:** Refresh token blacklist (stored in DB or Redis), supports logout-all-devices

### POST /v1/auth/register
Request:
```json
{
  "email": "user@example.com",
  "password": "******"
}
```
Response:
```json
{
  "token": "JWT...",
  "refresh_token": "REFRESH..."
}
```

### POST /v1/auth/login
Request: same as register  
Response: same as register

### POST /v1/auth/refresh
Request:
```json
{
  "refresh_token": "REFRESH..."
}
```
Response:
```json
{
  "token": "JWT..."
}
```

**Note:** Multi-tenant support (optional `tenant_id` field) reserved for future use; currently single-tenant.

---

## 2) Session Lifecycle

### POST /v1/sessions
Create a session and obtain upload URLs.

**Headers:** `Authorization: Bearer <JWT>`

Request:
```json
{
  "client_session_id": "20251028_101320_7f2c",
  "template": "squat",
  "strictness": "strict",
  "engine": "MoveNet",
  "consent": "keypoints"
}
```

**Enumerations & Defaults:**
- `template`: `["squat"]` (minimum set for v1, future: `pushup`, `deadlift`, ...)
- `engine`: `["MoveNet", "MLKit", "Auto"]` (**default:** `"MoveNet"`)
- `strictness`: `["strict", "relaxed"]` (**default:** `"strict"`)
- `consent`: `["keypoints", "video+keypoints"]`

Response:
```json
{
  "session_id": "1a3f6c1e-...",
  "upload_policies": {
    "keypoints_url": "https://...",
    "video_url": null
  }
}
```

### PUT <presigned_url>
Upload keypoints/video directly to storage. (No API auth headers required.)

**Constraints:**
- Presigned URL valid ≤15 minutes
- Single-use (first successful PUT invalidates URL)
- Content-Type restricted by server policy
- Max sizes: `VIDEO_MAX=200MB`, `KEYPOINTS_MAX=20MB`

### POST /v1/sessions/{session_id}/finalize
Bind uploaded assets to the session.

Request:
```json
{
  "assets": [
    {
      "type": "keypoints",
      "sha256": "abc..",
      "size": 321456,
      "content_type": "application/json"
    },
    {
      "type": "result_local",
      "sha256": "def..",
      "size": 10240,
      "content_type": "application/json"
    }
  ]
}
```
Response: `200 OK`

**Status Transition:** `local_only → uploaded`

### GET /v1/sessions/{session_id}
Response:
```json
{
  "session_id": "1a3f6c1e-...",
  "client_session_id": "20251028_101320_7f2c",
  "status": "uploaded",
  "template": "squat",
  "engine": "MoveNet",
  "strictness": "strict",
  "created_at": "2025-10-30T10:20:00Z"
}
```

**Status Values:** `local_only | uploaded | processing | ready | failed | cancelled`

---

## 3) Jobs

### POST /v1/sessions/{session_id}/jobs/reinfer
Start a re-inference job (cloud heavy model).  
**Status Transition:** `uploaded → processing`

Response:
```json
{
  "job_id": "job_9b2a..."
}
```

### POST /v1/sessions/{session_id}/jobs/advice
Start an AI advice job.  
**Status Transition:** `uploaded → processing` (if not already processing)

Response:
```json
{
  "job_id": "job_b92f..."
}
```

### GET /v1/jobs/{job_id}
Response:
```json
{
  "job_id": "job_9b2a...",
  "type": "REINFER",
  "status": "queued | running | succeeded | failed",
  "error_code": null,
  "result_asset": {
    "type": "result_cloud",
    "uri": "s3://bucket/path/result_cloud.json"
  }
}
```

**Status Transitions:**
- Worker success: `processing → ready`
- Worker failure: `processing → failed`
- User cancellation: `processing → cancelled`

---

## 4) Results

### GET /v1/sessions/{session_id}/results
Response **always includes three keys** (`local`, `cloud`, `advice`); missing resources return `null`:

```json
{
  "local": {
    "type": "result_local",
    "uri": "s3://.../result.json"
  },
  "cloud": {
    "type": "result_cloud",
    "uri": "s3://.../result_cloud.json"
  },
  "advice": {
    "type": "advice",
    "uri": "s3://.../advice.json"
  }
}
```

**Or when resources are missing:**
```json
{
  "local": {"type": "result_local", "uri": "s3://.../result.json"},
  "cloud": null,
  "advice": null
}
```

---

## 5) Error Responses

**Standard Error Response Structure:**
```json
{
  "error": {
    "code": "JOB_TIMEOUT",
    "message": "Cloud job timed out",
    "details": {
      "job_id": "job_abc123"
    }
  },
  "request_id": "req_abc123"
}
```

**Error Codes & HTTP Status Mapping:**

| Error Code | HTTP Status | Description |
|------------|-------------|-------------|
| `AUTH_INVALID` | 401 | Invalid or malformed token |
| `AUTH_EXPIRED` | 401 | Token expired (refresh required) |
| `CONSENT_REQUIRED` | 403 | Video upload requires explicit consent |
| `UPLOAD_EXPIRED` | 410 | Presigned URL expired |
| `UPLOAD_MISMATCH` | 422 | SHA256 or size mismatch |
| `JOB_NOT_FOUND` | 404 | Job does not exist |
| `JOB_TIMEOUT` | 504 | Job exceeded SLA timeout |
| `WORKER_UNAVAILABLE` | 503 | Worker service unavailable |
| `NOT_FOUND` | 404 | Resource not found |
| `RATE_LIMITED` | 429 | Rate limit exceeded (60 rpm) |
| `INTERNAL_ERROR` | 500 | Server internal error |

**All error responses include `request_id` for tracing.**

---

## 6) Webhooks (Optional)

### POST /v1/hooks/job_status
Server calls back when a job status changes.

**Headers:**
- `X-AIWA-Signature: sha256=<hex>` (HMAC SHA-256 of body + `X-AIWA-Timestamp`)
- `X-AIWA-Timestamp: <unix_timestamp>`
- `X-AIWA-Delivery-Id: <uuid>` (for deduplication)

**Security:**
- Signature: HMAC SHA-256 of `{body} + {timestamp}` using shared secret
- Replay protection: 5-minute time window; deduplicate by `delivery_id`
- Retry: Exponential backoff, max 3 attempts; alert on failure

Payload:
```json
{
  "job_id": "job_...",
  "session_id": "1a3f...",
  "status": "succeeded"
}
```

---

**End of CLOUD_CORE_API.md**
