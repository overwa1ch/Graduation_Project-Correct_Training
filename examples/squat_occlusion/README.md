# Squat Occlusion Sample

- **类别**：异常样本
- **目的**：验证在低光与遮挡条件下 Hybrid 触发与云端合并逻辑是否正确。
- **输入**：
  - 遮挡视频 (`input.mp4`)
  - 混合触发策略 (`hybrid_policy.json`)
  - 云端推理 mock (`cloud_result.json`)
- **预期**：
  - 本地覆盖率低于阈值时触发 `hybrid.triggered == true`。
  - `hybrid.mergeStrategy` 固定 `prefer-cloud-count-then-reconcile`。
  - 最终 `repCount` 取云端计数并提供 `delta` 说明。
  - `expected/perf.json` 记录性能退化与回传耗时。
- **验证脚本**：`aiwa_agent run milestoneE_test_generation --verify-schema --generate-mock`。
