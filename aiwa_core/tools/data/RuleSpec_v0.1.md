# Rule Spec v0.1（规则规范说明书）

## 1. 元信息
- **id**: 字符串；规则唯一标识（例："squat.v1"）。
- **version**: 字符串；语义化版本（例："1.0"）。
- **metadata**: { name, author, updatedAt }。

## 2. 模型适配（modelAdapters）
- **movenet17.map**: 语义名 → 17 点索引。
- **blazepose33.map**: 语义名 → 33 点索引。
- **fallbacks**: 可选；缺点/低置信度时的替代方案。

> 语义点集合（最小集）：肩、髋、膝、踝、肘、腕 + 鼻/耳（可选）。

## 3. 阶段定义（phases[]）
- **name**: 阶段名（Squat 用 "Up"、"Down"）。
- **enter**: 进入条件（角度变化、阈值 crossing）。
- **exit**: （可选）退出条件，默认由下一阶段触发。
- **minMs**: 阶段最短持续时间（默认 250ms）。

## 4. 计数规则（counts）
- **sequence**: 合法阶段顺序（["Down","Up"]）。
- **minValleyKneeAngle**: 谷值膝角阈值（宽松/严苛）。
- **minIntervalMs**: 相邻 reps 最小间隔（默认 600ms）。
- **windowMs**: 谷值/峰值确认窗口（默认 ±150ms）。

## 5. 指标与阈值（metrics）
每个指标都有 relaxed / strict 两档：
- **depth**: 膝角最小值。
- **valgus**: 膝外展角或双膝距/髋宽比。
- **trunk**: 躯干前倾角。
- **tempo**: 离心:向心比与时长。

## 6. 评分权重（scoreWeights）
- `{ form:0.5, stability:0.25, tempo:0.25 }`

## 7. 证据与提示
- **evidence**: 需导出证据的指标列表。
- **cues**: { primary: 主建议, secondary: [次建议…] }

## 8. 严苛度包（strictness）
- **relaxed / strict**：覆盖 metrics 与 counts 的阈值。

## 9. 输入/输出约定（里程碑 A）
- **输入**：`kp.json` + `video.mp4`
- **输出**：`angles.csv`、`result.json`
- **质量阈值**：覆盖率 < 0.7 标记低可信。

---

# 字段校验清单（Checklist）

### A. 结构级
- [ ] `id` 非空且唯一；`version` 语义化。
- [ ] `metadata.name/author/updatedAt` 完整。
- [ ] 两个 `map` 覆盖所需语义点。
- [ ] `phases` ≥ 2 且与 `counts.sequence` 对齐。

### B. 语义/范围
- [ ] `phases[*].minMs ≥ 200`。
- [ ] `counts.minIntervalMs ≥ 500`。
- [ ] 阈值对 (relaxed, strict) 正确且宽松 ≥ 严苛。
- [ ] 角度 ∈ [0, 180]。
- [ ] `tempo` 参数合理。
- [ ] `evidence` 指标必须存在于 `metrics` 中，总帧数 ≤ 6。
- [ ] `cues.primary` 非空。

### C. 模型映射与回退
- [ ] 所有语义名在两个 `map` 中均有条目或有退化策略。

### D. 输出一致性
- [ ] `angles.csv` 含时间戳与角度。
- [ ] `result.json` 字段齐备。
- [ ] 覆盖率 < 0.7 → `lowConfidence: true`。

---

# 关键点语义映射表

## MoveNet（17 点）
| 语义名          | 索引 |
|-----------------|------|
| NOSE            | 0    |
| LEFT_EYE        | 1    |
| RIGHT_EYE       | 2    |
| LEFT_EAR        | 3    |
| RIGHT_EAR       | 4    |
| LEFT_SHOULDER   | 5    |
| RIGHT_SHOULDER  | 6    |
| LEFT_ELBOW      | 7    |
| RIGHT_ELBOW     | 8    |
| LEFT_WRIST      | 9    |
| RIGHT_WRIST     | 10   |
| LEFT_HIP        | 11   |
| RIGHT_HIP       | 12   |
| LEFT_KNEE       | 13   |
| RIGHT_KNEE      | 14   |
| LEFT_ANKLE      | 15   |
| RIGHT_ANKLE     | 16   |

## BlazePose（33 点）
| 语义名          | 索引 |
|-----------------|------|
| NOSE            | 0    |
| LEFT_EYE_INNER  | 1    |
| LEFT_EYE        | 2    |
| LEFT_EYE_OUTER  | 3    |
| RIGHT_EYE_INNER | 4    |
| RIGHT_EYE       | 5    |
| RIGHT_EYE_OUTER | 6    |
| LEFT_EAR        | 7    |
| RIGHT_EAR       | 8    |
| MOUTH_LEFT      | 9    |
| MOUTH_RIGHT     | 10   |
| LEFT_SHOULDER   | 11   |
| RIGHT_SHOULDER  | 12   |
| LEFT_ELBOW      | 13   |
| RIGHT_ELBOW     | 14   |
| LEFT_WRIST      | 15   |
| RIGHT_WRIST     | 16   |
| LEFT_PINKY      | 17   |
| RIGHT_PINKY     | 18   |
| LEFT_INDEX      | 19   |
| RIGHT_INDEX     | 20   |
| LEFT_THUMB      | 21   |
| RIGHT_THUMB     | 22   |
| LEFT_HIP        | 23   |
| RIGHT_HIP       | 24   |
| LEFT_KNEE       | 25   |
| RIGHT_KNEE      | 26   |
| LEFT_ANKLE      | 27   |
| RIGHT_ANKLE     | 28   |
| LEFT_HEEL       | 29   |
| RIGHT_HEEL      | 30   |
| LEFT_FOOT_INDEX | 31   |
| RIGHT_FOOT_INDEX| 32   |
