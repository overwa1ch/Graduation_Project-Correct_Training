# Hybrid 占位流程设计说明

## 目标
在端侧完成 Hybrid 流程的判定与占位，为后续云端增强预留数据钩子；不依赖真实网络，不改动原始评分模型。

## 范围
- A1 触发器（TriggerEvaluator）
- A2 上行路径占位（CloudPayloadBuilder）
- A3 合并策略（HybridMerger）
- A4 UI/状态占位（数据层）

## 原则
- 不破坏 vB1.1 Schema 的向后兼容性。
- 所有增量字段以 `hybrid{}` 和 `evidence[]` 为命名空间。
- 端侧流程在性能与隐私预算内完成；任何视频片段导出均需审计。

## 关键指标定义
| 指标 | 说明 | 计算口径 |
| --- | --- | --- |
| coverage | conf ≥ 阈值 的关键点占比 | 全序列平均 |
| lowConfPct | 低置信帧比例 | 满足低置信条件帧数 / 总帧数 |
| jitterPx | 去趋势后关键点帧间位移 RMS | 全局均值 |
| fps | 帧率中位数 | 时间戳差分倒数中位 |

## 触发判定规则
- 采用可配置策略文件 (`hybrid_policy.json`)；
- 按引擎差异化；
- 可选综合评分（加权计算）；
- 若任意规则命中或综合分数低于阈值 → 触发。

## 上行包约束
- 关键点优先，视频片段可选；
- 体积 ≤ 5MB；视频 ≤10s，≤15fps；
- 落盘文件 `cloud_payload.json` 与 `payload_audit.json` 必须一致。

## 合并策略
- 匹配方式：以 rep 中心时间做一维匹配，容差 200ms；
- 优先级：count → cloud，phase → cloud_if_within_threshold，否则 local；
- 回退逻辑：差异过大写入 `reconcileNote` 并回退端侧。

## 性能预算
- 触发计算 O(N)；
- 打包与合并不超过离线管线总耗时的 10%；
- 性能日志写入 `logs/perf.json`。

## 隐私策略
- 默认 `privacy=keypoints_only`；
- 若包含视频，则审计文件中需记录 `consent=true` 与体积信息。



