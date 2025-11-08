# Phase 4 Functional Integration - 实施指南

**状态：** ✅ 已完成  
**版本：** v1.1  
**更新日期：** 2025-10-30

本文档说明 Phase 4 功能集成的实际实现状态和使用方法。

---

## 📋 实施概览

Phase 4 已完成以下核心功能：

1. ✅ **CLI 调用 & 事件流** - `lib/services/event_bus.dart`
2. ✅ **结果适配 & 字段映射** - `lib/adapters/result_adapter.dart`
3. ✅ **运行时配置** - `lib/services/config_sync.dart`
4. ✅ **错误处理 & 恢复** - `lib/services/error_code_mapper.dart` + Camera 页面
5. ✅ **会话管理** - `lib/services/session_manager.dart`
6. ✅ **最小契约测试** - `test/result_adapter_test.dart`, `test/config_sync_test.dart`, `test/services/event_bus_jsonl_test.dart`
7. ✅ **CI Schema 校验** - `.github/workflows/flutter-ci.yml`

---

## 📦 核心文件

### 1. 服务层（Services）
- **`lib/services/event_bus.dart`** - 事件流服务（三种事件源：JSONL/CLI/Isolate）
- **`lib/services/config_sync.dart`** - 配置同步层（Settings ↔ app_runtime.json）
- **`lib/services/session_manager.dart`** - 会话目录管理（创建/清理/列表）
- **`lib/services/error_code_mapper.dart`** - 错误码归一化与 UI 行为映射

### 2. 适配层（Adapters）
- **`lib/adapters/result_adapter.dart`** - 结果适配器（result.json → UI 模型）
- **`lib/adapters/evidence_resolver.dart`** - 证据解析器（降级策略）

### 3. UI 页面（Pages）
- **`lib/ui/pages/camera_page.dart`** - 状态机 + 事件监听 + 进度展示
- **`lib/ui/pages/result_popup_page.dart`** - 结果弹窗（分数/证据展示）
- **`lib/ui/pages/settings_page.dart`** - 配置双向同步

### 4. 演示数据（Dev）
- **`dev/stdout_demo.jsonl`** - 演示事件流（JSONL 格式）
- **`dev/result_demo.json`** - 演示结果数据（JSON 格式）
- **`dev/app_runtime_default.json`** - 默认运行时配置

### 5. 测试（Tests）
- **`test/result_adapter_test.dart`** - 结果适配器测试（字段映射 & 证据回退）
- **`test/config_sync_test.dart`** - 配置同步测试（读写 & 必填校验）
- **`test/services/event_bus_jsonl_test.dart`** - 事件流测试（事件顺序 & 关键字段）

---

## 🎯 核心功能

### 1️⃣ CLI 调用 & 事件流

**实现文件：** `lib/services/event_bus.dart`

**三种事件源：**
1. **JSONL 文件** - 离线演示/测试
2. **CLI 子进程** - 开发/桌面平台
3. **Isolate** - 移动端（桩实现）

**契约校验：**
- 自动校验所有事件的必填字段
- 禁止 NaN/Infinity
- 自动注入 sessionId

**错误处理：**
- 统一的 ERROR 事件格式
- 三种异常类型：`EventParseException`, `ContractViolation`, `CliExitException`
- stderr 缓冲（CLI 模式）

---

### 2️⃣ 结果适配 & 字段映射

**实现文件：** `lib/adapters/result_adapter.dart`

**字段映射（基于 `docs/protocols/ui_contracts.md`）：**
```dart
posture   ← scores.form       // 姿势得分
stability ← scores.stability  // 稳定性得分
rhythm    ← scores.tempo      // 节奏得分
total     ← scores.overall    // 综合得分
reps      ← repCount          // 动作次数
evidencePath ← evidence[0].snapshotPath  // 证据快照路径
```

**证据降级策略：**
1. **优先级 1：** 显示证据快照（`evidencePath`）
2. **优先级 2：** 显示时间窗提示（`window.startMs ~ endMs`）
3. **优先级 3：** 显示占位图标（"No evidence snapshot"）

---

### 3️⃣ 运行时配置

**实现文件：** `lib/services/config_sync.dart`

**职责：**
1. Settings 表单 ↔ `configs/app_runtime.json` 的双向同步（全局）
2. 每次分析时生成会话级只读快照 `configs_snapshot.json`
3. 产出 CLI/Isolate 可用的参数三元组

**配置字段（基于 `docs/protocols/schemas/app_runtime_v1.schema.json`）：**
- `engine`: MoveNet / MLKit / MediaPipe / Auto
- `strictness`: strict / relaxed
- `stride`: 抽样步长（默认 2）
- `targetFps`: 目标帧率（默认 30）
- `resolution`: 分辨率（默认 1280x720）
- `privacy.upload`: none / keypoints-only / video+keypoints
- `cleanup.days`: 清理天数（默认 7）
- `logs.level`: 日志级别（默认 info）

---

### 4️⃣ 错误处理 & 恢复

**实现文件：** `lib/services/error_code_mapper.dart` + `lib/ui/pages/camera_page.dart`

**错误码归一化：**
将历史错误码或变体映射为标准错误码（基于 `docs/protocols/ERROR_TO_ACTION.md` v1.1）

**标准错误码：**
- `400_PARSE` - JSON 解析失败
- `404_FILE_NOT_FOUND` - 文件不存在
- `408_WARMUP_TIMEOUT` - CLI 启动超时
- `422_CONTRACT` - 事件契约违反
- `422_SCHEMA_MISMATCH` - result.json 结构不符
- `500_CLI_EXIT_<code>` - CLI 异常退出
- `500_INTERNAL` - 内部错误
- `500_RESULT_READ` - 读取 result.json 失败
- `501_NOT_IMPLEMENTED` - 功能未实现

**UI 行为映射：**
每个错误码对应特定的 UI 响应（错误弹窗/警告 toast/重试按钮/查看日志/清理空间）

---

### 5️⃣ 会话管理

**实现文件：** `lib/services/session_manager.dart`

**职责：**
1. 创建唯一会话目录（格式: `build/offline_out/yyyyMMdd_HHmmss_<rand>`）
2. 清理过期会话（根据 `cleanup.days` 配置）
3. 列出所有会话

**会话目录结构：**
```
build/offline_out/
  └── 20251030_143052_a7f3/
      ├── result.json
      ├── configs_snapshot.json
      ├── evidence/
      │   └── frame_612.jpg
      └── logs/
          └── run.log
```

---

### Camera Page（相机页）

**状态机流程：**
```
idle → preparing → running → parsing → success/error
```

**主要功能：**
1. ✅ 点击"Record New Video"或"Import Videos"触发分析
2. ✅ 从 JSONL 文件读取事件流（演示模式）
3. ✅ 实时更新进度条（0-100%）
4. ✅ 显示 ETA 和性能指标（etaSec, p95MsPerFrame）
5. ✅ 质量警告提示（低置信度/低覆盖率）
6. ✅ 证据缓存（首条 EVIDENCE 事件）
7. ✅ 错误处理（显示错误码和消息，支持归一化）
8. ✅ 取消/重试按钮

**事件源切换：**

**演示模式（当前）：** 从 JSONL 文件读取事件
```dart
final stream = analysisEventsFromJsonlFile(
  'dev/stdout_demo.jsonl',
  debugLog: (msg) => debugPrint('[EventBus] $msg'),
);
```

**CLI 模式（真实）：** 从子进程读取事件
```dart
final stream = analysisEventsFromCli(
  dartBin: 'dart',
  args: [
    'run', 'aiwa_cli/bin/aiwa_cli.dart',
    '--input', args.inputPath,
    '--out', args.sessionRoot,
    '--config', args.configPath,
  ],
  debugLog: (msg) => debugPrint('[EventBus] $msg'),
);
```

**Isolate 模式（移动端）：** 从 Isolate 读取事件
```dart
final stream = analysisEventsFromIsolate(
  inputPath: args.inputPath,
  sessionRoot: args.sessionRoot,
  configPath: args.configPath,
  debugLog: (msg) => debugPrint('[EventBus] $msg'),
);
```

---

### Result Popup Page（结果弹窗）

**主要功能：**
1. ✅ 显示分项分数（Posture/Stability/Rhythm）
2. ✅ 根据分数显示颜色（<60 红，60-79 黄，≥80 绿）
3. ✅ 显示总分和次数
4. ✅ 证据降级策略（三级降级）：
   - **优先级 1：** 显示证据快照（`evidencePath`）
   - **优先级 2：** 显示时间窗提示（`window.startMs ~ endMs`）
   - **优先级 3：** 显示占位图标（"No evidence snapshot"）
5. ✅ 质量警告提示（lowConfidence / coverage < 0.7）
6. ✅ 显示元信息（template/strictness/engine/fps/coverage）

**数据映射（参见 `ui_contracts.md`）：**
```dart
posture   ← scores.form
stability ← scores.stability
rhythm    ← scores.tempo
total     ← scores.overall
reps      ← repCount
```

**证据降级策略实现：**
```dart
// 1. 优先显示快照图片
if (evidencePath != null && evidencePath.isNotEmpty) {
  显示图片: ${sessionRoot}/${evidencePath}
}
// 2. 次选显示时间窗提示
else if (evidenceWindow != null) {
  显示时间窗: "${startSec}s - ${endSec}s"
  提示用户回放该片段
}
// 3. 最后显示占位
else {
  显示图标: "No evidence snapshot"
}
```

---

### Settings Page（设置页）

**主要功能：**
1. ✅ 从 `configs/app_runtime.json` 读取配置并填充表单
2. ✅ 完整字段支持：
   - **Analysis Threshold:** `relaxed` / `strict`
   - **Analysis Engine:** `MLKit` / `MoveNet` / `MediaPipe` / `Auto`
   - **Performance Settings:**
     - Stride (步长): int, ≥ 1
     - Target FPS (目标帧率): int, ≥ 1
     - Resolution (分辨率): string, 格式 `\d{3,4}x\d{3,4}`
   - **Data Management:**
     - Upload Video: `keypoints-only` / `video+keypoints`
     - Confirm Before Upload: bool
     - Cleanup Days (清理天数): int, ≥ 0
   - **Advanced Settings:**
     - Log Level: `info` / `debug` / `warning` / `error`
3. ✅ 轻量校验（前端侧）
   - 枚举值匹配
   - 数值范围检查
   - 分辨率格式验证
   - 实时校验 + 内联错误提示
4. ✅ 变更检测
   - 无变更时禁用"保存设置"按钮
   - 有变更时启用按钮
5. ✅ 恢复默认功能
   - 一键恢复所有字段为 schema 默认值
6. ✅ 保存配置到 `configs/app_runtime.json`
   - 保存期间禁用按钮（loading indicator）
   - 成功提示："已保存，下次分析生效"
   - 失败提示："保存失败: <错误信息>"
7. ✅ 清理历史会话
   - 删除 N 天前的会话目录
   - 默认 7 天

---

## 🔧 配置文件

### app_runtime.json（全局配置）

**默认值：**
```json
{
  "engine": "MoveNet",
  "strictness": "strict",
  "stride": 2,
  "targetFps": 30,
  "resolution": "1280x720",
  "privacy": {
    "upload": "keypoints-only",
    "confirmVideoUpload": true
  },
  "cleanup": {
    "days": 7
  },
  "logs": {
    "level": "info"
  }
}
```

**保存位置：**
- 全局：`configs/app_runtime.json`
- 会话快照：`<sessionRoot>/configs_snapshot.json`

---

## 📂 会话目录结构

```
build/offline_out/
  ├── 20251028_143052_a7f3/          # 会话 ID（格式: yyyyMMdd_HHmmss_<rand>）
  │   ├── result.json                # 分析结果（必须）
  │   ├── configs_snapshot.json      # 配置快照（会话级只读）
  │   ├── evidence/                  # 证据快照（可选）
  │   │   └── frame_612.jpg
  │   └── logs/                      # 日志文件（可选）
  │       └── perf.json
  └── ...
```

---

## 🧪 演示模式测试流程

1. **启动应用**
   ```bash
   cd aiwa_app
   flutter run
   ```

2. **触发分析**
   - 点击"Record New Video"或"Import Videos"按钮
   - 观察状态变化：idle → preparing → running → parsing

3. **观察进度**
   - 进度条从 0% 增长到 100%
   - 显示 ETA 和性能指标
   - 可能显示质量警告（黄条）

4. **查看结果**
   - 自动弹出结果页面
   - 显示分项分数（带颜色）
   - 显示总分和次数
   - 显示元信息

5. **修改设置**
   - 进入 Settings 页
   - 修改 Threshold 或 Engine
   - 点击"Save Settings"
   - 返回 Camera 页，再次分析（新配置生效）

---

## 🚀 切换到真实 CLI 模式

**修改 `camera_page.dart` 第 99-101 行：**

```dart
// 注释掉演示模式
// final stream = analysisEventsFromJsonlFile(
//   'dev/stdout_demo.jsonl',
//   debugLog: (msg) => debugPrint('[EventBus] $msg'),
// );

// 启用 CLI 模式
final stream = analysisEventsFromCli(
  dartBin: 'dart',
  args: [
    'run', 'aiwa_cli/bin/aiwa_cli.dart',
    '--input', args.inputPath,
    '--out', args.sessionRoot,
    '--config', args.configPath,
  ],
  debugLog: (msg) => debugPrint('[EventBus] $msg'),
);
```

**注意：** 需要实现视频选择功能，替换 `pickedInput: 'dev/demo_video.mp4'`（第 93 行）。

---

## 📋 DoD（完成定义）验证清单

- [x] Camera 页能从 `idle → preparing → running → parsing → success` 走完
- [x] 进度条随 `PROGRESS` 事件正常变化
- [x] 显示 `etaSec` 和 `p95MsPerFrame`（若有）
- [x] DONE 后成功解析 `result.json`，弹出结果页面
- [x] 分项/次数/证据/质量提示正确显示
- [x] `ERROR` 事件 / Schema/IO 异常统一展示错误卡片
- [x] Settings 保存后，下次分析 `configs_snapshot.json` 字段一致
- [x] 事件源在 JSONL（演示）与 CLI 之间切换无需改 UI 逻辑
- [x] 无 linter 错误

---

## 🐛 已知限制

1. **演示模式限制：**
   - JSONL 文件固定，进度变化可能不够平滑
   - 需要手动创建对应的 `result.json`（当前使用 `dev/result_demo.json`）

2. **视频选择未实现：**
   - 当前使用占位路径 `'dev/demo_video.mp4'`
   - 真实场景需集成 `image_picker` 或 `file_picker` 包

3. **Isolate 模式未实现：**
   - `analysisEventsFromIsolate` 当前返回 `501_NOT_IMPLEMENTED` 错误
   - 需要 CLI 提供 Isolate 入口函数

4. **证据快照路径：**
   - 当前假设相对路径基于 `sessionRoot`
   - 若证据文件不存在，显示占位图标

---

## 📞 联系与支持

如有问题，请参考以下文档：
- `docs/protocols/stdout_events.md` - 事件流契约
- `docs/protocols/ui_contracts.md` - UI 映射规则
- `docs/protocols/schemas/analysis_result_v2.schema.json` - 结果 Schema
- `docs/protocols/schemas/app_runtime_v1.schema.json` - 配置 Schema

---

**版本：** v2.0  
**最后更新：** 2025-10-28

