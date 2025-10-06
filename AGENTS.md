# 项目说明（AIWA Squat Offline Pipeline）

## 1. 项目概述
- 本仓库包含 Dart 实现的 **AIWA Milestone A** 离线动作分析管线，主要用于解析人体关键点序列、按规则集计算深蹲等动作的次数与质量指标，并生成 CSV/JSON 报告。
- 核心流程：CLI 接收关键点与规则 JSON，调用 `OfflinePipeline` 对数据做滤波、角度计算、动作分段与质量评估，最终输出打分证据与汇总。
- 附带 `tools/` 目录提供 Python 基线脚本与规则、关键点示例数据，便于对照与调试。

## 2. 安装、环境变量、运行与构建
- **基础环境**：需要 [Dart SDK](https://dart.dev/get-dart) ≥ 3.4。安装后请确保 `dart` 命令在 `PATH` 中，或手动设置：
  ```bash
  export DART_SDK="/path/to/dart-sdk"
  export PATH="$DART_SDK/bin:$PATH"
  ```
- **依赖安装**：
  ```bash
  cd aiwa_milestone_a
  dart pub get
  ```
- **运行 CLI**（默认使用测试夹带样例，可通过参数覆盖）：
  ```bash
  dart run bin/aiwa_cli.dart \
    --keypoints path/to/kp.json \
    --rule path/to/rule.json \
    --strictness relaxed \
    --out build/offline_out
  ```
- **构建本地可执行文件**：
  ```bash
  dart compile exe bin/aiwa_cli.dart -o build/aiwa_cli
  ```
- **测试**：
  ```bash
  dart test
  ```
- 若需要在工具链中安装 Node 相关依赖，请使用 `pnpm` 替换 `npm`（例如 `pnpm install`），仓库当前未提供前端依赖。

## 3. 目录结构、路由与接口
- **整体结构**：
  ```
  aiwa_milestone_a/
  ├── bin/                # CLI 入口（aiwa_cli.dart）
  ├── lib/
  │   ├── core/           # 错误类型、IO 与取整工具
  │   ├── math/           # 欧拉滤波、角度计算等数学模块
  │   ├── pipeline/       # 离线分析主流程与计数、分段、质量评估
  │   ├── pose/           # 关键点模型与 MoveNet 适配
  │   ├── result/         # CSV/JSON 导出工具
  │   └── spec/           # 规则模型、解析与 JSON Schema
  ├── test/               # 单元测试与夹带数据
  ├── tools/
  │   ├── data/           # 示例关键点、规则、对齐说明
  │   └── python_baseline.py
  └── pubspec.*           # Dart 包配置
  ```
- **前端/页面路由**：项目不包含前端代码，也不存在页面路由。如果需要集成前端，请自行在独立目录中创建并通过 `pnpm` 管理依赖。
- **API 接口**：当前实现为离线 CLI 工具，不暴露 HTTP/REST API。输入通过文件（关键点 JSON、规则 JSON）提供，输出生成 `angles.csv` 与 `result.json`；如需服务化，可在此基础上封装。

## 4. 技术栈与依赖
- **语言与工具**：Dart 3、ArgParser（命令行参数解析）、`dart test` 单元测试框架。
- **核心依赖**：
  - `args`：解析 CLI 参数。
  - `collection`：集合扩展功能。
  - `json_annotation` / `json_serializable`：规则与关键点模型的 JSON 序列化。
  - `csv`：生成角度 CSV 输出。
  - `build_runner`：配合 `json_serializable` 的代码生成。
- **工具脚本**：`tools/python_baseline.py` 提供 Python 参考实现，便于结果对比。

## 5. 贡献与注意事项
- 修改或新增前端脚本时，请使用 `pnpm` 管理依赖并在相关目录补充说明。
- 运行 `dart test` 确认新增逻辑的稳定性；若涉及代码生成，请执行 `dart run build_runner build --delete-conflicting-outputs` 并提交生成文件。
- 确保 CLI 入参与输出路径在文档或 README 中更新，以便团队成员快速复现。
