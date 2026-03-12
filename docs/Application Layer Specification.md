---

# 📘 Fitness Self-Management App

# Application Layer Specification (V1.1 — Final / Agent-Safe)

> 本规范为最终可执行版本。
> 用于指导 `fit_application` 模块实现与未来扩展。
> 已结合实现修复项、单元测试与事务规则进行反向校准。
> 与当前文档版本一致 

---

# 1. 设计目标

Application 层是系统的**编排层（Orchestration Layer）**。

它：

* 不包含业务规则（规则在 Domain）
* 不包含 IO 实现（在 Infra）
* 负责事务边界
* 负责时间注入
* 负责跨聚合协作
* 负责 DTO 输出
* 负责 Milestone 触发

---

# 2. 分层强约束

## 2.1 依赖方向（不可违反）

```
UI → UseCase → (Service) → Ports → Domain
```

禁止：

* UI 直接访问 Repository
* UI 直接访问 Service
* Application 访问 Infra 实现类
* Application 重写 Domain 规则

---

# 3. UseCase 规范（强制）

## 3.1 统一接口

```dart
abstract interface class UseCase<I, O> {
  Future<O> execute(I input);
}
```

---

## 3.2 UseCase = 事务边界

* 一个 UseCase = 一个完整业务意图
* 所有跨 Repository 写操作必须在 UnitOfWork 内
* 不允许部分成功

---

# 4. 时间与 ID 规范

## 4.1 Clock（强制 UTC）

```dart
abstract class Clock {
  DateTime nowUtc();
}
```

### 强制规则：

* 所有写用例必须调用 `clock.nowUtc()`
* 必须断言 `isUtc == true`
* 不允许使用 `DateTime.now()`

若违反：

```dart
throw ApplicationException("Clock must return UTC time");
```

---

## 4.2 IdGenerator

```dart
abstract class IdGenerator {
  String newId();
}
```

Domain 不生成 ID。

---

# 5. 异常规范

允许：

* DomainException（原样抛出）
* ApplicationException

禁止：

* 返回 null 表示失败
* 吞异常
* 把异常转字符串

---

## 5.1 NotFoundException 规则（强制 errorCode）

当 repo.findById == null：

必须抛：

```dart
throw NotFoundException(
  errorCode: "WORKOUT_LOG_NOT_FOUND",
);
```

固定 errorCode 列表：

* WORKOUT_LOG_NOT_FOUND
* PLAN_ENTRY_NOT_FOUND
* EXERCISE_NOT_FOUND
* TAG_NOT_FOUND
* PLAN_TEMPLATE_NOT_FOUND
* PLAN_INSTANCE_NOT_FOUND

---

# 6. UnitOfWork

```dart
abstract class UnitOfWork {
  Future<T> runInTransaction<T>(Future<T> Function() action);
}
```

---

## 6.1 强制使用场景

必须使用 UoW：

* BindPlanEntryUseCase
* UnbindPlanEntryUseCase
* DeleteTagUseCase
* 所有会保存 Milestone 的用例

---

## 6.2 事务语义（写入规范）

若 transaction 内发生异常：

* 不允许产生部分写入
* InMemory 实现必须支持回滚测试

---

# 7. Repository Ports（完整清单）

## 7.1 WorkoutLogRepository

```dart
abstract class WorkoutLogRepository {
  Future<WorkoutLog?> findById(LogId id);
  Future<List<WorkoutLog>> findByDate(DateOnly date);
  Future<List<WorkoutLog>> findAll();
  Future<void> save(WorkoutLog log);
  Future<void> delete(LogId id);
}
```

---

## 7.2 ExerciseRepository

```dart
abstract class ExerciseRepository {
  Future<Exercise?> findById(ExerciseId id);
  Future<List<Exercise>> findAll();
  Future<void> save(Exercise exercise);
}
```

---

## 7.3 TagRepository

```dart
abstract class TagRepository {
  Future<Tag?> findById(TagId id);
  Future<List<Tag>> findAll();
  Future<void> save(Tag tag);
  Future<void> delete(TagId id);
}
```

---

## 7.4 PlanTemplateRepository

```dart
abstract class PlanTemplateRepository {
  Future<PlanTemplate?> findById(PlanTemplateId id);
  Future<List<PlanTemplate>> findAll();
  Future<void> save(PlanTemplate template);
  Future<void> delete(PlanTemplateId id);
}
```

---

## 7.5 PlanInstanceRepository

```dart
abstract class PlanInstanceRepository {
  Future<PlanInstance?> findById(PlanInstanceId id);
  Future<List<PlanInstance>> findAll();
  Future<void> save(PlanInstance instance);
  Future<void> delete(PlanInstanceId id);
}
```

---

## 7.6 PlanEntryRepository

```dart
abstract class PlanEntryRepository {
  Future<PlanEntry?> findById(PlanEntryId id);
  Future<List<PlanEntry>> findByDate(DateOnly date);
  Future<void> save(PlanEntry entry);
}
```

---

## 7.7 MilestoneRepository

```dart
abstract class MilestoneRepository {
  Future<MilestoneEvent?> findByDedupKey(String dedupKey);
  Future<void> save(MilestoneEvent event);
}
```

必须支持：

* deletedAtUtc != null 时不允许重建

---

# 8. DTO 规范

## 8.1 DTO 禁止

* 不得包含 Domain 聚合根
* 不得包含可变 List
* 不得包含行为方法

---

## 8.2 LogEditorDTO

必须包含：

* id
* date
* boundPlanEntryId
* createdAtUtc
* lastEditedAtUtc
* List<BlockDTO>

BlockDTO = freezed union（10 种类型）

禁止添加 filePath。

---

## 8.3 PRSummaryDTO

```dart
class PRSummaryDTO {
  List<ExercisePRDTO> prs;
  DateTime computedAtUtc;
}
```

---

## 8.4 ExercisePRDTO

必须字段：

* exerciseId
* prWeightKg
* achievedOnDate
* achievedInLogId

可选：

* exerciseName
* exerciseNameSnapshot

---

## 8.5 BindPlanResultDTO

必须字段：

* logId
* planEntryId
* isBound
* atUtc

---

# 9. PR 与 Milestone 规则（最终版）

## 9.1 PR 来源

必须调用 Domain InsightsService。

规则：

* reps >= 1
* max(weightKg)
* tie-break：date → lastEditedAtUtc → logId

---

## 9.2 Milestone 触发条件

必须：

```
changedLogTopWeight > previousMaxWeight
```

dedupKey:

```
"pr:${exerciseId}:${logId}"
```

---

## 9.3 baseline 计算（必须基于修改前状态）

baseline 必须基于：

* logBefore 状态
* 全量 logs

严禁用 logAfter 回算 baseline。

---

## 9.4 触发范围优化（新增强约束）

只有修改 ExerciseBlock sets 的用例才触发 Milestone 计算。

以下用例不触发：

* TextBlock 编辑
* Checklist 编辑
* Divider 编辑
* Reorder 不涉及 set 的变更

---

## 9.5 去重规则

若：

* existing == null → 创建
* existing.deletedAtUtc == null → 禁止重复
* existing.deletedAtUtc != null → 禁止重建

---

# 10. UseCase 清单（完整）

必须实现：

* CreateWorkoutLogUseCase
* InsertBlockUseCase
* AppendBlockUseCase
* UpdateBlockUseCase
* RemoveBlockUseCase
* ReorderBlocksUseCase
* ToggleChecklistItemUseCase
* AddChecklistItemUseCase
* RemoveChecklistItemUseCase
* AddSetUseCase
* UpdateSetUseCase
* RemoveSetUseCase
* BindPlanEntryUseCase（UoW）
* UnbindPlanEntryUseCase（UoW）
* CreateExerciseUseCase
* RenameExerciseUseCase
* DeprecateExerciseUseCase
* CreateTagUseCase
* RenameTagUseCase
* DeleteTagUseCase（UoW）
* GetCurrentPRSummaryUseCase

---

# 11. Services（可选）

允许：

* LogMutationTemplate
* MilestoneWriter
* DtoMapper

禁止：

* UI 访问
* new Repository 实现

---

# 12. 测试要求（必须通过）

## 必须包含：

1. Block 编辑更新 lastEditedAtUtc
2. AddSet → PR 正确
3. Milestone 去重
4. deletedAtUtc != null 不重建
5. BindPlanEntry 原子性
6. NotFound errorCode 正确
7. UTC 断言测试

---

# 13. 验收标准

当：

* 无 DateTime.now()
* 所有写用例使用 clock.nowUtc()
* 所有事务正确使用 UoW
* PR 与 Milestone 行为符合规则
* DTO 无 Domain 泄漏
* 单元测试全部通过

Application 层视为合格。

---

# ✅ 本版本状态

* 已覆盖 11 项实现修复点
* 已补齐 Repository 缺口
* 已强化事务与 baseline 规则
* 已强化 UTC 强制断言
* 已强化触发范围约束
* 已可作为 V1.1 Final 基线

---
