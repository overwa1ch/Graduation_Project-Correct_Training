# USER_GUIDE.md
**AIWA App User Guide (v1.0)**  
**Platform:** Android + iOS

---

## Overview
AIWA analyzes workout videos locally to generate Posture, Stability, and Rhythm scores — no cloud upload required.

---

## Using the App

1️⃣ **Select or Record Video**  
  Choose existing video or record via camera. 720p @ 30 fps, good lighting recommended.

2️⃣ **Run Analysis**  
  Tap Analyze → observe progress (Decode → Infer → Analyze → Export).

3️⃣ **View Results**  
  Pop-up shows Total and sub-scores; tap Details for evidence frames and advice.

4️⃣ **Settings**  
  Adjust engine, strictness, stride, resolution.  
  Saved to `aiwa_app/configs/app_runtime.json`.

5️⃣ **Export Support Bundle**  
  Settings → Export Support Bundle.  
  File stored at `build/offline_out/<sessionId>/support_bundle.zip`.

---

## Common Issues & Solutions

| Issue | Cause | Resolution |
|-------|-------|-------------|
| Low Confidence banner | Poor lighting / partial view | Improve lighting & camera angle |
| Storage Full | Old sessions remain | Tap “Clean Up” in Settings |
| Analysis Paused | App backgrounded | Keep screen active |
| Unexpected Scores | Old config | Restore Defaults in Settings |

---

## Privacy
- No data uploaded without consent.  
- Files under `build/offline_out/`.  
- Auto-cleanup after 7 days.

---

## Support
For help, export a support bundle and send to AIWA team for diagnosis.

---
**End of USER_GUIDE.md**