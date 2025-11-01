# BUDGET.md
**Performance Budget & Benchmark Template (Phase 5)**  
**Version:** v1.0  
**Platform:** Android + iOS

---

## Key Metrics

| Metric | Target | Notes |
|---------|---------|-------|
| Total Analysis Time | ≤ 45 s (720p @ 30 fps, stride 2) | decode + infer + analyze + export |
| Decode Phase | ≤ 10 s | Video decode |
| Inference Phase | ≤ 25 s | MoveNet / MLKit |
| Analysis Phase | ≤ 5 s | Rule evaluation |
| Export Phase | ≤ 3 s | File write |
| Peak Memory (RSS) | ≤ 400 MB | Mobile device |
| Artifacts Size | ≤ 10 MB | Result + perf + keypoints |
| CPU Utilization | < 90 % per core | During inference |
| Battery Impact | < 5 % per run | ~30 s session |

---

## perf.json Sample
```json
{
  "frames_total": 1275,
  "stride": 2,
  "total_ms": 38100,
  "decode_ms": 4200,
  "infer_ms": 22100,
  "analyze_ms": 3800,
  "export_ms": 1900,
  "ms_per_frame": { "p50": 27.1, "p90": 33.4, "p95": 36.8, "max": 48.2 },
  "rss_peak_mb": 312,
  "artifacts_size_mb": 8.4,
  "device": {"brand": "Google","model": "Pixel 7","soc": "GS101"}
}
Validation
Run 3 samples per device (Android/iOS).
Aggregate P95 values and compare with targets.
Deviation > 10 % → investigate bottleneck.

Compliance Report Template
Device	Date	Version	Total (ms)	RSS (MB)	OK?	Notes
Pixel 7	2025-10-30	v1.0.0	38100	312	✅	Baseline
iPhone 13	2025-10-30	v1.0.0	36500	298	✅	Baseline

End of BUDGET.md