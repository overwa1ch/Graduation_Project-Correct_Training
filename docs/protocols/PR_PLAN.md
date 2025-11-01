# PR_PLAN.md

**Suggested PR Structure for Phase 4 Functional Integration**
**Version:** v1.1 *(以实际实现为准)*

---

### PR1 — CLI Runner & Event Flow

* 实现 `event_bus.dart`（`Process.start` + JSONL 解析 + 广播流）
* Camera 状态随事件更新
  **DoD:** `PROGRESS` 正常推进，`DONE` 能进入解析

### PR2 — Analysis Adapter & Pop-up Binding

* `result_adapter.dart` 字段映射
* 绑定到 Pop-up 展示
  **DoD:** 分数/次数/证据渲染正确

### PR3 — Settings Persistence

* `config_sync.dart` 读写 `aiwa_app/configs/app_runtime.json`
* 校验 `configs_snapshot.json` 一致
  **DoD:** 设置生效并被快照

### PR4 — Error Handling & Fallbacks

* 引入错误码 → UI 行为（参见 `ERROR_TO_ACTION.md`）
* 增加“重试/查看日志/清理空间/片段回退”
  **DoD:** 三类主失败能优雅处理

### PR5 — Session Management

* `build/offline_out/<sessionId>` 管理与按天清理
  **DoD:** 历史可打开，清理可用

### PR6 — Minimal Tests

* 适配层 / 配置持久化 / 事件流 三类最小测试
  **DoD:** 本地绿灯；不设覆盖率门槛

### PR7 — Lightweight CI Checks

* 样本结果与 schema 校验；文档 schema 变更需样本同步
  **DoD:** 破坏契约即 CI fail；不影响日常迭代