# squat_normal 样本

- **类别**：正常样本
- **目的**：验证离线管线在标准光照和规范动作下的主流程、输出格式与证据生成。
- **输入**：`neutral_keypoints.json`（vB1.1 规范）。
- **预期现象**：
  - 关键点置信度稳定，无 Hybrid 触发。
  - 计数为 12 次，整体得分 ≥ 88。
  - `perf.json` 中 `pipelineRtf` < 0.9 且 `memPeakMB` < 420。
- **校验提示**：运行 `python tools/validate_examples.py --schema vB1.1 --manifest examples/examples_manifest.json` 应通过。
