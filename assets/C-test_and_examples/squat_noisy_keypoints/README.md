# squat_noisy_keypoints 样本

- **类别**：噪声样本
- **目的**：验证关键点抖动与置信度噪声下的鲁棒性。
- **输入**：`neutral_keypoints.json`（注入随机抖动与低置信帧）。
- **预期现象**：
  - 低置信帧比例约 18%，但计数仍稳定在 6 次。
  - `result.json` 中 `quality.lowConfidence` 与标记帧一致。
  - Evidence 聚焦于噪声高峰帧，`scoreImpact` 控制在 -0.8 以内。
