# Squat Long Sample

- **类别**：性能样本（超长）
- **目的**：验证长时素材下的内存峰值、降级策略与 perf 报告。
- **输入**：7 分钟 1080p 视频 (`input.mp4`)，含 80 次深蹲。
- **预期**：
  - `perf.json` 中 `memPeakMB` 保持在 600 MB 以下。
  - `rtf` 接近 1.0，展示性能上限。
  - `issues` 可记录疲劳相关 cue，`evidence` 包含多段摘要帧。
- **验证脚本**：`aiwa_agent run milestoneE_test_generation --verify-schema --export-json`。
