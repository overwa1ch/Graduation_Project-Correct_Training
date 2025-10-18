# Hybrid 校验规则

- 若 `hybrid.triggered=true`：必须存在 `reason[]`、`cloud_payload.json`、`hybrid_diff.json`。
- 若导出 `overlay.mp4`：其长度应 ≈ `(endMs-startMs) ± 1s`。
- `evidence[].snapshotPath` 可解析时间锚点。
- 新增 Schema 校验：字段类型正确、数值范围合理。
- CI 检查：Hybrid 流程新增耗时 <10%；payload 体积 ≤5MB。
