# AIWA 系统架构（当前分支）

本页记录当前分支的整体系统形态，串联本地离线分析、移动端推理、云端扩展以及支撑文档，便于在不同交付场景下快速定位职责与依赖。

## 1. 组件全景

```
┌───────────────────────────────────────────────────────────────────────┐
│                              AIWA 平台                               │
├──────────────────┬────────────────────────┬───────────────────────────┤
│ 终端推理层       │ 核心分析与工具层       │ 云端扩展层                │
│ (Flutter/Dart)   │ (纯 Dart)              │ (Node/Infra)              │
├──────────────────┼────────────────────────┼───────────────────────────┤
│ • aiwa_app       │ • aiwa_core            │ • aiwa_cloud / docs/07    │
│   - UI/主题      │   - OfflinePipeline    │   - Core API, S3, SQS     │
│   - Pose Engines │   - 规则/计数/质量     │   - Worker Contracts      │
│   - Cloud API    │ • aiwa_cli             │                           │
│ • aiwa_runner    │   - 命令行入口         │                           │
│   - 帧抽取/镜像  │   - 性能预算守护       │                           │
└──────────────────┴────────────────────────┴───────────────────────────┘
```

- **aiwa_app**：面向终端用户，封装姿态引擎选择、证据降级策略和云端 API 客户端。
- **aiwa_runner**：在移动端/模拟器中批量处理视频帧，调用核心离线流水线并导出结果。
- **aiwa_core**：实现姿态序列过滤、角度计算、计数、质量评估及证据生成，是离线与云端的共享内核。【F:aiwa_core/lib/pipeline/offline_pipeline.dart†L1-L200】
- **aiwa_cli**：面向开发/验收的命令行工具，包装 `aiwa_core` 并提供性能守护与多项输出检查。【F:aiwa_cli/bin/aiwa_cli.dart†L1-L160】
- **aiwa_cloud**：提供会话管理、资产存储与后台推理的服务化实现，详细结构见云端文档。【F:docs/07-cloud/ARCHITECTURE_OVERVIEW.md†L1-L133】

## 2. 核心模块职责

### aiwa_core — 离线分析内核
- `OfflinePipeline` 负责关键点过滤、角度计算、阶段分段、计数和质量评估，并导出 `angles.csv` 与结构化 `result.json` 证据。【F:aiwa_core/lib/pipeline/offline_pipeline.dart†L22-L199】
- 统一的规则模型 (`RuleSet`)、严格度配置和指标阈值支撑不同强度的训练场景。【F:aiwa_core/lib/pipeline/offline_pipeline.dart†L89-L145】

### aiwa_cli — 命令行与验收工具
- 作为 Dart CLI 入口，直接依赖 `aiwa_core` 的 IO、姿态序列和规则解析模块，提供关键点解析、规则加载与性能计时。【F:aiwa_cli/bin/aiwa_cli.dart†L10-L57】
- 内建性能守护：监控实时性、内存、温度，并在严格模式下触发告警或退出码，用于端到端验收。【F:aiwa_cli/bin/aiwa_cli.dart†L65-L156】

### aiwa_runner — 移动端离线编排器
- 管理应用工作目录、输入/规则/日志结构，并在内部与外部存储之间同步素材与结果，便于调试与 `adb pull`。【F:aiwa_runner/lib/runner_orchestrator.dart†L62-L134】
- 负责任务调度：枚举帧、调用 ML Kit 推理、构建中立关键点序列并交由 `OfflinePipeline` 生成证据。【F:aiwa_runner/lib/runner_orchestrator.dart†L136-L200】

### aiwa_app — 终端应用
- 通过 `PoseEngineFactory` 选择不同的姿态引擎（ML Kit / MoveNet / Auto），统一暴露 `PoseEngine` 接口供 UI 与服务层使用。【F:aiwa_app/lib/pose/pose_engine_factory.dart†L1-L86】
- `EvidenceResolver` 根据协议降级策略解析快照或时间窗，确保 UI 可以容错展示训练证据。【F:aiwa_app/lib/adapters/evidence_resolver.dart†L1-L106】
- `ApiClient` 统一处理云端 API 的鉴权、请求头、超时与错误封装，为会话上传和结果拉取提供基础设施。【F:aiwa_app/lib/services/api_client.dart†L1-L120】

### aiwa_cloud — 云平台交付
a. **Core API Service**：暴露 `/v1/auth`, `/v1/sessions`, `/v1/jobs`，使用 JWT 进行会话管理并协调 S3 资产与 SQS 任务队列。
b. **Worker Services**：`REINFER` 与 `ADVICE` Worker 从队列消费任务，产出云端推理结果。
c. **存储与数据库**：Supabase PostgreSQL 存储用户/作业状态，S3 保存关键点、视频与分析结果，DLQ 保障失败任务可追踪。
> 详细结构见云端架构图及组件边界说明。【F:docs/07-cloud/ARCHITECTURE_OVERVIEW.md†L1-L133】

## 3. 数据流

### 3.1 离线分析流程
1. **素材准备**：`aiwa_runner` 将视频与规则复制到工作空间，并定位内部/外部帧目录，缺失时提示先抽帧。【F:aiwa_runner/lib/runner_orchestrator.dart†L76-L153】
2. **姿态推理**：通过 ML Kit 逐帧推理生成中立关键点，统计推理耗时与质量指标。【F:aiwa_runner/lib/runner_orchestrator.dart†L166-L200】
3. **核心计算**：`OfflinePipeline` 滤波关键点 → 角度计算 → 阶段分段 → 次数统计 → 质量指标 → 证据汇总，最终输出 `angles.csv` 与 `result.json`。【F:aiwa_core/lib/pipeline/offline_pipeline.dart†L29-L199】
4. **命令行模式**：`aiwa_cli` 复用相同管线，扩展性能守护、导出目录和退出码体系，便于自动化 CI 验证。【F:aiwa_cli/bin/aiwa_cli.dart†L31-L156】

### 3.2 云端协同流程
1. 移动 App 通过 `ApiClient` 完成鉴权、上传关键点/视频至 S3（预签名 URL），并在 Core API 中创建/更新 Session。
2. Core API 将任务投递至 SQS，`REINFER` / `ADVICE` Worker 处理后将结果写回 S3，并更新数据库状态。
3. App 轮询或推送获取云端增强结果，与本地离线结果合并呈现。
> 详细时序、权限与安全边界参考云端架构文档。【F:docs/07-cloud/ARCHITECTURE_OVERVIEW.md†L98-L133】

## 4. 部署与运行模式
- **本地开发**：使用 `aiwa_cli` 调试规则与关键点数据，结合 docs/05-testing 的端到端计划执行 CI 验收。
- **移动离线**：`aiwa_runner` 与 `aiwa_app` 的离线路径共享 `aiwa_core` 内核，确保移动端无需网络即可完成一次完整分析。
- **云端增强**：当需同步至后端或获取 AI 建议时，通过 `aiwa_app` 的 API 客户端接入 `aiwa_cloud` 服务，并遵守 docs/protocols 的 schema 与错误处理规范。【F:aiwa_app/lib/services/api_client.dart†L1-L120】【F:docs/protocols/ui_contracts.md†L1-L120】

## 5. 协议与输出契约
- 证据降级策略与 UI 契约：`EvidenceResolver` 按 `docs/protocols/ui_contracts.md` 解析快照/时间窗，保证前端一致性。【F:aiwa_app/lib/adapters/evidence_resolver.dart†L1-L106】
- 结果与性能 Schema：位于 `docs/protocols/schemas/`，在 CLI、App 与云端间共享，确保导出的 `result.json`、性能指标具备验证依据。

## 6. 仓库目录速览
- `aiwa_core/`：核心算法、规则与测试。
- `aiwa_cli/`：CLI 入口与默认配置。
- `aiwa_app/`：Flutter 应用（UI、服务、适配器、主题）。
- `aiwa_runner/`：Milestone B 离线 Runner。
- `aiwa_cloud/`：部署脚本、Core API、Worker 规范。
- `docs/`：文档中心（参见 [docs/README.md](../README.md)）。

如需扩展或替换某一层，请在对应模块补充文档并更新本页，保持架构信息同步。
