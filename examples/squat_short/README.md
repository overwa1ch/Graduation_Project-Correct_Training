# squat_short 样本

- **类别**：性能样本
- **目的**：验证超短素材 (< 5 s) 时的启动开销与降级逻辑。
- **输入**：`input.mp4`（4 s，30 fps）。
- **预期现象**：
  - 管线在 4 s 内完成，`pipelineRtf` 约 0.55。
  - 由于帧数不足，`reps` 仅返回 2 次，`coverage` 约 0.88。
  - `perf.json` 中 `timingsMs.load` 占比较高，用于监控冷启动成本。
