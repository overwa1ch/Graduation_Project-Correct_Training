# Event Bus Service

**版本:** v2.0  
**文件:** `event_bus.dart`

## 概述

事件层服务，统一输出 `Stream<Map<String,dynamic>>` 的分析事件流，用于驱动 UI 状态机（Camera → Result）。

基于契约文档：
- `docs/protocols/stdout_events.md`（事件枚举/字段/JSONL 约定）
- `docs/protocols/artifacts_layout.md`（产物目录结构）

## 功能特性

✅ **三种事件源：**
1. **JSONL 文件** - 离线演示/测试
2. **CLI 子进程** - 开发/桌面平台
3. **Isolate** - 移动端（桩实现，待完善）

✅ **契约校验：**
- 自动校验所有事件的必填字段
- 禁止 NaN/Infinity
- 自动注入 sessionId

✅ **错误处理：**
- 统一的 ERROR 事件格式
- 三种异常类型：`EventParseException`, `ContractViolation`, `CliExitException`
- stderr 缓冲（CLI 模式）

✅ **资源管理：**
- 自动释放文件句柄、子进程、Isolate
- 优雅终止（2 秒超时后强杀）
- Warmup 超时检测

## 快速开始

### 1. 从 JSONL 文件读取（推荐用于测试）

```dart
import 'package:aiwa_app/services/event_bus.dart';

final stream = analysisEventsFromJsonlFile('dev/stdout_demo.jsonl');

await for (final event in stream) {
  print('Event: ${event['event']}, sessionId: ${event['sessionId']}');
  
  if (event['event'] == 'DONE') {
    final artifacts = event['artifacts'] as Map;
    print('Analysis complete: ${artifacts['root']}');
  }
}
```

### 2. 从外部进程读取（扩展场景）

> **注意**：aiwa_app 已内置完整的离线分析能力，通常无需外部工具。

```dart
// 仅作为示例，实际使用时请使用内置分析功能
final stream = analysisEventsFromCli(
  dartBin: 'dart',
  args: [
    'run', 
    'some_analyzer.dart',
    '--input', videoPath,
    '--out', outputDir,
    '--config', configPath,
  ],
  warmupTimeout: Duration(seconds: 10),
  debugLog: (msg) => print('[DEBUG] $msg'),
);

await for (final event in stream) {
  // 处理事件...
}
```

### 3. 从 Isolate 读取（移动端）

```dart
final stream = analysisEventsFromIsolate(
  inputPath: videoPath,
  sessionRoot: outputDir,
  configPath: configPath,
);

await for (final event in stream) {
  // 处理事件...
}
```

## 事件类型

| 事件名 | 必填字段 | 说明 |
|--------|---------|------|
| `START` | `input`, `params` | 视频信息与运行参数 |
| `PHASE` | `phase` | 阶段切换 |
| `PROGRESS` | `processed`, `total` | 处理进度 |
| `METRIC` | - | 中间指标 |
| `EVIDENCE` | `frame`, `files` | 命中证据 |
| `DONE` | `artifacts.root` | 产物生成完毕 |
| `ERROR` | `code`, `message` | 错误事件 |

所有事件都包含 `event` 字段和 `sessionId` 字段。

## 错误码

| 错误码 | 说明 |
|--------|------|
| `400_PARSE` | JSON 解析错误 |
| `422_CONTRACT` | 契约违反（字段缺失/类型错误） |
| `404_FILE_NOT_FOUND` | 文件不存在 |
| `408_WARMUP_TIMEOUT` | Warmup 超时 |
| `500_CLI_EXIT_<code>` | CLI 异常退出 |
| `500_INTERNAL` | 内部错误 |
| `501_NOT_IMPLEMENTED` | 功能未实现 |

## 测试

运行单元测试：

```bash
cd aiwa_app
flutter test test/event_bus_test.dart
```

运行示例：

```bash
cd aiwa_app
dart run lib/services/event_bus_example.dart
```

## 文件说明

- `event_bus.dart` - 核心实现（三个接口 + 三个异常类）
- `event_bus_example.dart` - 使用示例
- `../test/event_bus_test.dart` - 单元测试
- `../dev/stdout_demo.jsonl` - 演示用 JSONL 数据

## 验收条件（DoD）

✅ **基础功能：**
1. 能从 `dev/stdout_demo.jsonl` 读取完整事件流（START → DONE）
2. CLI 正常结束时收到 DONE，能从 `DONE.artifacts.root` 定位产物
3. 异常场景下正确抛出异常并下发 ERROR 事件

✅ **异常处理：**
- JSON 解析错误 → `EventParseException` + `ERROR(400_PARSE)`
- 字段缺失 → `ContractViolation` + `ERROR(422_CONTRACT)`
- 子进程退出码非 0 → `CliExitException` + `ERROR(500_CLI_EXIT_<code>)`

✅ **资源释放：**
- 所有场景下资源均被正确释放（文件/进程/Isolate）

## 技术细节

- **编码：** UTF-8（无 BOM）
- **行尾：** 支持 `\n` 和 `\r\n`
- **空安全：** 严格空安全
- **依赖：** 无第三方依赖（纯 Dart）
- **平台兼容：** Android, iOS, macOS, Windows, Linux（Web 不支持 CLI 模式）

## 下一步

1. 完善 Isolate 实现（需要 CLI 提供 Isolate 入口函数）
2. 集成到主应用的状态机
3. 添加性能监控（事件延迟、吞吐量等）
4. 添加事件持久化（可选）

## 许可

遵循项目主许可证。

