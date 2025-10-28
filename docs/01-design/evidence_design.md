# 🧩 证据化（Evidence Pipeline）规范与配置资产库

---

## 1️⃣ 设计说明

**目标**：为离线管线输出增加可复核的证据（Evidence）层，使评分和动作判定具备"可解释、可回放、可核查"的依据。

**范围**：

* B1 证据帧与片段选择（EvidenceSelector）
* B2 证据数据落盘与结构定义
* B3 overlay 导出（可选）
* B4 cue→建议映射表（规则引擎对接）

**原则**：

* 与 vB1.1 输出完全兼容，增量字段放入 `evidence[]`。
* 所有证据均以时间戳为锚点，可追溯至关键帧或 overlay 视频。
* 不新增模型，只利用离线管线已有的角度、相位、计数、评分信息。

**核心理念**：

* 证据化 = "数据记录 + 解释可视 + 复核一致"。
* 保持统一的关键点语义（中立 33 点）。
* 仅在推理完成后生成证据，不参与实时判定。

---

## 2️⃣ 证据生成策略配置

参见 `configs/evidence_config.json`。

---

## 3️⃣ 证据数据契约

参见 `schemas/evidence_data_contract.json`。

---

## 4️⃣ 证据生成流程文档

参见 `docs/evidence_pipeline.md`。

---

## 5️⃣ cue→建议映射表

参见 `rules/cue_advice_map.json`。

---

## 6️⃣ 校验规则

参见 `checks/evidence_validation_rules.md`。

---

## 7️⃣ 性能与隐私预算

参见 `docs/evidence_perf_privacy_budget.md`。

---

## 8️⃣ 测试计划

参见 `tests/evidence_e2e_plan.md`。

---

## 9️⃣ CLI 参数扩展

参见 `docs/CLI_使用与参数说明.md`。

---

## ✅ 验收标准（Definition of Done）

1. 文档与配置齐全（上列 9 项产出完整）。
2. CLI 执行后生成 `evidence.json` 与可选 `overlay.mp4`。
3. `result.json` 中包含 `evidence[]` 字段，格式通过 Schema 校验。
4. 校验脚本通过、性能预算满足。
5. 全链路可复核（cue→advice→视频帧）。



