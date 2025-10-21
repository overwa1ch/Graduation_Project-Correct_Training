# Squat Normal Sample

- **类别**：正常样本
- **目的**：验证标准光照、标准姿势下的完整离线流程与输出格式。
- **输入**：30 fps 日光环境视频 (`input.mp4`)，包含 10 次完整深蹲。
- **预期**：
  - CLI 生成 `expected/` 目录中的四个黄金产物（`result.json`、`angles.csv`、`evidence.json`、`perf.json`）。
  - `hybrid.triggered` 为 `false`，代表未触发云端兜底。
  - 评分应稳定在 90 分以上，节奏均衡。
  - 质量覆盖率高于 0.92，低置信帧占比 < 5%。
- **验证脚本**：使用 `aiwa_agent run milestoneE_test_generation --verify-schema` 对应项可以直接 PASS。
