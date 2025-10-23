# 项目说明（AIWA Squat Offline Pipeline）

## 1. 项目概述
- 仓库包含三个主要的 Dart/Flutter 包，用于实现离线深蹲姿态评估：
  - `aiwa_core`：纯 Dart 核心算法（关键点解析、滤波、角度计算、计数、评分等）。
  - `aiwa_cli`：基于 `aiwa_core` 的命令行工具，处理离线关键点 JSON 并产出统计结果。
  - `aiwa_app`：Flutter 应用，后续可集成相机与 ML Kit 推理以复用核心算法。
- `tools/` 目录提供 Python 基线脚本与示例数据，便于对照调试。

## 2. 安装、环境变量、运行与构建
1. **准备基础环境**
   ```bash
   # 请安装 Dart SDK ≥ 3.4，并确保可在命令行使用
   export DART_SDK="/path/to/dart-sdk"
   export PATH="$DART_SDK/bin:$PATH"
   ```
2. **安装核心与 CLI 依赖**
   ```bash
   cd aiwa_core
   dart pub get

   cd ../aiwa_cli
   dart pub get
   ```
3. **运行 CLI（默认读取夹带样例，可按需替换参数）**
   ```bash
   cd aiwa_cli
   dart run bin/aiwa_cli.dart \
     --keypoints ../aiwa_core/test/fixtures/kp_sample.json \
     --rule ../aiwa_core/test/fixtures/squat.v1.json \
     --strictness relaxed \
     --out build/offline_out
   ```
   - CLI 目前只支持文件输入；若需实时推理，请使用 Flutter 应用。
4. **构建本地可执行文件**
   ```bash
   cd aiwa_cli
   dart compile exe bin/aiwa_cli.dart -o build/aiwa_cli
   ```
5. **运行测试**
   ```bash
   cd aiwa_core
   dart test
   ```
6. **前端依赖管理提示**
   - 若后续引入前端或 Node 脚本，请使用 `pnpm`（如 `pnpm install`）替代 `npm` 系列命令。

## 3. 目录结构、页面路由与 API 接口
- **后端/核心目录**
  - `aiwa_core/lib/`：核心算法模块，包含 `core/`、`math/`、`pipeline/`、`pose/`、`result/`、`spec/` 等子目录。
  - `aiwa_core/test/`：纯 Dart 单元测试及夹带关键点数据。
  - `aiwa_cli/bin/aiwa_cli.dart`：命令行入口，解析参数并调用核心能力。
  - `aiwa_core/tools/`：Python 基线脚本与示例关键点。
- **前端目录**
  - `aiwa_app/lib/main.dart`：Flutter 主入口，当前为计数器示例。
  - `aiwa_app/assets/`：Flutter 资源占位目录。
  - 其他平台目录（`android/`、`ios/`、`web/`、`macos/`、`windows/`、`linux/`）保留 Flutter 默认结构。
- **页面路由**
  - Flutter 应用采用 `MaterialApp`，`home` 对应 `_CounterPage`，用于演示计数器界面。
- **项目 API 接口**
  - 现阶段仅提供离线 CLI，没有 HTTP/REST API。
  - CLI 输入：关键点 JSON（`--keypoints`）、规则 JSON（`--rule`），输出目录（`--out`）。
  - CLI 输出：`angles.csv` 与 `result.json` 等统计文件，供后续集成使用。

## 4. 技术栈与依赖说明
- **语言与框架**：Dart 3、Flutter、Material Design。
- **核心依赖（aiwa_core）**：`csv`（角度 CSV 导出）、`path`（文件路径处理）。
- **CLI 依赖（aiwa_cli）**：`args`（命令行参数解析）、`path`、本地依赖 `aiwa_core`。
- **Flutter 依赖（aiwa_app）**：`google_mlkit_pose_detection`（姿态识别）、`aiwa_core`、`flutter_lints`、`flutter_test`。
- **开发工具**：`dart test`（单元测试）、`lints`（静态检查）。
- **辅助脚本**：`aiwa_core/tools/python_baseline.py` 提供 Python 参考实现，用于验证算法输出。

## 5. 贡献与注意事项
- 修改或新增脚本时，请同步更新相关包内的文档与依赖描述。
- 提交前务必运行 `dart test`（核心）及必要的 `flutter test`，确保改动稳定。
- 如需生成代码，请执行 `dart run build_runner build --delete-conflicting-outputs` 并提交生成结果。
- CLI 参数或输出格式若有变更，请及时在文档（如 README 或本说明）中说明，方便团队复现。
