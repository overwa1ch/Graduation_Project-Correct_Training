# Hybrid 合并规则说明

1. **匹配方式**：rep 中心时间最近匹配，容差 ≤ 200ms。
2. **计数合并**：
   - |Δcount| ≤ 1 → 采用 cloud；
   - 否则回退 local 并记录 `reconcileNote`。
3. **相位边界**：差异 ≤ 阈值采用 cloud；否则保留 local。
4. **质量项合并**：cloud cue 加 `cloud:` 前缀写入 `evidence.cues[]`。
5. **评分修正**：端侧主导，可对 cloud bad cue 附加惩罚因子（仅文档化）。
6. **最终输出**：更新 `result.json` 中 `hybrid{}` 字段。
