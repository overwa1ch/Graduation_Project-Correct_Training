# Squat Tempo Irregular Sample

- **类别**：节奏样本
- **目的**：验证快慢节奏交替与停顿时，评分与节奏统计是否稳定。
- **输入**：关键点时间序列 (`neutral_keypoints.json`)，人工注入长停顿与急速下蹲。
- **预期**：
  - `tempo` 分数下降但整体计数不受影响。
  - `evidence` 列出节奏异常帧，`issues` 包含 `TEMPO_VARIATION` 提示。
  - `perf.json` 近似正常样本，因为样本帧数有限。
- **验证脚本**：`aiwa_agent run milestoneE_test_generation --verify-schema --generate-mock`。
