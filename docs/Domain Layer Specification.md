````md
# 📘 Fitness Self-Management App
# Domain Layer Specification (V1.1)

---

## 0. 文档目标

本规范用于指导 Agent 一次性实现 Domain 层代码，要求：

- 详细、清楚、无歧义
- 可直接生成代码（Dart / Flutter）
- 严格遵守分层：Domain 无 IO，Application 负责编排与持久化
- PR 为可重算计算结果，不是持久化事实

---

# 1. 全局约束

## 1.1 技术栈

- Language: Dart (Flutter)
- 实体风格: **Mutable but Encapsulated**
- DTO / 数据结构: `freezed` + `json_serializable`

---

## 1.2 聚合根风格（强制）

### 封装规则（对所有 Aggregate Root 强制）

- 私有可变字段（`_field`）
- 只读 getter
- 修改必须通过方法
- List 必须返回只读视图（`UnmodifiableListView` 或 `List.unmodifiable`）

### 编辑时间规则（条件适用，强制）

- 若聚合根包含 `lastEditedAtUtc` 字段，则任何会改变聚合状态的操作都必须通过注入的 `nowUtc` 更新该字段

---

## 1.3 时间与日期规则

### DateOnly

- 仅包含年月日
- JSON 格式: `"YYYY-MM-DD"`
- 无时区

### DateTime

- Domain 内部所有 `DateTime` 必须为 **UTC**（`isUtc == true`）
- JSON 输入：
  - 允许 ISO-8601/RFC3339 字符串，必须**显式**包含时区信息（例如 `Z` 或 `+09:00` 等偏移量）
  - 不允许无时区信息的“naive”字符串（例如 `2025-01-01T12:00:00`）
- 进入 Domain 后必须规范化为 UTC（即以同一“瞬间”表达为 UTC）
- JSON 输出：使用 ISO-8601 UTC 字符串（应带 `Z`）

### 禁止

- Domain 层调用 `DateTime.now()`
- 必须通过参数 `nowUtc` 注入时间（且必须为 UTC）

---

## 1.4 ID 规则

- 所有 ID 类型为 `String`
- 由 Application 层生成
- Domain 仅校验非空

建议 typedef：

```dart
typedef LogId = String;
typedef BlockId = String;
typedef ExerciseId = String;
typedef TagId = String;
typedef PlanTemplateId = String;
typedef PlanInstanceId = String;
typedef PlanEntryId = String;
typedef AttachmentId = String;
typedef MilestoneEventId = String;
````

---

# 2. 分层规则

## 2.1 Domain 禁止事项

Domain 层不得包含：

* 数据库操作
* 文件系统访问
* 网络请求
* Flutter UI 代码
* 同步逻辑
* 通知推送

---

## 2.2 Domain 允许事项

* 实体 / 聚合根
* 值对象
* 领域服务（纯计算）
* 校验规则
* 领域异常

---

# 3. 领域异常

统一抛出：

```
class DomainException implements Exception
```

可细分：

* ValidationException
* NotFoundException
* InvariantException

异常必须包含：

* errorCode
* message
* optional context

---

# 4. 核心领域模型

---

# 4.1 WorkoutLog（Aggregate Root）

## 字段

* LogId id
* DateOnly date
* PlanEntryId? boundPlanEntryId
* DateTime createdAtUtc
* DateTime lastEditedAtUtc
* List<LogBlock> blocks（只读视图）

---

## 规则

* 同一天允许多条日志
* 无 publish / finalize 概念
* 保存即持久化 Draft
* 修改必须更新 lastEditedAtUtc（通过注入的 nowUtc）

> 说明：当前 Domain 中 **WorkoutLog 是唯一包含 lastEditedAtUtc 的 Aggregate Root**，因此 1.2 的“编辑时间规则”目前仅对 WorkoutLog 实际适用。

---

## 方法

### Block 操作

* insertBlock(position, block, nowUtc)
* appendBlock(block, nowUtc)
* updateBlock(blockId, newBlock, nowUtc)
* removeBlock(blockId, nowUtc)
* reorderBlocks(fromIndex, toIndex, nowUtc)

---

### Checklist 操作

* toggleChecklistItem(blockId, index, nowUtc)
* addChecklistItem(blockId, text, nowUtc)
* removeChecklistItem(blockId, index, nowUtc)

---

### Exercise Set 操作

* addSet(blockId, set, nowUtc)
* updateSet(blockId, setIndex, set, nowUtc)
* removeSet(blockId, setIndex, nowUtc)

---

### Plan 绑定

* bindPlanEntry(planEntryId, nowUtc)
* unbindPlanEntry(nowUtc)

规则：

* 一个 log 最多绑定一个 PlanEntry
* 必须先解绑才能重新绑定

---

# 4.2 LogBlock（Freezed Union）

Union key 固定为：

```
"type"
```

必须包含：

```
BlockId id
```

---

## Variants

### TextBlock

* id
* text

### HeadingBlock

* id
* text
* level (1–3)

### DividerBlock

* id

### ExerciseBlock

见 4.3

### ImageBlock

* id
* attachments (至少 1)
* caption?

### VideoBlock

* id
* attachments (至少 1)
* caption?

### ChecklistBlock

* id
* items: List<ChecklistItem>

ChecklistItem:

* text
* checked

---

### TimerMarkerBlock

* id
* kind
* atUtc
* label?

TimerKind:

* mark
* rest_start
* rest_end
* custom

---

### ReferenceBlock

* id
* refType
* refId
* previewText?

---

### LinkBlock

* id
* url
* title?
* note?

---

# 4.3 ExerciseBlock

字段：

* id
* exerciseId
* exerciseNameSnapshot
* sets
* note?
* rpe?

规则：

* sets 允许为空
* rpe 0–10

---

# 4.4 SetRecord

字段：

* weightKg >= 0
* reps >= 0
* restSec >= 0 (optional)

有效 set 定义：

```
reps >= 1
```

---

# 4.5 AttachmentRef

字段：

* id
* mediaType (image/video)
* meta?
* createdAtUtc

不存 filePath。

---

# 4.6 Exercise

字段：

* id
* name
* tagIds
* deprecated

规则：

* 不允许 hard delete
* 允许 rename
* 允许 deprecated
* tagIds 去重

---

# 4.7 Tag

字段：

* id
* name

规则：

* 允许 hard delete
* 删除后必须从 Exercise.tagIds 移除

---

# 5. Plan 系统

---

# 5.1 PlanTemplate

字段：

* id
* title
* description?
* type
* cycles (>=1)

---

## PlanCycleDef

* cycleId
* order (从 0 开始)
* startOffsetDays >= 0
* durationDays >= 1
* days

---

## PlanDayDef

* dayIndex
* expectedExercises
* notes?

---

## ExpectedExercise

* exerciseId
* targetSets?
* targetReps?
* targetWeightKg?
* note?

---

# 5.2 PlanInstance

字段：

* id
* templateId
* startDate
* entries
* createdAtUtc

模板修改不影响实例。

---

# 5.3 PlanEntry

字段：

* id
* date
* expectedExercises
* boundLogId?

完成规则：

```
completed = boundLogId != null
```

不存 bool。

---

# 6. 领域服务

---

# 6.1 InsightsService（纯计算）

输入：Iterable<WorkoutLog>

---

## PR 定义

```
PR = max(weightKg)
```

仅统计 reps >= 1 的 set。

---

## Tie-break 规则

1. date 较晚优先
2. lastEditedAtUtc 较晚优先
3. logId 字典序较大优先

---

## 必须实现方法

* currentPRByExercise
* allCurrentPRs
* logVolume
* exerciseVolumeInLog
* maxEstimated1RM

---

## e1RM

默认公式：

```
weight * (1 + reps / 30)
```

仅展示。

---

# 6.2 MilestoneDetector

字段：

* id
* type = "pr"
* exerciseId
* logId
* metricValue
* dedupKey = "pr:${exerciseId}:${logId}"
* createdAtUtc
* deletedAtUtc?

规则：

* changedLogTopWeight > previousMaxWeight 才触发
* 同 dedupKey 只能存在一个
* 若 deletedAtUtc != null，不得重新创建

---

# 7. 非目标

Domain 不实现：

* 同步
* 云端
* 媒体压缩
* 推送
* UI 状态管理

---

# 8. 测试要求

必须覆盖：

* block 编辑
* set 编辑
* PR 计算 + tie-break
* milestone 去重
* PlanEntry completed 推导

```
