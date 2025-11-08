# Milestone A Alignment Spec (Squat v1) — v1.1

## 0. 版本说明
- **基线来源**：Alignment Spec v1.0 与 Rule Spec v0.1（字段、阈值、容差、错误码）。  
- 本版（v1.1）仅**冻结与细化**里程碑 A 的实现口径，不改变 v1.0 的字段名与冻结阈值。

---

## 1) 输入契约（更新至 vB1.1 格式）
- **关键点文件 (kp.json)**  
  - **格式要求**：必须为 vB1.1 格式（`version: "vB1.1"`）
  - 结构：`{ "version": "vB1.1", "video": {...}, "engine": {...}, "sampling": {...}, "frames": [...] }`
  - **坐标系统**：归一化到 [0,1] 范围（原点左上），`x, y ∈ [0,1]`；`score ∈ [0,1]`
  - **关键点命名**：使用标准名称（snake_case），如 `left_hip`, `right_knee`, `left_ankle`
  - **模型限定（A 阶段）**：仅 **MoveNet17** 的 17 个关键点；BlazePose33 的映射与适配不在 A 阶段对齐范围内
  - 缺点/`score=0`：该点本帧**不参与角度计算**，计入覆盖率统计（见 §5）
  - **注意**：旧格式（`{fps, frames}`）已不再支持（自 Milestone A v1.2 起）  

- **规则文件 (squat.v1.json)**  
  - 字段集：`modelAdapters, phases, counts, metrics, scoreWeights, strictness`；版本：`v1`，含 `relaxed/strict` 两档。

---

## 2) 输出契约（精度/格式冻结）
- **angles.csv**  
  - 表头固定：`t_ms,knee_L,knee_R,trunk_deg`；分隔符 `,`，小数点 `.`，UTF-8 无 BOM。  
  - 单位：度；**精度**：三位小数（统一 round）。  
  - **缺测表示**：当某角度因缺点无法计算时，**对应列留空**（空值），不做插值或前向填充。  

- **result.json**  
  - 字段：  
    - `meta`: `fps, engine, ruleVersion, strictness`  
    - `quality`: `coverage(三位小数), lowConfidence(bool)`  
    - `reps`: 总次数与每次区间  
    - `scores`: `overall, form, stability, tempo`（**一位小数**；统一 round）  
    - `issues`: 违规项（`code, frames, severity`）  
    - `evidence`: 代表帧/最坏帧时间点列表  
  - 其余数值（角度、coverage 等）均保留**三位小数**（统一 round）。

---

## 3) 角度“唯一标准”公式（冻结）
- **knee_L / knee_R**：∠(HIP–KNEE–ANKLE)，范围 `0–180°`。  
- **trunk_deg**：夹角（向量 `shoulder→hip` 与**竖直方向**），**前倾为正**，范围 `0–90°`。  
- **主角度**：`knee_main = min(knee_L, knee_R)`，**所有计数阈值**（如 `minValleyKneeAngle`）均以 `knee_main` 为准。

---

## 4) phases / counts 行为（冻结）
- **相位机**：`phases[*].minMs = 250ms` 作为默认最小持续时间（若规则文件另有指定，以规则为准）；若 Dart 与 Python 存在细微差异，以 Python 脚本输出为“事实标准”。  
- **计数**：按 `Down → Up` 配对，满足 `counts.minIntervalMs` 与 `windowMs`；谷值判断使用 `knee_main` 与 `minValleyKneeAngle`。

---

## 5) 平滑与质量（冻结）
- **平滑**：One Euro 滤波器，参数固定：`min_cutoff=1.0, beta=0.005, d_cutoff=1.0`；按帧率自适应，逐序列独立。  
- **质量阈值**：`quality_th = 0.7`（覆盖率低于阈值**不中断**，仅在 `result.json.quality.lowConfidence=true` 标记）。

---

## 6) 节奏（tempo）口径（冻结）
- **逐 rep 计算**：对每个 `Down–Up`  
  - 计算 **离心时长**（Down）、**向心时长**（Up），得到 `eccentricMs` 与 `ratio = Down/Up`。  
- **聚合**：对所有 reps 取**平均值**作为最终统计。  
- **评分**：若任一 rep 超出阈值区间，按“**偏离程度线性扣分**”；对所有 reps 扣分后取平均，纳入 `tempo` 分。

---

## 7) Freeze 表（沿用 v1.0，重申）
- **counts**：`minValleyKneeAngle: relaxed=90, strict=80`；`minIntervalMs=600`，`windowMs=150`。  
- **metrics**：  
  - `depth.kneeAngleMin`: r=90, s=80  
  - `valgus.kneeOutAngleMin`: r=5, s=10（window=200ms）  
  - `trunk.maxForwardLean`: r=45, s=35  
  - `tempo.eccentricMs`: [600,2000]，`ratio`: [1.0,2.5]  
- **scoreWeights**：`form=0.5, stability=0.25, tempo=0.25`  
- **quality_th**：`0.7`（见 §5）

---

## 8) 精度与容差（沿用 v1.0）
- **reps**：必须一致；仅边缘样本允许 `±1`，需人工复核。  
- **angles.csv**：同序同列，逐点 **MAE ≤ 2°**。  
- **result.json**：`scores` 绝对差 `≤ 2`；`issues/evidence` 时间点容差 `±33ms`。

---

## 9) 错误处理（A 阶段策略冻结）
- **fail-fast**：除 `QUALITY_BELOW_THRESHOLD` 外，**全部错误码**均“立即中断并提示”：  
  - `RULES_PARSE_ERROR`、`MODEL_ADAPTER_MISSING`、`INPUT_KP_INVALID`、`ANGLE_COMPUTE_FAILED`、`COUNTING_INCONSISTENT` → **中断**；  
  - `QUALITY_BELOW_THRESHOLD` → **不中断**，仅在 `result.json.quality.lowConfidence=true` 标记。

---

## 10) 与 Rule Spec 的一致性要求
- 解析器必须覆盖 Rule Spec v0.1 的字段、范围与校验要点（含 `phases.minMs`、`counts.*`、`metrics.*`、`scoreWeights`、`strictness`）。  
- A 阶段仅启用 MoveNet17 的 `modelAdapters.map`；33 点映射保留但不参与对齐。

---
