# TELEMETRY_MIN.md
**Minimum Telemetry & Diagnostics Specification (Phase 5)**  
**Version:** v1.0  
**Applies To:** Android + iOS (mobile)

---

## 1️⃣ Purpose
Define the minimum telemetry and diagnostic data collected locally for debugging and reliability tracking, without collecting personal data.

---

## 2️⃣ Telemetry Scope
| Category | Source | File | Fields |
|-----------|---------|------|--------|
| Runtime Performance | CLI (`aiwa_cli`) | `perf.json` | `total_ms`, `decode_ms`, `infer_ms`, `analyze_ms`, `rss_peak_mb`, `artifacts_size_mb`, `ms_per_frame.{p50,p90,p95,max}` |
| Error Summary | App (`aiwa_app`) | `diagnostics.log` | `sessionId`, `errorCode`, `phase`, `hint` |
| Environment Info | CLI snapshot | `configs_snapshot.json` | `engine`, `strictness`, `stride`, `deviceModel`, `osVersion` |

---

## 3️⃣ Support Bundle
**Path:** `build/offline_out/<sessionId>/support_bundle.zip`  

**Contents:**
support_bundle.zip
├── result.json # redacted
├── perf.json
├── run.log
├── configs_snapshot.json
└── diagnostics.log


**Privacy Policy**
- Strip absolute paths, user names, raw video URIs.  
- Keep only anonymous device brand/model/OS.  
- Bundle created manually via “Export Support Bundle”.  
- Auto-deleted after 7 days unless exported.

---

## 4️⃣ Local Event Log
| Event | When | Data |
|--------|------|------|
| START | Start analysis | `sessionId`, timestamp |
| PHASE_CHANGE | Each phase switch | `phase`, elapsed |
| DONE | End of analysis | `duration`, `totalMs` |
| ERROR | Failure | `errorCode`, `hint` |
| RETRY | User retry | `retryCount` |
| CLEANUP | Auto-cleanup | `removedSessions` |

---

## 5️⃣ Retention
- Stored under `build/offline_out/<sessionId>/`.  
- Auto-cleanup via `cleanup.days` (default 7).  
- Exported bundles user-managed.

---
**End of TELEMETRY_MIN.md**