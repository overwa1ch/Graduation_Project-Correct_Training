# Squat Noisy Keypoints Sample

- **类别**：噪声样本
- **目的**：验证关键点抖动、低置信时，滤波与评分是否稳定。
- **输入**：带噪关键点 (`neutral_keypoints.json`)，置信度随机衰减模拟跟踪失败。
- **预期**：
  - `quality.lowConfidence` 在局部帧上升，但整体覆盖率仍可接受。
  - `issues` 包含 `NOISY_LANDMARKS`，`evidence` 指向低置信帧。
  - `perf.json` 与正常样本接近。
- **验证脚本**：`aiwa_agent run milestoneE_test_generation --generate-mock --verify-schema`。
