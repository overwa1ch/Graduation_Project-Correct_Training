# Evidence Pipeline E2E 测试计划

## 样本集

* 深蹲（正常 / 轻微偏差 / 明显错误）
* 遮挡样本（低置信度）
* 快速节奏样本（节奏异常）

## 验证项

1. `evidence.json` 格式符合 Schema；
2. `overlay.mp4` 可播放且帧数与事件数匹配；
3. 每个 rep 至少一条 cue；
4. `cue_advice_map.json` 匹配正确，UI 可读；
5. 性能指标写入 `logs/perf.json`。

## 验收标准

* 全部校验 PASS；
* 每个异常 rep 至少产生 1 条 evidence；
* 无冗余 cue；
* overlay 导出性能满足预算。
