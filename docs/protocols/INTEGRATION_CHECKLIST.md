# INTEGRATION_CHECKLIST.md

**Phase 4 Integration Checklist (Normal Functional Implementation)**
**Version:** v1.1 *(以实际实现为准)*
**CLI Command:** `dart run aiwa_cli/bin/aiwa_cli.dart`
**App Config Path:** `aiwa_app/configs/app_runtime.json`

---

## 1️⃣ CLI Invocation & Event Stream

**Action:**

* 桌面用 `Process.start('dart',['run','aiwa_cli/bin/aiwa_cli.dart', ...])` 监听 stdout JSON Lines。
* 移动端用 Isolate 跑 `aiwa_core`，事件对象同 stdout 结构。
* 统一封装为 `Stream<Map>` 供 UI 订阅。

**Deliverables**

* `aiwa_app/lib/services/event_bus.dart` *(实际实现文件)*

**DoD**

* Camera 页能显示 `PROGRESS` 与 `PHASE`，`DONE` 触发解析流程。

---

## 2️⃣ Artifact Parsing & Adapter Layer

**Action**

* 解析 `result.json` 并映射：

  * `form→posture`，`stability→stability`，`tempo→rhythm`，`overall→total`，`repCount→reps`
  * `evidence[0].snapshotPath→evidencePath`；为空时回退到 `window.startMs~endMs` 片段

**Deliverables**

* `aiwa_app/lib/adapters/result_adapter.dart` *(实际实现文件)*

**DoD**

* Pop-up 正常展示分数、次数与证据（图片或片段二选一）。

---

## 3️⃣ Runtime Configuration (Settings)

**Action**

* 表单写入 `aiwa_app/configs/app_runtime.json`（遵循 `app_runtime_v1.schema.json`）。
* CLI 以 `--config` 读取；生成 `configs_snapshot.json` 归档。

**Deliverables**

* `aiwa_app/lib/services/config_sync.dart` *(实际实现文件)*

**DoD**

* 下一次分析的 `configs_snapshot.json` 与 UI 设置一致。

---

## 4️⃣ Error Handling & Recovery

**Action**

* 将 `ERROR.code` 映射为 UI 行为；提供“重试/查看日志/清理空间”。
* `snapshotPath` 为空 → 回放 `window` 片段；空间不足 → 一键清理历史会话。

**Deliverables**

* 错误处理逻辑分散在 `aiwa_app/lib/ui/pages/camera_page.dart` 等页面中
* （可选）`docs/protocols/ERROR_TO_ACTION.md` *(已实现)*

**DoD**

* 人为制造：CLI 启动失败 / 无证据 / 空间不足，均能被优雅处理并可重试。

---

## 5️⃣ Session Management

**Action**

* 会话目录：`build/offline_out/<sessionId>`；保留最近 N 次；按 `cleanup.days` 自动清理。

**Deliverables**

* `aiwa_app/lib/services/session_manager.dart` *(实际实现文件)*

**DoD**

* 历史列表可打开结果；过期会话自动清理不影响新分析。

---

## 6️⃣ Minimum Contract Tests

**Action**

* 最小化契约测试（不过度追求覆盖率）：

  1. `result_adapter_test.dart`：字段映射 & 证据回退
  2. `config_sync_test.dart`：读写与必填校验
  3. `event_bus_jsonl_test.dart`：事件顺序与关键字段存在

**Deliverables**

* 三个小测试 + `events_sample.jsonl`

**DoD**

* 三测通过即可；不设覆盖率门槛。

---

## 7️⃣ Lightweight CI Safeguards

**Action**

* CI 校验一个 `result.sample.json` 与 schema 的一致性。
* 如变更 `docs/protocols/schemas/*`，需附带通过校验的样本。

**Deliverables**

* CI 说明片段（YAML 集成指引）

**DoD**

* 破坏契约的改动 CI 直接失败；不拖慢正常合并。

---

**End of Checklist**

---
