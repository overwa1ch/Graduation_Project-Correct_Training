文件间关系图（责任边界）
        ┌──────────────────────────────┐
        │         app_runtime.json     │ ← App 写入配置
        └──────────────┬───────────────┘
                       │  (CLI 读取)
                 ┌──────▼──────┐
                 │  aiwa_cli   │
                 ├─────────────┤
                 │ 输出 stdout │ → 参照 stdout_events.md
                 │ 写产物 JSON │ → 参照 analysis_result_v2.schema.json
                 │ 写 perf.json│ → 参照 perf_v1.schema.json
                 └──────┬──────┘
                        │
                        ▼
                 ┌──────────────┐
                 │   aiwa_app   │ ← 按 ui_contracts.md 映射/展示
                 └──────────────┘

| 文件                                         | 放置位置                      | 读/写方             | 主要作用                                                                 |
| ------------------------------------------ | ------------------------- | ---------------- | -------------------------------------------------------------------- |
| **stdout_events.md**                       | `docs/protocols/`         | CLI → App        | 定义 CLI 在 stdout 中逐行输出的事件格式（JSON Lines），包括事件名、字段、示例。前端订阅这些事件更新 UI 状态。 |
| **schemas/analysis_result_v2.schema.json** | `docs/protocols/schemas/` | CLI 写入 / App 校验  | 定义 CLI 输出的 `result.json` 的字段规范，以实际文件为准。用于前端解析与单元测试校验。                |
| **schemas/perf_v1.schema.json**            | `docs/protocols/schemas/` | CLI 写入 / QA 校验   | 描述 `perf.json` 文件结构，包含帧耗时统计与设备信息。供性能验收与 CLI 优化调试使用。                  |
| **schemas/app_runtime_v1.schema.json**     | `docs/protocols/schemas/` | App 写入 / CLI 读取  | 约束 `configs/app_runtime.json` 的字段、默认值和可选项。保证前端与 CLI 的运行参数一致。         |
| **ui_contracts.md**                        | `docs/protocols/`         | App → QA / 前后端共用 | 说明 UI 状态机、字段映射（如 form→posture）、证据降级逻辑、提示阈值、错误码展示。是前端联调与验收标准。         |
| **artifacts_layout.md** *(可选)*             | `docs/protocols/`         | CLI → QA         | 记录 CLI 输出产物目录结构与命名规则，QA 用于检查文件完整性。                                   |


📑 详细作用说明
1️⃣ stdout_events.md

目的：
定义 CLI → 前端的「实时事件流」格式，描述每个事件（START / PHASE / PROGRESS / DONE / ERROR）的字段结构、示例与含义。

谁使用：

CLI 开发者：遵守事件输出格式；

App 开发者：解析这些事件更新状态机；

QA：用它验证事件顺序与字段完整性。

关键内容：

JSON Lines 格式介绍；

所有事件枚举及示例；

时间戳、会话 ID、一致性要求；

日志文件与 stdout 对应关系。

2️⃣ schemas/analysis_result_v2.schema.json

目的：
严格定义 CLI 产物 result.json 的字段、类型、取值范围及必选项。

基于实际 aiwa_cli 输出更新：

分项字段：form / stability / tempo / overall

计数字段：repCount

质量信息：quality.lowConfidence、quality.coverage

证据结构：evidence[].snapshotPath、window.startMs/endMs、angles、advice

元信息：meta.template、meta.strictness、meta.engine、meta.fps

作用：

App 校验与解析；

QA 作为 CLI 输出一致性检查标准；

后续版本变更（v2.1/v3.0）只需维护兼容性层。

3️⃣ schemas/perf_v1.schema.json

目的：
描述 perf.json 的结构，用于性能监控与 CLI 调优。

主要字段：

帧耗时统计（p50/p90/p95/max）

分阶段耗时（decode/infer/analyze/export）

总帧数与 stride

设备信息（brand/model/soc）

可选扩展：内存峰值、推理引擎名。

谁使用：

CLI 侧：生成；

QA：回归测试与性能基线对比；

App：详情页性能可视化（可选）。

4️⃣ schemas/app_runtime_v1.schema.json

目的：
约束 App 写入、CLI 读取的配置文件格式。

字段：
engine, strictness, stride, targetFps, resolution,
privacy.upload, confirmVideoUpload, cleanup.days, logs.level.

作用：

保证 CLI 与 App 的运行参数一致；

可由 CLI 启动时自动快照保存；

App 可在设置页生成或修改。

5️⃣ ui_contracts.md

目的：
定义前端侧的：

状态机状态与事件驱动关系；

字段映射关系（form→posture, tempo→rhythm 等）；

错误码与提示逻辑；

困难样本提示阈值；

证据降级策略。

谁使用：

Flutter 前端开发：实现 UI；

QA：检查状态机行为；

CLI：理解 UI 依赖哪些字段。