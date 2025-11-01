# APP_INTEGRATION_GUIDE.md
**AIWA App – Cloud Integration Guide (P0)**  
**Version:** v1.0  
**Platforms:** Android + iOS  
**Base URL:** `https://api.aiwa.dev` (production) / `https://api.aiwa.stage` (staging) / `https://api.aiwa.app` (development)

---

## 1) Sequence (Happy Path)

1. `POST /v1/auth/login` → JWT + Refresh Token
2. Store tokens securely (Keychain/Keystore)
3. `POST /v1/sessions` → `session_id` + presigned URLs
4. Upload `keypoints.json` (required) and `video.mp4` (optional, requires consent)
5. `POST /v1/sessions/{id}/finalize`
6. Trigger `reinfer` and `advice` jobs: `POST /v1/sessions/{id}/jobs/reinfer`, `POST /v1/sessions/{id}/jobs/advice`
7. Poll `GET /v1/jobs/{job_id}` until `status = "succeeded"` or `"failed"`
8. `GET /v1/sessions/{id}/results` fetch `cloud_result` + `advice`
9. Frontend merges and displays (retain fallback to local-only results)

---

## 2) Error Handling

**Standard Error Response:**
```json
{
  "error": {
    "code": "JOB_TIMEOUT",
    "message": "Cloud job timed out",
    "details": {"job_id": "job_abc123"}
  },
  "request_id": "req_abc123"
}
```

**Error Handling Strategy:**

| Error Code | HTTP | User Action |
|------------|------|-------------|
| `401 AUTH_INVALID` / `AUTH_EXPIRED` | 401 | Prompt re-login, refresh token |
| `403 CONSENT_REQUIRED` | 403 | Show consent dialog (video upload only) |
| `410 UPLOAD_EXPIRED` | 410 | Request new presigned URL |
| `504 JOB_TIMEOUT` | 504 | Show "try again later", keep local results |
| `503 WORKER_UNAVAILABLE` | 503 | Show "service unavailable", keep local results |
| `429 RATE_LIMITED` | 429 | Show "too many requests", retry after delay |
| Network unavailable | - | Show local results only, don't block usage |

**Graceful Degradation:** App always shows local results; cloud enhancements are optional enhancements.

---

## 3) UI Notes

**Settings Page:**
- Upload scope selection (default: `keypoints`; `video+keypoints` requires explicit consent)
- Show consent status and expiration

**Results Page:**
- If `result_cloud` exists, display "Cloud enhanced" badge
- Allow toggle between local/cloud results
- Show job polling status (if jobs still processing)

**Advice Panel:**
- Render `{title, detail, evidence}` list from `advice.json`
- Format evidence timestamps for user-friendly display

---

## 4) Security & Privacy

**Token Storage:**
- Access Token: Secure storage (Keychain/Keystore)
- Refresh Token: Secure storage (Keychain/Keystore)
- Token rotation: Refresh before expiration (15 min access token)

**Session Management:**
- Session files cleaned per `cleanup.days` (local policy)
- "Delete session" action: Call cloud delete API + remove local files
- Revoke consent: Cloud deletes video immediately

**Network:**
- Use HTTPS only
- Certificate pinning (optional, for production)

---

## 5) Sample Mappings

**Local-to-Cloud Session Binding:**
- `client_session_id` (App local) ↔ `session_id` (Cloud server) stored in local DB
- Mapping table: `{client_session_id, cloud_session_id, created_at, status}`

**File Naming Convention:**
- `keypoints.json` - Keypoints data (required)
- `video.mp4` - Video file (optional, consented)
- `result.json` - Local inference result (optional)
- `result_cloud.json` - Cloud re-inference result (generated)
- `advice.json` - AI advice (generated)

---

## 6) Minimal Tests (Contract)

**Required Test Coverage:**
1. Mock API: Register/login/sessions/jobs/results basic flows
2. Network unavailable: App still shows local results
3. Video consent disabled: Should not call video upload endpoints
4. Token refresh: Automatic refresh on 401
5. Job polling: Handle succeeded/failed/timeout states
6. Error handling: All error codes display appropriate messages

**Test Scenarios:**
- Happy path (full cloud integration)
- Partial cloud (keypoints only, no video)
- Local-only fallback (no cloud)
- Error recovery (expired tokens, network errors, job failures)

---

## 7) API Authentication

**JWT Details:**
- Algorithm: RS256
- Access Token: 15 minutes
- Refresh Token: 30 days (sliding expiration)
- Header: `Authorization: Bearer <access_token>`

**Token Refresh Flow:**
1. On 401 response, call `POST /v1/auth/refresh` with refresh token
2. Update stored access token
3. Retry original request
4. If refresh fails, prompt user to re-login

---

## 8) Rate Limiting

**Limits:** 60 requests per minute per user & per IP

**On 429 Response:**
- Back off exponentially
- Show user-friendly message
- Do not block local-only functionality

---

**End of APP_INTEGRATION_GUIDE.md**
