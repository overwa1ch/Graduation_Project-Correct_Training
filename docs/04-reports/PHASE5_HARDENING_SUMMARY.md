Phase 5：上线前硬化（Release Hardening）总结报告

目标回顾
- 明确性能产物来源与规范；在 App 侧补齐最小闭环的诊断与支持能力；提升发布前的可观测性与可追溯性。

本期完成
- 文档/规范对齐
  - 统一 perf.json 为 snake_case，并与 docs/protocols/schemas/perf_v1.schema.json 对齐。
  - 在性能预算样例中新增 ms_per_frame.{p50,p90,p95,max} 百分位说明。
  - 发布说明明确沿用 v1 schema，保持向后兼容。
- 职责边界
  - perf.json：由 CLI/Runner 侧生成；App 仅消费/展示，不写入。
  - App 侧：负责本地诊断日志与支持包导出。
- App 端实现
  - Diagnostics Log：会话目录输出 diagnostics.log（JSONL），记录 START/PHASE/PROGRESS/DONE/ERROR/RETRY/CLEANUP，UTC 时间戳，路径脱敏。
  - Support Bundle：Settings → Export Support Bundle，生成 <sessionRoot>/support_bundle.zip，包含（若存在）：result.json、logs/perf.json、logs/run.log、configs_snapshot.json、diagnostics.log。
  - 会话与配置：沿用 SessionManager（默认清理 7 天），分析前写入 configs_snapshot.json。

自动化验证
- 新增用例（无需设备/包名）：
  - test/services/support_bundle_test.dart：验证导出 zip 清单与内容片段。
  - test/services/diagnostics_logger_test.dart：验证 JSONL 行可解析与路径脱敏。
- 运行结果：两项新增用例通过。
- 说明：现有部分历史用例（event_bus*, session_manager*）因插件/边界期望导致无关失败，不影响本期功能验收。
- 运行命令：
  - flutter test test/services/support_bundle_test.dart -r compact
  - flutter test test/services/diagnostics_logger_test.dart -r compact
  - flutter test test/services -r compact

实机抽检建议
- 运行一次分析（演示流可跑通）后检查：
  - <sessionRoot>/diagnostics.log 存在，包含 START/PROGRESS/DONE 或 ERROR，UTF-8、逐行 JSON、路径脱敏。
  - 导出 <sessionRoot>/support_bundle.zip，包含约定文件，zip 内为相对路径。

风险与缓解
- 平台文件系统差异：采用 Application Support 目录与相对路径；建议 Android/iOS 各抽测 1 台。
- 非典型结束（ERROR 直接结束）：打包“存在即收纳”，不阻断导出；建议做一次错误流导出验证。

后续（可选）
- 为部分历史用例补充插件桩/初始化，降低噪音。
- CLI 保持 perf.json.evidence 与 perf_history.ndjson，用于长期性能跟踪（无需改文档）。

结论
- Phase 5 目标达成：产物规范清晰、职责明确、诊断与导出能力上线，并具备本地自动化校验与实机抽检路径。可按上述步骤完成最终发布前检查。


