# DATA_SCHEMAS.md
**Cloud Core – Data Schemas (P0)**  
**Version:** v1.0  
**Storage:** Postgres + AWS S3 (S3-compatible object storage)  
**Note:** Admin tables (`admin-users`, `admin-session`) are **separate** and not mixed with App user tables.

---

## 1) Tables

### users
- id (uuid, pk)
- email (text, unique)
- password_hash (text)
- status (text, default 'active')
- tenant_id (text, nullable) - **Reserved for future multi-tenant support**
- created_at (timestamptz, default now())

### sessions
- id (uuid, pk)
- client_session_id (text, index)
- user_id (uuid, fk → users.id)
- template (text) - Enum: `["squat"]` (v1 minimum set)
- strictness (text) - Enum: `["strict", "relaxed"]`, default: `"strict"`
- engine (text) - Enum: `["MoveNet", "MLKit", "Auto"]`, default: `"MoveNet"`
- status (text) - Enum: `local_only | uploaded | processing | ready | failed | cancelled`
- deleted_at (timestamptz, nullable) - **Soft delete marker**
- created_at (timestamptz, default now())
- updated_at (timestamptz, default now())

**Status State Machine:**
- `local_only` → `uploaded` (on `POST /v1/sessions/{id}/finalize`)
- `uploaded` → `processing` (when Job started)
- `processing` → `ready` (Worker success)
- `processing` → `failed` (Worker failure)
- `processing` → `cancelled` (User cancellation)

**Soft Delete:** Marked `deleted_at`, retained 7 days for recovery; hard delete (DB + S3) after expiry.

### assets
- id (uuid, pk)
- session_id (uuid, fk → sessions.id, index)
- type (text) - Enum: `video | keypoints | result_local | result_cloud | advice`
- uri (text) - S3 URI: `s3://bucket/users/{user_id}/sessions/{session_id}/{filename}`
- sha256 (text)
- size (bigint)
- content_type (text)
- created_at (timestamptz, default now())

**FK:** ON DELETE CASCADE (cascades on session hard delete, with secondary validation to prevent active job interference)

### consents
- id (uuid, pk)
- user_id (uuid, fk → users.id)
- session_id (uuid, fk → sessions.id)
- scope (text) - Enum: `keypoints | video+keypoints`
- granted_at (timestamptz)
- expires_at (timestamptz, nullable)
- revoked_at (timestamptz, nullable)

**Revocation:** Immediate deletion of `video.mp4` objects; `keypoints.json` may be retained if only video consent revoked.

### jobs
- id (uuid, pk)
- session_id (uuid, fk → sessions.id, index)
- type (text) - Enum: `REINFER | ADVICE`
- status (text) - Enum: `queued | running | succeeded | failed`
- priority (int, default 0)
- error_code (text, nullable)
- created_at (timestamptz, default now())
- finished_at (timestamptz, nullable)

**SLA Timeouts:**
- `REINFER`: 30 minutes
- `ADVICE`: 5 minutes

**FK:** ON DELETE CASCADE (with validation to prevent active job deletion)

---

## 2) Indexing & Constraints

- `sessions (user_id, created_at desc)` – recent sessions per user
- `sessions (status, created_at)` – active job lookup
- `sessions (deleted_at)` – soft delete cleanup query
- `assets (session_id, type)` – unique partial index to avoid duplicates
- `jobs (session_id, type, created_at)` – latest job lookup
- `jobs (status, created_at)` – queue processing
- FK ON DELETE CASCADE for assets/consents/jobs when session removed (with validation)

---

## 3) Object Storage Layout

**S3 Bucket:** AWS S3 (configurable for MinIO/Supabase Storage compatibility)

**Encryption:** SSE-S3 (default) / SSE-KMS (if key audit required)

**Structure:**
```
s3://bucket/
users/{user_id}/sessions/{session_id}/
  keypoints.json
  video.mp4          # optional, consented
  result.json         # uploaded local result (optional)
  result_cloud.json   # cloud re-inference
  advice.json         # AI advice
```

**Lifecycle Policies:**
- Server-side encryption enabled
- Unreferenced / expired objects auto-deleted after 30 days (default retention)
- Session deletion triggers cascaded object deletion
- Revoked consent: immediate video deletion

**Size Limits (configurable):**
- `VIDEO_MAX=200MB`
- `KEYPOINTS_MAX=20MB`
- `MULTIPART_THRESHOLD=8MB`

---

## 4) Retention & Cleanup

- **Default Retention:** 30 days, then purge if not linked to active session
- **Soft Delete:** Mark `deleted_at`, retain 7 days for recovery; hard delete after expiry
- **User-initiated Delete:** Deletes DB rows and storage objects (idempotent)
- **Revoked Consent:** Remove `video.mp4` immediately; keep keypoints if allowed

---

**End of DATA_SCHEMAS.md**
