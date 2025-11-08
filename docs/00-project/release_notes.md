# RELEASE_NOTES.md
**AIWA Phase 5 – Release Hardening**  
**Version:** v1.0.0  |  Date:** 2025-10-30**  
**Platforms:** Android & iOS

---

## Highlights
- Integrated Isolate execution for mobile analysis.  
- Added CLI performance logging (`perf.json`).  
- Support bundle export for diagnostics.  
- Improved error handling and recovery.  
- Stabilized session management & auto-cleanup.

---

## Versions
| Component | Version | Notes |
|------------|----------|-------|
| aiwa_app | v1.0.0 | Mobile build with Isolate support |
| aiwa_cli | v1.0.0 | Adds perf logging & bundle export |
| aiwa_core | v1.0.0 | Shared pose logic module |

---

## Compatibility
| OS | Minimum Version | Tested Devices |
|----|------------------|----------------|
| Android | 10 (Q) | Pixel 7, Samsung S21 |
| iOS | 15.0 | iPhone 13, iPhone 14 |

---

## Known Limitations
- > 60 fps videos increase runtime.  
- > 1080p videos auto-downsampled to 720p.  
- CLI restricted to local files (no network sources).  
- iOS background execution may pause analysis.

---

## Upgrade Notes
- Ensure `aiwa_app/configs/app_runtime.json` exists and valid.  
- Delete legacy `offline_out/` sessions after upgrade.  
- `perf.json` remains compatible with the published v1 schema.

---

## Next Phase
Phase 6 – Post-release metrics collection and adaptive rule tuning pipeline.

---
**End of RELEASE_NOTES.md**