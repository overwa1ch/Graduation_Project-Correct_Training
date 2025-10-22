# squat_occlusion 样本

- **类别**：异常样本
- **目的**：验证遮挡触发 Hybrid，检查云端 mock 与本地结果合并逻辑。
- **输入**：`input.mp4`、`hybrid_policy.json`、`cloud_result.json`。
- **预期现象**：
  - 由于 2 s 内低置信占比 > 45%，Hybrid 触发并采用 `prefer-cloud-count-then-reconcile` 策略。
  - 最终计数以云端 10 次为准，本地与云端差异 ≤ 2。
  - `evidence.json` 包含云端 cue `cloud:occlusion` 并写入本地快照路径。
  - 性能保持在 RTF 0.92 左右，内存峰值 < 440 MB。
