# Evidence Pipeline 生成流程

## 阶段 1：选择候选帧

* 输入：离线管线结果 (`angles.csv`, `result.json`)；
* 对每个 rep：
  1. 计算角度偏差（目标 vs 实测）。
  2. 检测异常帧：角度超阈值、节奏异常、关键点遮挡。
  3. 对偏差排序，取前 `topK`。

## 阶段 2：确定片段

* 对每个异常帧，扩展 ±`windowMs/2`；
* 合并重叠窗口 → 输出 `segment` 类型证据。

## 阶段 3：落盘与可视化

* 写入 `evidence.json` 与主文件 `result.json.evidence[]`。
* 若启用 overlay：导出 `overlay.mp4`，绘制关键点、角度标签、cue 文本。
* 性能信息写入 `logs/perf.json.evidence`。

## 阶段 4：cue → 建议映射

* 依据 `rules/cue_advice_map.json` 生成“提示语”，供 UI/日志显示。
