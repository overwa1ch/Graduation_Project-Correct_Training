# Squat Short Sample

- **类别**：性能样本（超短）
- **目的**：验证超短素材下的吞吐、启动时间与降级逻辑。
- **输入**：约 3 秒视频 (`input.mp4`)，仅包含 2 次半 squat 动作。
- **预期**：
  - CLI 正确生成空/部分 rep 的结果并填充性能统计。
  - `rtf` 需明显低于 1，展示超短素材的实时能力。
  - `issues` 允许为空，但 `perf.json.timingsMs.startup` 应记录冷启动成本。
- **验证脚本**：`aiwa_agent run milestoneE_test_generation --export-json`。
