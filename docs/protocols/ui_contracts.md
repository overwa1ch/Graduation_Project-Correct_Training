# ui_contracts.md
**Version:** v2.0  
**Purpose:** Flutter 前端状态机、字段映射、错误提示与交互约定。

---

## 字段映射（实际 result.json → UI 模型）

| UI 字段 | CLI 字段 | 说明 |
|----------|-----------|------|
| posture | scores.form | 姿势得分 |
| stability | scores.stability | 稳定性得分 |
| rhythm | scores.tempo | 节奏得分 |
| total | scores.overall | 综合得分 |
| reps | repCount | 动作次数 |
| evidencePath | evidence[0].snapshotPath 或回放片段 | 证据图/片段路径 |

---

## 状态机

| 状态 | 条件 | UI 表现 |
|------|------|----------|
| idle | 初始 | 等待输入 |
| preparing | 收到 START | 显示视频元信息 |
| running | PHASE/PROGRESS/METRIC | 更新进度条与提示 |
| parsing | DONE | 解析文件中 |
| success | result.json 就绪 | 弹窗展示结果 |
| error | ERROR | 显示错误详情 |

---

## 质量提示
- lowConfidence == true → 黄条提示
- coverage < 0.7 → 黄条提示

---

## 分数色带
- <60 红，60~79 黄，≥80 绿

---

## 证据降级策略
- 若 snapshotPath 为空：以 window.startMs/endMs 为回放片段
- 若 evidence 数组为空：显示占位图并提示“无证据片段”

---

## 错误码映射
| code | 提示 |
|------|------|
| 401_UNAUTH | 登录失效，请重新登录 |
| 422_SCHEMA_MISMATCH | 版本不匹配，请更新 |
| 500_INFER_FAIL | 推理失败，请重试 |
