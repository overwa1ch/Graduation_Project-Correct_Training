# 项目说明（AIWA Squat Offline Pipeline）

## 1. 项目概述
- 仓库现拆分为三个 Dart/Flutter 包：
  - `aiwa_core`：纯 Dart 核心逻辑（关键点解析、滤波、角度计算、计数、评分等）。
  - `aiwa_cli`：纯 Dart 命令行工具，调用 `aiwa_core` 处理离线关键点 JSON。
  - `aiwa_app`：Flutter 应用，集成 ML Kit 推理与 UI，可直接依赖 `aiwa_core` 复用算法。
- 仍附带 `tools/` 目录（位于 `aiwa_core/tools`）提供 Python 基线脚本与规则、关键点示例数据，便于对照与调试。

## 2. 安装、环境变量、运行与构建
- **基础环境**：需要 [Dart SDK](https://dart.dev/get-dart) ≥ 3.4。安装后请确保 `dart` 命令在 `PATH` 中，或手动设置：
  ```bash
  export DART_SDK="/path/to/dart-sdk"
  export PATH="$DART_SDK/bin:$PATH"
  ```
- **核心与 CLI 依赖安装**：
  ```bash
  cd aiwa_core
  dart pub get

  cd ../aiwa_cli
  dart pub get
  ```
- **CLI 运行方式**（仅文件模式；视频/引擎推理请切到 Flutter 工程）：
  ```bash
  cd aiwa_cli
  dart run bin/aiwa_cli.dart \
    --keypoints ../aiwa_core/test/fixtures/kp_sample.json \
    --rule ../aiwa_core/test/fixtures/squat.v1.json \
    --out-dir build/offline_out \
    --log-level info \
    --evidence topK=8 windowMs=1500
  ```
- **云端增强示例**：仓库附带 `aiwa_cli/mocks/cloud_result.json`，可直接作为 `--cloud-mock` 的输入进行合并演示。
- **关键参数速查**：
  - `--hybrid`：启用混合触发；默认关闭。若打开需同时提供 `--hybrid-policy`（默认 `./configs/hybrid_policy.json`）。
  - `--cloud-mock <path>`：引入云端增强模拟 JSON，可与 `--hybrid` 独立使用，用于验证合并流程。
  - `--evidence [key=value]`：开启证据化并传入参数，支持 `topK`（默认 6）、`windowMs`（默认 1200）、`exportOverlay`（默认 false，可自动降级）。
  - `--dry-run`：仅做参数/配置校验，不执行推理与导出。
  - `--strict` / `--fail-on-warn`：严格模式，校验失败返回退出码 3；可选将 WARN 视为失败。
  - `--log-level`：`trace|debug|info|warn|error`，默认 `info`。
  - `--output-format`：校验汇总输出格式 `human|json|junit|all`，默认 `human`。
  - `--out-dir`：覆盖输出根目录，默认 `./offline_out`。
  - `--version` / `--help`：查看版本、帮助信息。
- **互斥/依赖提醒**：
  - CLI 仅支持 `--keypoints` 文件输入；`--video` 会直接报错提醒使用 Flutter 构建。
  - `--hybrid` 打开时必须能读取 `--hybrid-policy`，且 JSON 需符合 `configs/hybrid_policy.json` 的 C-augment 结构。
  - `--cloud-mock` 会进入合并路径，即使未打开 `--hybrid` 亦可演示云端增强。
  - 当 `--evidence exportOverlay=true` 且本地缺失 `ffmpeg` 时会自动降级为 `false` 并给出 WARN。
- **退出码语义**：`0` 成功；`1` 参数/配置错误；`2` 运行时错误；`3` 校验失败（严格模式下）。
- **构建本地可执行文件**：
  ```bash
  cd aiwa_cli
  dart compile exe bin/aiwa_cli.dart -o build/aiwa_cli
  ```
- **核心单元测试**：
  ```bash
  cd aiwa_core
  dart test
  ```
- 若需要在工具链中安装 Node 相关依赖，请使用 `pnpm` 替换 `npm`（例如 `pnpm install`），仓库当前未提供前端依赖。

## 3. 目录结构、路由与接口
- **整体结构**：
  ```
  aiwa_core/
  ├── lib/                 # 核心算法模块（core、math、pipeline、pose、result、spec）
  ├── test/                # 纯 Dart 单元测试与夹带数据
  ├── tools/               # Python 基线脚本与示例数据
  └── pubspec.*

  aiwa_cli/
  ├── bin/aiwa_cli.dart    # CLI 入口
  ├── configs/             # 默认混合/证据配置
  └── pubspec.*

  aiwa_app/                # Flutter 应用（保留原平台工程与 UI）
  ```
- **前端/页面路由**：仓库仍未包含 Web/前端页面；Flutter 应用示例为计数器壳工程。
- **API 接口**：当前实现为离线 CLI 工具，不暴露 HTTP/REST API。输入通过文件（关键点 JSON、规则 JSON）提供，输出生成 `angles.csv` 与 `result.json`；如需服务化，可在此基础上封装。

## 4. 技术栈与依赖
- **语言与工具**：Dart 3、`args`（CLI 参数解析）、`dart test` 单元测试框架。
- **核心依赖**（位于 `aiwa_core`）：
  - `csv`：生成角度 CSV 输出。
  - `path`：处理文件路径、导出中立关键点。
- **CLI 依赖**：`args`（命令行参数解析）。
- **Flutter 侧**：`google_mlkit_pose_detection`（相机推理）、`flutter_test`、`flutter_lints`。
- **工具脚本**：`aiwa_core/tools/python_baseline.py` 提供 Python 参考实现，便于结果对比。

## 5. 贡献与注意事项
- 修改或新增脚本时，请在对应包目录更新文档与依赖说明。
- 提交前运行 `dart test`（核心）或相应 `flutter test`，确保新增逻辑的稳定性；若涉及代码生成，请执行 `dart run build_runner build --delete-conflicting-outputs` 并提交生成文件。
- 确保 CLI 入参与输出路径在文档或 README 中更新，以便团队成员快速复现。
