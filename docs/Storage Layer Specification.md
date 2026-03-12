# 📘 Fitness Self-Management App
# Storage Layer Specification (V1.1 — Agent-Safe)

> 本规范用于指导 `fit_storage` 模块实现。
> 严格对齐：
>
> - Domain Layer Specification (V1.1) :contentReference[oaicite:0]{index=0}
> - Application Layer Specification (V1.1 Final) :contentReference[oaicite:1]{index=1}
> - 项目重构建议（包含 fit_storage 职责定位） :contentReference[oaicite:2]{index=2}
>
> Storage 层负责：
>
> - 本地数据库
> - Repository Ports 实现
> - UnitOfWork 实现
> - 媒体文件管理
> - 备份导出
>
> Storage 不包含业务规则，不重写 Domain 逻辑。

---

# 1. 分层定位

## 1.1 依赖方向（强制）
UI → Application → Domain

↑

Storage（实现 Ports + IO）

```

Storage：

- ✅ 实现 Application 定义的 Repository Ports
- ✅ 实现 UnitOfWork
- ✅ 实现 MediaStore
- ❌ 不得包含业务规则
- ❌ 不得修改 Domain 不变量
- ❌ 不得生成时间（必须来自 Application）

---

# 2. 技术栈（V1.1 强制）

## 2.1 数据库

- SQLite
- Drift
- 单数据库文件：`fit.sqlite`

原因：

- 事务支持良好
- 可迁移
- 可测试
- 与 UnitOfWork 语义匹配 :contentReference[oaicite:3]{index=3}

---

## 2.2 文件存储

- `dart:io`
- `path_provider`
- `path`
- 媒体存储在 App sandbox 内

---

## 2.3 Zip 导出

- `archive` 包
- 生成 `backup.zip`

---

# 3. 模块结构
```

aiwa_core/fit_storage/

lib/

fit_storage.dart

src/

db/

fit_database.dart

tables_*.dart

repositories/

workout_log_repo.dart

exercise_repo.dart

tag_repo.dart

plan_template_repo.dart

plan_instance_repo.dart

plan_entry_repo.dart

milestone_repo.dart

uow/

drift_unit_of_work.dart

media/

media_store.dart

backup/

backup_service.dart

errors/

storage_exception.dart

utils/

utc_codec.dart

json_codec.dart

```

---

# 4. 数据编码规则（强制对齐 Domain）

依据 Domain 时间规则 :contentReference[oaicite:4]{index=4}

---

## 4.1 DateOnly

- 存储为 TEXT
- 格式：`YYYY-MM-DD`
- 允许按字典序排序

---

## 4.2 DateTime（UTC）

- 必须为 ISO-8601 UTC 字符串
- 必须带 `Z`
- 读入后必须 `isUtc == true`
- Storage 不得生成时间

---

## 4.3 JSON 存储策略

- 聚合根完整 JSON 作为事实来源
- 可冗余索引字段（date、name 等）
- 不允许反向从索引字段重建对象

---

# 5. 数据库 Schema（V1.1）

- `schemaVersion = 1`
- 默认不启用 SQLite 外键约束（弱引用策略） :contentReference[oaicite:5]{index=5}

---

# 6. 表定义

---

## 6.1 workout_logs

| 字段 | 类型 | 说明 |
|------|------|------|
| id | TEXT PK | |
| date | TEXT | DateOnly |
| bound_plan_entry_id | TEXT NULL | |
| created_at_utc | TEXT | |
| last_edited_at_utc | TEXT | |
| json | TEXT | 完整 JSON |

索引：

- index(date)
- index(bound_plan_entry_id)
- index(last_edited_at_utc)

排序规则：

- findByDate → created_at_utc ASC, id ASC

---

## 6.2 exercises

| 字段 | 类型 |
|------|------|
| id | TEXT PK |
| name | TEXT |
| deprecated | INTEGER |
| json | TEXT |

索引：

- index(deprecated)
- index(name)

不允许 hard delete（Domain 规则） :contentReference[oaicite:6]{index=6}

---

## 6.3 tags

| 字段 | 类型 |
|------|------|
| id | TEXT PK |
| name | TEXT |
| json | TEXT |

---

## 6.4 plan_templates

| 字段 | 类型 |
|------|------|
| id | TEXT PK |
| title | TEXT |
| type | TEXT |
| json | TEXT |

---

## 6.5 plan_instances

| 字段 | 类型 |
|------|------|
| id | TEXT PK |
| template_id | TEXT |
| start_date | TEXT |
| created_at_utc | TEXT |
| json | TEXT |

---

## 6.6 plan_entries

| 字段 | 类型 |
|------|------|
| id | TEXT PK |
| plan_instance_id | TEXT |
| date | TEXT |
| bound_log_id | TEXT NULL |
| json | TEXT |

约束：
```

UNIQUE(plan_instance_id, date)

```

---

## 6.7 milestones

| 字段 | 类型 |
|------|------|
| id | TEXT PK |
| dedup_key | TEXT UNIQUE |
| type | TEXT |
| exercise_id | TEXT |
| log_id | TEXT |
| metric_value | REAL |
| created_at_utc | TEXT |
| deleted_at_utc | TEXT NULL |
| json | TEXT |

UNIQUE(dedup_key) 强制去重 :contentReference[oaicite:7]{index=7}

---

## 6.8 attachments

| 字段 | 类型 |
|------|------|
| id | TEXT PK |
| media_type | TEXT |
| created_at_utc | TEXT |
| relative_path | TEXT |
| thumbnail_relative_path | TEXT NULL |
| byte_size | INTEGER |
| sha256 | TEXT NULL |
| meta_json | TEXT NULL |

AttachmentRef 不存 filePath（对齐 Domain） :contentReference[oaicite:8]{index=8}

---

# 7. Repository 实现规则

对齐 Application Ports :contentReference[oaicite:9]{index=9}

---

## 7.1 通用规则

- findById → 不存在返回 null
- save → upsert
- delete → 只删当前表
- JSON 解析失败 → 抛 DB_JSON_CORRUPTED

---

## 7.2 PlanInstanceRepository 保存规则

必须在同一事务：

1. upsert instance
2. delete 所有 entries
3. 全量 insert entries

---

## 7.3 MilestoneRepository

- 冲突抛 DB_CONSTRAINT_VIOLATION
- 不做业务判断

---

# 8. UnitOfWork

对齐 Application 接口 :contentReference[oaicite:10]{index=10}

```dart
abstract class UnitOfWork {
  Future<T> runInTransaction<T>(Future<T> Function() action);
}
```

---

## 8.1 Drift 实现

- 使用 drift transaction
- 异常回滚
- 不吞异常

---

## 8.2 InMemory 实现（测试）

- Map 存储
- 开始事务时深拷贝
- 异常恢复快照

---

# 9. MediaStore 规范

## 9.1 目录结构

```
fit_storage/
  db/
  media/
    objects/
    thumbs/
```

子目录规则：

- 使用 attachmentId 前两位分片

---

## 9.2 API

```dart
abstract class MediaStore {
  Future<void> importFromFile(...);
  Future<File> openObjectFile(String attachmentId);
  Future<File> openThumbnailFile(String attachmentId);
  Future<void> deleteAttachment(String attachmentId);
}
```

---

## 9.3 强制规则

- 先写文件再写索引
- 失败抛 MEDIA_WRITE_FAILED
- 不写绝对路径
- 不返回 filePath 给 DTO（Application 禁止）

---

# 10. BackupService

对齐项目建议中的导出策略

---

## 10.1 导出结构

```
backup.zip
  manifest.json
  db/fit.sqlite
  media/...
```

---

## 10.2 API

```dart
abstract class BackupService {
  Future<File> exportBackupZip({
    required Directory targetDir,
    String? fileName,
  });
}
```

---

# 11. StorageException

```dart
class StorageException implements Exception {
  final String errorCode;
  final String message;
  final Map<String, Object?> context;
}
```

errorCode 固定：

- DB_OPEN_FAILED
- DB_MIGRATION_FAILED
- DB_JSON_CORRUPTED
- DB_CONSTRAINT_VIOLATION
- MEDIA_WRITE_FAILED
- MEDIA_NOT_FOUND
- BACKUP_EXPORT_FAILED

---

# 12. 测试要求

必须覆盖：

1. JSON round-trip
2. 排序稳定性
3. 事务回滚
4. Milestone UNIQUE
5. Media import/open/delete
6. Backup zip 包含 manifest/db/media

---

# 13. 非目标

Storage 不实现：

- 云同步
- PR 计算（PR 必须通过 Domain InsightsService）
- UI
- 通知
- 同步冲突处理

---

# ✅ V1.1 验收标准

当：

- 所有 Repository Ports 实现完成
- 所有写操作通过 UnitOfWork
- DateTime 全为 UTC
- Attachment 不泄漏路径
- Backup 正常导出
- 单元测试全部通过

Storage 层视为合格。