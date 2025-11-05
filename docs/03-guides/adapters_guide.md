# Result Adapter Layer

**版本:** v2.0  
**契约依据:**
- `docs/protocols/schemas/analysis_result_v2.schema.json` (CLI 输出结构)
- `docs/protocols/ui_contracts.md` (字段映射规则)
- `docs/protocols/artifacts_layout.md` (产物目录结构)

## 概述

结果适配层负责读取 CLI 输出的 `result.json` 并映射为 UI 轻量模型。

**职责：**
- ✅ 读取 `${sessionRoot}/result.json`
- ✅ 校验关键字段（严格遵循 schema）
- ✅ 映射为 `AnalysisResultLite`（UI 模型）
- ✅ 证据降级策略（snapshot > window > null）

**非职责：**
- ❌ 不负责事件订阅
- ❌ 不负责 UI 展示
- ❌ 不负责 CLI 调用

---

## 快速开始

### 1. 读取并映射结果

```dart
import 'package:aiwa_app/adapters/result_adapter.dart';

try {
  // 1. 读取 result.json
  final raw = await readResultJson(sessionRoot);
  
  // 2. 校验契约
  assertResultContract(raw);
  
  // 3. 映射为轻量模型
  final lite = mapToLite(raw);
  
  // 4. 使用结果
  print('姿势: ${lite.posture}/100');
  print('稳定性: ${lite.stability}/100');
  print('节奏: ${lite.rhythm}/100');
  print('总分: ${lite.total}/100');
  print('次数: ${lite.reps}');
  
  if (lite.evidencePath != null) {
    print('证据: ${lite.evidencePath}');
  }
  
} on SchemaMismatch catch (e) {
  print('契约违反: $e');
} on ResultReadException catch (e) {
  print('读取失败: $e');
}
```

### 2. 证据降级策略

```dart
import 'package:aiwa_app/adapters/evidence_resolver.dart';

// 优先级 1: 快照路径
final snapshot = resolveSnapshotPath(raw);
if (snapshot != null) {
  showSnapshot('$sessionRoot/$snapshot');
  return;
}

// 优先级 2: 时间窗（回放片段）
final window = resolveEvidenceWindow(raw);
if (window != null) {
  playbackSegment(window.startMs, window.endMs);
  return;
}

// 优先级 3: 无证据
showPlaceholder('无证据片段');
```

---

## 字段映射规则

基于 `docs/protocols/ui_contracts.md`：

| UI 字段 | CLI 字段 | 说明 |
|---------|---------|------|
| `posture` | `scores.form` | 姿势得分 (0..100) |
| `stability` | `scores.stability` | 稳定性得分 (0..100) |
| `rhythm` | `scores.tempo` | 节奏得分 (0..100) |
| `total` | `scores.overall` | 综合得分 (0..100) |
| `reps` | `repCount` | 动作次数 (>=0) |
| `evidencePath` | `evidence[0].snapshotPath` | 证据快照路径 |
| `lowConfidence` | `quality.lowConfidence` | 低置信度标记 |
| `coverage` | `quality.coverage` | 覆盖率 (0..1) |

---

## 核心 API

### `readResultJson(String sessionRoot)`

读取并解析 `result.json`

**参数：**
- `sessionRoot`: 会话根目录（例如：`"build/offline_out/20251028_101320_7f2c"`）

**返回：**
- `Future<Map<String, dynamic>>` - 原始 JSON Map

**异常：**
- `ResultReadException` - 文件不存在或 JSON 解析失败

---

### `assertResultContract(Map<String, dynamic> raw)`

校验 `result.json` 的关键字段

**必填字段：**
- `scores.form|stability|tempo|overall` (int, 0..100)
- `repCount` (int, >=0)
- `meta` (object)

**异常：**
- `SchemaMismatch` - 字段缺失、类型错误、越界

**注意：**
- `meta.*` 子字段缺失不抛错（可容忍）
- `evidence` 可为空或缺失（不抛错）
- `quality.*` 可为空或缺失（不抛错）

---

### `mapToLite(Map<String, dynamic> raw)`

映射为 UI 轻量模型

**参数：**
- `raw`: 原始 JSON Map（已通过 `assertResultContract`）

**返回：**
- `AnalysisResultLite` - UI 轻量模型

**值规范化：**
- 分数浮点数使用 `round()` 取整
- `coverage` 截断到 `[0, 1]` 区间
- `evidencePath` 保持原始相对路径（不拼接 sessionRoot）

---

### `resolveSnapshotPath(Map<String, dynamic> raw)`

解析证据快照路径（优先级最高）

**返回：**
- `String?` - 快照路径（相对路径）或 `null`

**规则：**
- 若 `evidence` 缺失/空 → `null`
- 若 `evidence[0].snapshotPath` 为空/全空白 → `null`
- 否则返回 `snapshotPath`（trim 后）

---

### `resolveEvidenceWindow(Map<String, dynamic> raw)`

解析证据时间窗（优先级次于 snapshotPath）

**返回：**
- `({int startMs, int endMs})?` - 时间窗或 `null`

**规则：**
- 若 `evidence` 缺失/空 → `null`
- 若 `window.startMs` 或 `endMs` 缺失 → `null`
- 若 `endMs <= startMs` → `null`（非法窗口）
- 若 `startMs < 0` → `null`（非法时间）
- 否则返回 `(startMs, endMs)`

---

## 证据降级策略

优先级：`snapshotPath` > `window` > `null`

```dart
// 策略实现示例
String? getEvidenceDisplay(Map<String, dynamic> raw, String sessionRoot) {
  // 1. 优先快照
  final snapshot = resolveSnapshotPath(raw);
  if (snapshot != null) {
    return '$sessionRoot/$snapshot';
  }
  
  // 2. 降级到时间窗
  final window = resolveEvidenceWindow(raw);
  if (window != null) {
    return '回放片段: ${window.startMs}ms - ${window.endMs}ms';
  }
  
  // 3. 无证据
  return null; // UI 显示占位图
}
```

---

## 异常类型

### `SchemaMismatch`

契约违反异常（字段缺失/类型错误/越界）

```dart
class SchemaMismatch implements Exception {
  final String message;
  SchemaMismatch(this.message);
}
```

**常见场景：**
- `scores.form missing`
- `repCount missing`
- `scores.overall out of range [0,100]`
- `repCount must be non-negative`
- `scores.form is NaN or Infinity`

---

### `ResultReadException`

`result.json` 读取异常（文件缺失/解析失败）

```dart
class ResultReadException implements Exception {
  final String message;
  final Object? cause;
  ResultReadException(this.message, {this.cause});
}
```

**常见场景：**
- `result.json not found at: ...`
- `json parse failed`
- `result.json is not a JSON object`

---

## 测试

运行单元测试：

```bash
cd aiwa_app
flutter test test/result_adapter_test.dart
```

**测试覆盖（27 个测试用例）：**
- ✅ Happy path（完整 result.json）
- ✅ Snapshot 缺失（降级到 window）
- ✅ Scores 缺字段（抛 SchemaMismatch）
- ✅ RepCount 缺失（抛 SchemaMismatch）
- ✅ 数值越界/类型错（抛 SchemaMismatch）
- ✅ 文件缺失/JSON 解析失败（抛 ResultReadException）
- ✅ 浮点数取整（round）
- ✅ Coverage 截断 [0,1]
- ✅ Meta 子字段缺失（可容忍）
- ✅ Evidence 数组为空（降级）
- ✅ NaN/Infinity 检测

---

## 示例 result.json

### 完整版本

```json
{
  "version": "2.0",
  "scores": {
    "form": 84,
    "stability": 77,
    "tempo": 71,
    "overall": 78
  },
  "repCount": 12,
  "quality": {
    "lowConfidence": false,
    "coverage": 0.76
  },
  "meta": {
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "fps": 30
  },
  "evidence": [
    {
      "snapshotPath": "evidence/frame_612.jpg",
      "window": {
        "startMs": 20000,
        "endMs": 21000
      },
      "angles": {},
      "advice": ["保持膝盖对齐脚尖"]
    }
  ]
}
```

### 最小版本（无快照）

```json
{
  "scores": {
    "form": 60,
    "stability": 58,
    "tempo": 65,
    "overall": 61
  },
  "repCount": 8,
  "meta": {},
  "evidence": [
    {
      "window": {
        "startMs": 12000,
        "endMs": 12750
      }
    }
  ]
}
```

---

## 技术细节

- **语言：** Dart (Flutter)
- **空安全：** 严格空安全
- **依赖：** 无第三方包（纯 Dart）
- **编码：** UTF-8
- **平台：** 全平台（Android/iOS/macOS/Windows/Linux/Web）

---

## 与事件层集成

结合 `event_bus.dart` 使用：

```dart
import 'package:aiwa_app/services/event_bus.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';

// 1. 监听分析事件
final stream = analysisEventsFromCli(...);

await for (final event in stream) {
  if (event['event'] == 'DONE') {
    final artifacts = event['artifacts'] as Map;
    final sessionRoot = artifacts['root'] as String;
    
    // 2. 读取并映射结果
    try {
      final raw = await readResultJson(sessionRoot);
      assertResultContract(raw);
      final lite = mapToLite(raw);
      
      // 3. 显示 UI
      showResultDialog(lite);
    } catch (e) {
      showError(e);
    }
  }
}
```

---

## 常见问题

### Q: 为什么 `evidencePath` 不自动拼接 `sessionRoot`？

A: 保持适配层纯粹，路径拼接应在 UI 层处理。这样更灵活，易于测试。

```dart
// UI 层负责路径拼接
final fullPath = '$sessionRoot/${lite.evidencePath}';
```

---

### Q: 如何处理 `meta.*` 字段缺失？

A: `meta` 对象必须存在，但子字段可缺失（视为可容忍）。UI 可选择性显示：

```dart
if (lite.templateName != null) {
  print('动作模板: ${lite.templateName}');
}
```

---

### Q: `coverage` 越界怎么办？

A: 自动截断到 `[0, 1]` 区间：

```dart
// coverage = 1.5 → 1.0
// coverage = -0.2 → 0.0
coverage = math.max(0.0, math.min(1.0, rawCoverage));
```

---

### Q: 为什么不对 `snapshotPath`/`window` 缺失抛错？

A: 这是证据降级策略，不是错误条件。UI 可显示占位图或提示"无证据片段"。

---

## 更多资源

- **契约规范：** `docs/protocols/schemas/analysis_result_v2.schema.json`
- **字段映射：** `docs/protocols/ui_contracts.md`
- **产物结构：** `docs/protocols/artifacts_layout.md`
- **事件层：** `lib/services/README.md`

---

## 许可

遵循项目主许可证。

