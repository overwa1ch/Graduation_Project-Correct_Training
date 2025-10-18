# Hybrid & Evidence CLI 使用与参数说明

## 1. 运行入口
```bash
cd aiwa_cli
dart run bin/aiwa_cli.dart --keypoints <kp.json> --rule <rule.json> [options]
```
> CLI 为纯 Dart 文件模式；需要视频/实时推理时请切换 Flutter 工程。

## 2. 核心参数速览
| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `--keypoints <path>` | - | 关键点 JSON 输入（必填）。|
| `--rule <path>` | - | 规则 JSON 输入（必填）。|
| `--out-dir <dir>` | `./offline_out` | 输出根目录。|
| `--log-level <level>` | `info` | `trace|debug|info|warn|error`。|
| `--dry-run` | `false` | 仅校验配置，不执行推理/导出。|
| `--strict` | `false` | 严格模式：校验失败返回退出码 `3`。|
| `--fail-on-warn` | `false` | 严格模式下将 WARN 视为失败。|
| `--output-format <fmt>` | `human` | 校验汇总输出：`human|json|junit|all`。|
| `--hybrid` | `false` | 启用混合触发/云端合并。需配合 `--hybrid-policy`。|
| `--hybrid-policy <path>` | `./configs/hybrid_policy.json` | C-augment 策略 JSON。|
| `--cloud-mock <path>` | - | 云端合并模拟输入；可单独使用。仓库提供 `aiwa_cli/mocks/cloud_result.json` 作为示例。|
| `--evidence [key=value]` | `topK=6 windowMs=1200 exportOverlay=false` | 证据化参数，可重复传入多组 `key=value`。|
| `--version` / `--help` | - | 查看版本、帮助信息。|

> 当 `--evidence exportOverlay=true` 但本机缺少 `ffmpeg` 时会自动降级为 `false` 并输出 WARN。

## 3. 互斥 / 依赖关系
- CLI 仅支持 `--keypoints`，传入 `--video` 会直接报错并提醒使用 Flutter 构建。
- `--hybrid` 为 true 时必须能读取 `--hybrid-policy`，并且策略需满足 `configs/hybrid_policy.json` 的 C-augment 结构。
- `--cloud-mock` 可与 `--hybrid` 独立开启：未触发策略时可演示“云端占位合并”。示例文件位于 `aiwa_cli/mocks/cloud_result.json`。
- `--evidence` 支持多组参数：例如 `--evidence topK=8 windowMs=1500 --evidence exportOverlay=true`。

## 4. 帮助文案摘录
```
AIWA CLI — Offline Squat Pipeline (schema=vB1.1 / cli=vB1.1-C-augment)

Usage:
  dart run bin/aiwa_cli.dart --keypoints <kp.json> --rule <rule.json> [options]

示例:
  dart run bin/aiwa_cli.dart --engine mlkit --hybrid \
    --hybrid-policy ./configs/hybrid_policy.json \
    --evidence topK=8 windowMs=1500

  dart run bin/aiwa_cli.dart --engine mlkit \
    --cloud-mock ./mocks/cloud_result.json \
    --evidence topK=10 exportOverlay=true
```

## 5. 退出码约定
| 退出码 | 场景 |
| --- | --- |
| `0` | 成功执行。|
| `1` | 参数 / 配置错误，如文件缺失、JSON 解析失败。|
| `2` | 运行时错误，如推理或合并失败、外部工具异常。|
| `3` | 校验失败（需配合 `--strict`；可通过 `--fail-on-warn` 将 WARN 升级为失败）。|

## 6. 校验与日志产物
- 校验结果同时输出到控制台与 `logs/validation_report.json`，并生成 `logs/validation_junit.xml` 供 CI 展示。
- `--output-format json|junit|all` 可在终端额外打印对应机器可读内容。
- 性能统计输出 `logs/perf.json`，字段示例：`evidence_select_ms`、`overlay_render_ms`、`overlayDowngraded`。

## 7. 产物结构
- `offline_out/<run_id>/angles.csv`：角度时间序列。
- `offline_out/<run_id>/result.json`：结果总览，包含 `hybrid`、`evidence` C-augment 字段。
- `offline_out/<run_id>/evidence.json`：新生成的证据列表。
- `offline_out/<run_id>/overlay.mp4`：当 `exportOverlay=true` 且环境支持时导出；否则跳过。
- `offline_out/<run_id>/logs/`：运行日志、触发诊断、云端合并 diff 等。

