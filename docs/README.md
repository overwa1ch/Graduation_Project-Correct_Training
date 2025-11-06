# AIWA 项目文档中心

欢迎查阅 AIWA（AI Workout Assistant）项目文档中心。本目录收录了项目的全部设计、规范、实施与运维资料，并按照主题分类，便于在不同交付阶段快速检索。

---

## 🗂️ 目录导航

### 00-project / project — 项目基础档案
- **[project/architecture.md](project/architecture.md)**：当前分支的整体系统架构、组件边界与数据流向。
- **[00-project/project_summary.md](00-project/project_summary.md)**：阶段性交付总结、完成事项与统计。
- **[00-project/agents.md](00-project/agents.md)**：AIWA Squat Offline Pipeline 的项目说明、依赖与目录索引。

### 01-design — 设计文档
- **[evidence_design.md](01-design/evidence_design.md)**：证据化（Evidence Pipeline）设计规范。
- **[hybrid_design.md](01-design/hybrid_design.md)**：Hybrid 占位流程设计说明。
- **[evidence_pipeline.md](01-design/evidence_pipeline.md)**：证据生成流程细节。
- **[merge_rules.md](01-design/merge_rules.md)**：合并规则说明。
- **[perf_privacy_budget.md](01-design/perf_privacy_budget.md)**、**[evidence_perf_privacy_budget.md](01-design/evidence_perf_privacy_budget.md)**：性能与隐私预算。

### 02-specifications — 规范与契约
- **[schema_milestone_b.md](02-specifications/schema_milestone_b.md)**：Milestone B 输出规范。
- **[alignment_contract.md](02-specifications/alignment_contract.md)**：关键点语义对齐契约。
- **[rule_spec_v0.1.md](02-specifications/rule_spec_v0.1.md)**：规则规范。
- **[theme_boundary_compliance.md](02-specifications/theme_boundary_compliance.md)**、**[quick_start_boundary.md](02-specifications/quick_start_boundary.md)**：主题与快速开始边界约定。

### 03-guides — 安装与使用指南
- **[cli_usage.md](03-guides/cli_usage.md)**：Hybrid & Evidence CLI 参数说明。
- **[environment_config.md](03-guides/environment_config.md)**：环境变量配置指南与常见问题。
- **[tools_quick_start.md](03-guides/tools_quick_start.md)**、**[tool_quick_start.md](03-guides/tool_quick_start.md)**：工具快速开始。
- **[movenet_quick_start.md](03-guides/movenet_quick_start.md)**、**[event_bus_quick_start.md](03-guides/event_bus_quick_start.md)**：关键子系统使用指南。
- **[config_sync_guide.md](03-guides/config_sync_guide.md)**、**[adapters_guide.md](03-guides/adapters_guide.md)**：配置同步与适配器使用说明。

### 04-reports — 交付与验收报告
- 核心功能实现：如 **[cancellation_token_implementation_report.md](04-reports/cancellation_token_implementation_report.md)**、**[movenet_implementation.md](04-reports/movenet_implementation.md)** 等。
- 页面/功能实现：如 **[analysis_history_implementation.md](04-reports/analysis_history_implementation.md)**、**[pages_optimization_summary.md](04-reports/pages_optimization_summary.md)**。
- 服务与适配器交付：如 **[services_implementation_summary.md](04-reports/services_implementation_summary.md)**、**[adapters_delivery.md](04-reports/adapters_delivery.md)**。
- 其他阶段报告：如 **[ci_cd_complete.md](04-reports/ci_cd_complete.md)**、**[figma_theme_generation_summary.md](04-reports/figma_theme_generation_summary.md)**。

### 05-testing — 测试计划与结果
- **[COMPLETE_TESTING_REPORT.md](05-testing/COMPLETE_TESTING_REPORT.md)**：全量测试报告。
- **[TEST_SUMMARY_PHASE3.md](05-testing/TEST_SUMMARY_PHASE3.md)**：Phase 3 测试总结与覆盖率。
- **[evidence_e2e_plan.md](05-testing/evidence_e2e_plan.md)**、**[hybrid_e2e_plan.md](05-testing/hybrid_e2e_plan.md)**：端到端测试计划。

### 06-validation — 验证规则
- **[validation_rules.md](06-validation/validation_rules.md)**：通用验证规则。
- **[evidence_validation_rules.md](06-validation/evidence_validation_rules.md)**：证据流程专用验证。

### 07-cloud — 云平台交付
- **[ARCHITECTURE_OVERVIEW.md](07-cloud/ARCHITECTURE_OVERVIEW.md)**：云端架构与组件边界。
- **[CLOUD_CORE_API.md](07-cloud/CLOUD_CORE_API.md)**：核心 API 说明。
- **[WORKER_CONTRACT.md](07-cloud/WORKER_CONTRACT.md)**、**[DATA_SCHEMAS.md](07-cloud/DATA_SCHEMAS.md)**：云端工人协议与数据结构。
- **[PLAN_VALIDATION_REPORT.md](07-cloud/PLAN_VALIDATION_REPORT.md)**、**[project_phase_summary.md](07-cloud/project_phase_summary.md)**：阶段总结与上线计划。

### perf — 性能预算
- **[BUDGET.md](perf/BUDGET.md)**：性能指标、设备分级与预算。

### protocols — 协议与对接契约
- **[readme.md](protocols/readme.md)**：协议合集索引。
- **[ERROR_TO_ACTION.md](protocols/ERROR_TO_ACTION.md)**、**[INTEGRATION_CHECKLIST.md](protocols/INTEGRATION_CHECKLIST.md)**：集成与异常处理规范。
- **schemas/**：结果、性能、运行时等 JSON Schema 定义。

### 根目录与其他文档
- **[USER_GUIDE.md](USER_GUIDE.md)**：最终用户使用说明。
- **[RELEASE_NOTES.md](RELEASE_NOTES.md)**：版本变更与发布记录。
- **[ORGANIZATION_SUMMARY.md](ORGANIZATION_SUMMARY.md)**：组织交付摘要。
- 统一取消令牌架构实施报告、Figma 主题总结等补充材料位于仓库根目录。

---

如需新增文档，请按上述分类将文件放置到对应目录，并在本索引中同步更新，确保团队成员可快速定位。
