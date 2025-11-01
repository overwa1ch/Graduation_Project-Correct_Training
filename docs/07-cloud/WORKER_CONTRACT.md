# WORKER_CONTRACT.md
**Workers – Re-Inference & Advice**  
**Version:** v1.0  
**Queue:** AWS SQS (+ Dead-Letter Queue)

---

## 1) Queue Configuration

**Service:** AWS SQS  
**Dead-Letter Queue (DLQ):** Retains failed messages for 7 days

**Visibility Timeout:**
- `REINFER`: 45 minutes (must exceed job timeout)
- `ADVICE`: 10 minutes (must exceed job timeout)

**Rationale:** Visibility timeout > Job timeout prevents premature message re-queueing.

---

## 2) Message Format (Queue)

Common envelope:
```json
{
  "job_id": "job_...",
  "session_id": "1a3f...",
  "type": "REINFER | ADVICE",
  "assets": {
    "keypoints": "s3://.../keypoints.json",
    "video": "s3://.../video.mp4",
    "result_local": "s3://.../result.json"
  },
  "attempt": 1
}
```

---

## 3) REINFER Worker

Load heavy/accurate model (e.g., higher-res, temporal model).

**Input:** `keypoints.json`, optional `video.mp4`, optional `result_local.json`

**Output:** `result_cloud.json` (superset, compatible with local `result.json` fields)

**May include:** `calibration`, `confidence_hist`, `smoothing_params`, additional analysis metrics

**Process:**
1. Download assets from S3
2. Run heavy model inference
3. Write `result_cloud.json` to S3: `s3://bucket/users/{user_id}/sessions/{session_id}/result_cloud.json`
4. Update job status to `succeeded` in database

**Timeout:** 30 minutes (SLA)

---

## 4) ADVICE Worker

**Input:** Local/cloud results (prefer cloud), optional keypoints, optional video

**Output:** `advice.json`

```json
{
  "advice": [
    {
      "title": "Keep chest up",
      "detail": "...",
      "evidence": {
        "t": "00:00:27.07",
        "angle": "kneeValleyAngle"
      }
    },
    {
      "title": "Even tempo",
      "detail": "...",
      "evidence": {
        "rep": 8,
        "phase": "eccentric"
      }
    }
  ],
  "version": "v1.0"
}
```

**Process:**
1. Load results (prefer `result_cloud.json` over `result.json`)
2. Optionally load `keypoints.json` and `video.mp4` for context
3. Generate structured advice using AI/model
4. Write `advice.json` to S3
5. Update job status to `succeeded`

**Timeout:** 5 minutes (SLA)

**Output is structured; App only renders the list.**

---

## 5) Timeouts & Retries

**Job Timeouts (SLA):**
- `REINFER`: 30 minutes
- `ADVICE`: 5 minutes

**Retry Strategy:**
- Exponential backoff
- Maximum 3 attempts
- Failed messages move to DLQ after 3 failures

**Final Failure:** `jobs.status = failed`, record `error_code` (e.g., `JOB_TIMEOUT`, `WORKER_UNAVAILABLE`, `MODEL_ERROR`)

---

## 6) Observability (P0)

**Logging Requirements:**
- Start time, input size (asset sizes)
- Per-stage duration (download, inference, upload)
- Final status, error code (if failed)
- **No PII or privacy-sensitive data in logs**

**Metrics:**
- Job duration (p50, p95, p99)
- Success/failure rates
- Queue depth
- Worker utilization

---

**End of WORKER_CONTRACT.md**
