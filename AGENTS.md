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
- **运行 CLI**（默认使用测试夹带样例，可通过参数覆盖）：
  ```bash
  cd aiwa_cli
  dart run bin/aiwa_cli.dart \
    --keypoints ../aiwa_core/test/fixtures/kp_sample.json \
    --rule ../aiwa_core/test/fixtures/squat.v1.json \
    --strictness relaxed \
    --out build/offline_out
  ```
  > 纯 Dart CLI 当前仅支持 `--keypoints` 文件模式；视频推理请使用 Flutter 工程。
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

## Milestone E 任务描述（Milestone C 测试与样例阶段）

### 阶段目标

- 证明功能可靠、性能达标、边界条件安全。
- 通过生成并运行多种测试样本，验证整个系统在不同输入条件下能否稳定、准确、可复现地工作。

### 总体要求

1. **功能验证**：确认 C 阶段新增的 CLI 参数、Hybrid 触发、Schema 字段、证据化输出全通。
2. **稳定性验证**：不同素材与设备下结果变化小，误差在容差范围内。
3. **回归防护**：生成 Golden 样本 `expected/` 目录，用于后续版本自动比对。
4. **性能监测**：自动输出 `perf.json` 并检查帧率、耗时、内存，防止性能退化。

### 样本类别（共 5 类）

| 类型      | 目录名                                            | 输入内容                           | 测试目的                        |
| --------- | ------------------------------------------------- | ---------------------------------- | ------------------------------- |
| ✅ 正常样本  | `examples/squat_normal/`                          | 光照正常、动作标准的视频或关键点文件             | 验证主流程与输出格式                  |
| ⚠️ 异常样本 | `examples/squat_occlusion/`                       | 遮挡/低光素材 + `hybrid_policy.json` | 验证 Hybrid 触发与 cloud mock 合并 |
| ⏱ 性能样本  | `examples/squat_short/`、`examples/squat_long/`   | 超短 (< 5 s) 与超长 (> 5 min) 视频  | 测试耗时、内存、降级逻辑                |
| 🌀 节奏样本 | `examples/squat_tempo_irregular/`                 | 动作忽快忽慢、停顿素材                    | 检查节奏与评分稳健性                  |
| 🧪 噪声样本 | `examples/squat_noisy_keypoints/`                 | 在关键点中注入抖动或置信度噪声                | 测系统鲁棒性（输出不乱跳）               |

### 每个样本的文件结构

```
input.mp4 或 neutral_keypoints.json
hybrid_policy.json        # 若涉及 Hybrid 触发
cloud_result.json         # 若涉及云端 mock
expected/
  ├── result.json
  ├── angles.csv
  └── evidence.json
  README.md               # 说明样本目的、触发条件、预期结果
  perf.json               # 记录性能指标（timingsMs、RTF、内存等）
```

### 输出格式规范

要求 AI Agent 生成统一结构的 JSON 描述（便于 CI 识别）：

```json
{
  "sampleId": "squat_occlusion",
  "category": "异常样本",
  "purpose": "验证 Hybrid 触发与云端合并逻辑",
  "inputs": ["input.mp4", "hybrid_policy.json", "cloud_result.json"],
  "expectedOutputs": ["result.json", "angles.csv", "evidence.json", "perf.json"],
  "validationRules": [
    "hybrid.triggered == true",
    "mergeStrategy == 'prefer-cloud-count-then-reconcile'",
    "overlay.durationDiff <= 1s"
  ]
}
```

> **提示：**
>
> - `expected/*.json` 可用伪数据填充，但字段结构必须符合 Schema vB1.1 + C-augment。
> - 所有文件命名与 CLI 输出规范保持一致。
> - 若能，生成 `perf.json` 样例，含 `timingsMs`、`inferenceFps`、`cpuUtilAvgPct` 等字段。

### 验收标准

- 覆盖 5 类样本（正常/异常/性能/节奏/噪声）。
- 每类样本产物完整：`result.json`、`angles.csv`、`evidence[]`、`perf.json`。
- 校验脚本 PASS 率 = 100%。
- 性能指标 ≤ 阈值：`RTF ≤ 1.0`、`memPeakMB ≤ 600`。
- Golden 回归连续 3 次稳定 PASS。

### 附加指令（可选）

- `--generate-mock` → 允许 Agent 创建伪 keypoints 数据。
- `--verify-schema` → 在生成样本时自动跑 schema 校验。
- `--export-json` → 导出所有样本描述为 `examples_manifest.json` 供 CI 调用。
