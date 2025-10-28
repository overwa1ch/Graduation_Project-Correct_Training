# AIWA 项目文档中心

欢迎查阅 AIWA（AI Workout Assistant）项目文档中心。本目录包含了项目的所有技术文档，按照阶段和功能进行了分类整理。

---

## 📚 文档目录结构

### 00-project/ - 项目总体文档
项目架构、总结和核心说明文档

- **[architecture.md](00-project/architecture.md)** - AIWA 项目系统架构
  - 系统架构图、CI/CD 流程图、数据流图
  - 目录结构树、组件依赖关系
  - 测试架构、技术栈层次
  
- **[project_summary.md](00-project/project_summary.md)** - AIWA 项目完成总结
  - 项目概览、完成任务清单
  - 项目统计、文档索引
  - 技术栈、最佳实践、项目成就
  
- **[agents.md](00-project/agents.md)** - 项目说明（AIWA Squat Offline Pipeline）
  - 项目概述、包结构
  - 安装与运行、构建指南
  - 目录结构、技术栈、贡献指南

---

### 01-design/ - 设计文档
核心算法与流程设计说明

- **[evidence_design.md](01-design/evidence_design.md)** - 证据化（Evidence Pipeline）规范
  - 设计说明、证据生成策略
  - 数据契约、生成流程
  - cue→建议映射表、验收标准
  
- **[hybrid_design.md](01-design/hybrid_design.md)** - Hybrid 占位流程设计
  - 触发器、上行路径、合并策略
  - 关键指标定义、触发判定规则
  - 上行包约束、性能预算、隐私策略
  
- **[evidence_pipeline.md](01-design/evidence_pipeline.md)** - 证据生成流程详细文档
  
- **[merge_rules.md](01-design/merge_rules.md)** - 合并规则说明
  
- **[perf_privacy_budget.md](01-design/perf_privacy_budget.md)** - 性能与隐私预算
  
- **[evidence_perf_privacy_budget.md](01-design/evidence_perf_privacy_budget.md)** - 证据流程性能与隐私预算

---

### 02-specifications/ - 规范与契约
项目规范、Schema 定义和边界约定

- **[schema_milestone_b.md](02-specifications/schema_milestone_b.md)** - Milestone B 输出规范文档（vB1.1）
  - neutral_keypoints.json Schema
  - result.json 增量字段
  - 输出目录规范、校验清单
  
- **[alignment_contract.md](02-specifications/alignment_contract.md)** - 对齐契约
  - 关键点语义对齐规范
  
- **[rule_spec_v0.1.md](02-specifications/rule_spec_v0.1.md)** - 规则规范 v0.1
  
- **[theme_boundary_compliance.md](02-specifications/theme_boundary_compliance.md)** - 主题边界合规性
  
- **[quick_start_boundary.md](02-specifications/quick_start_boundary.md)** - 快速开始边界约定

---

### 03-guides/ - 使用指南
安装、配置和使用教程

- **[cli_usage.md](03-guides/cli_usage.md)** - Hybrid & Evidence CLI 使用与参数说明
  - Hybrid 参数、Evidence 参数
  - 控制台输出格式、输出文件
  
- **[environment_config.md](03-guides/environment_config.md)** - 环境变量配置指南
  - 快速开始、详细配置说明
  - Supabase 配置示例、安全建议
  - 常见问题解答
  
- **[tools_quick_start.md](03-guides/tools_quick_start.md)** - 工具快速开始指南

---

### 04-reports/ - 完成报告
项目各阶段完成报告和总结

- **[ci_cd_complete.md](04-reports/ci_cd_complete.md)** - CI/CD 完成报告
  
- **[tokens_sync_complete.md](04-reports/tokens_sync_complete.md)** - Tokens 同步完成报告
  
- **[figma_theme_complete.md](04-reports/figma_theme_complete.md)** - Figma 主题完成报告
  
- **[figma_theme_generation_summary.md](04-reports/figma_theme_generation_summary.md)** - Figma 主题生成总结
  
- **[figma_mcp_test_results.md](04-reports/figma_mcp_test_results.md)** - Figma MCP 测试结果
  
- **[nav_implementation_report.md](04-reports/nav_implementation_report.md)** - 导航实现报告
  
- **[final_acceptance_report.md](04-reports/final_acceptance_report.md)** - 最终验收报告
  
- **[implementation_summary.md](04-reports/implementation_summary.md)** - 实现总结
  
- **[sync_tokens_report.md](04-reports/sync_tokens_report.md)** - Tokens 同步报告
  
- **[theme_generation_report.md](04-reports/theme_generation_report.md)** - 主题生成报告

---

### 05-testing/ - 测试文档
端到端测试计划和测试规范

- **[hybrid_e2e_plan.md](05-testing/hybrid_e2e_plan.md)** - Hybrid 端到端测试计划
  
- **[evidence_e2e_plan.md](05-testing/evidence_e2e_plan.md)** - Evidence 端到端测试计划

---

### 06-validation/ - 验证规则
数据验证和质量检查规则

- **[validation_rules.md](06-validation/validation_rules.md)** - 验证规则
  
- **[evidence_validation_rules.md](06-validation/evidence_validation_rules.md)** - Evidence 验证规则

---

### 07-cloud/ - 云端相关
云端平台相关文档

- **[project_phase_summary.md](07-cloud/project_phase_summary.md)** - 云端平台阶段性总结
  - 项目架构搭建、核心功能实现
  - 数据库设计、UI/UX 设计
  - 项目完成度评估
  
- **[file_organization.md](07-cloud/file_organization.md)** - 云端项目文件整理清单
  - 已删除/修改/新增文件列表
  - 项目文件结构、整理效果
  - 安全性提升、项目健康度检查
  
- **[cloud_app_readme.md](07-cloud/cloud_app_readme.md)** - 云端应用 README

---

## 🗂️ 其他资源

### 示例数据
- `cloud_mock_examples/` - 云端模拟数据示例
  - `cloud_conflict.json` - 冲突场景示例
  - `cloud_extra.json` - 额外数据示例
  - `cloud_refine.json` - 细化结果示例

### 配置契约
- `cloud_payload_contract.json` - 云端负载契约定义

---

## 📖 快速导航

### 🚀 新手入门
1. [项目说明](00-project/agents.md) - 了解项目概述
2. [架构文档](00-project/architecture.md) - 理解系统架构
3. [CLI 使用指南](03-guides/cli_usage.md) - 开始使用 CLI
4. [环境配置](03-guides/environment_config.md) - 配置开发环境

### 🔧 开发参考
1. [Schema 规范](02-specifications/schema_milestone_b.md) - 数据格式规范
2. [Evidence 设计](01-design/evidence_design.md) - 证据流程设计
3. [Hybrid 设计](01-design/hybrid_design.md) - 混合流程设计
4. [验证规则](06-validation/validation_rules.md) - 数据验证规则

### 📊 项目状态
1. [项目总结](00-project/project_summary.md) - 总体完成情况
2. [完成报告](04-reports/) - 各阶段完成报告
3. [测试计划](05-testing/) - 测试覆盖情况

---

## 📝 文档维护

### 文档更新原则
- **准确性**：确保文档与代码实现保持同步
- **完整性**：覆盖所有重要的功能和配置
- **可读性**：使用清晰的语言和结构化的格式
- **时效性**：及时更新文档以反映最新变更

### 文档分类标准
- **00-project**：项目级别的总体文档
- **01-design**：算法和流程的设计文档
- **02-specifications**：规范、Schema 和契约
- **03-guides**：面向用户的使用指南
- **04-reports**：阶段性完成报告
- **05-testing**：测试相关文档
- **06-validation**：验证规则和检查清单
- **07-cloud**：云端平台专属文档

---

## 🔗 相关链接

- 主项目 README：[../README.md](../README.md)
- aiwa_core：[../aiwa_core/](../aiwa_core/)
- aiwa_cli：[../aiwa_cli/](../aiwa_cli/)
- aiwa_app：[../aiwa_app/](../aiwa_app/)
- 配置文件：[../configs/](../configs/)
- Schema 定义：[../schemas/](../schemas/)
- 示例数据：[../examples/](../examples/)

---

## ❓ 获取帮助

如果您在使用文档时遇到问题：

1. 查看相关章节的"常见问题"部分
2. 检查示例代码和配置文件
3. 参考项目 README 中的"贡献指南"
4. 联系项目维护者

---

**文档整理日期**：2025年10月28日  
**文档版本**：v1.0  
**维护者**：AIWA 项目团队



