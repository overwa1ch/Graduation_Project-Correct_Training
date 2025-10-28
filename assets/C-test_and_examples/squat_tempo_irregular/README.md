# squat_tempo_irregular 样本

- **类别**：节奏样本
- **目的**：验证忽快忽慢节奏对评分与证据的影响。
- **输入**：`input.mp4`（含长停顿与爆发加速段）。
- **预期现象**：
  - Tempo 子分数下降至 78 左右，并输出节奏异常 evidence。
  - `issues` 中出现 `tempo-inconsistent`，定位在加速区间。
  - Pipeline 仍保持稳定，`pipelineRtf` ≈ 0.81。
