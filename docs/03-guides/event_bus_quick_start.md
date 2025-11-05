# Event Bus 快速开始指南

5 分钟快速上手 Event Bus 事件层服务。

---

## 📦 安装

无需安装！`event_bus.dart` 是纯 Dart 实现，无第三方依赖。

---

## 🚀 基础用法

### 1️⃣ 导入

```dart
import 'package:aiwa_app/services/event_bus.dart';
```

### 2️⃣ 创建事件流

**方式 A：从 JSONL 文件（推荐用于测试）**

```dart
final stream = analysisEventsFromJsonlFile('dev/stdout_demo.jsonl');
```

**方式 B：从 CLI 子进程（桌面平台）**

```dart
final stream = analysisEventsFromCli(
  dartBin: 'dart',
  args: [
    'run', 
    '../aiwa_cli/bin/aiwa_cli.dart',
    '--input', videoPath,
    '--out', outputDir,
    '--config', configPath,
  ],
);
```

**方式 C：从 Isolate（移动端）**

```dart
final stream = analysisEventsFromIsolate(
  inputPath: videoPath,
  sessionRoot: outputDir,
  configPath: configPath,
);
```

### 3️⃣ 监听事件

```dart
await for (final event in stream) {
  final eventName = event['event'];
  
  switch (eventName) {
    case 'START':
      print('分析开始');
      break;
      
    case 'PROGRESS':
      final processed = event['processed'];
      final total = event['total'];
      print('进度: $processed/$total');
      break;
      
    case 'DONE':
      final artifacts = event['artifacts'] as Map;
      print('完成！产物: ${artifacts['root']}');
      break;
      
    case 'ERROR':
      final code = event['code'];
      final message = event['message'];
      print('错误: $code - $message');
      break;
  }
}
```

---

## 📋 事件类型速查

| 事件名 | 说明 | 关键字段 |
|--------|------|---------|
| `START` | 分析开始 | `input`, `params` |
| `PHASE` | 阶段切换 | `phase` |
| `PROGRESS` | 进度更新 | `processed`, `total`, `etaSec` |
| `METRIC` | 中间指标 | （根据分析类型变化） |
| `EVIDENCE` | 证据命中 | `frame`, `files` |
| `DONE` | 分析完成 | `artifacts.root`, `artifacts.files` |
| `ERROR` | 错误发生 | `code`, `message`, `details` |

---

## ⚠️ 错误处理

始终监听 `ERROR` 事件：

```dart
if (event['event'] == 'ERROR') {
  final code = event['code'];
  final message = event['message'];
  
  // 根据错误码处理
  if (code.startsWith('400_')) {
    // 客户端错误（解析失败）
  } else if (code.startsWith('422_')) {
    // 契约违反（字段缺失）
  } else if (code.startsWith('500_')) {
    // 服务器错误（CLI 崩溃）
  }
}
```

常见错误码：
- `400_PARSE` - JSON 解析失败
- `422_CONTRACT` - 字段缺失或类型错误
- `404_FILE_NOT_FOUND` - 文件不存在
- `408_WARMUP_TIMEOUT` - 超时未收到事件
- `500_CLI_EXIT_<code>` - CLI 异常退出
- `500_INTERNAL` - 内部错误

---

## 🔧 调试模式

启用调试日志：

```dart
final stream = analysisEventsFromJsonlFile(
  'dev/stdout_demo.jsonl',
  debugLog: (msg) => print('[DEBUG] $msg'),
);
```

输出示例：
```
[DEBUG] [JSONL] Start reading: dev/stdout_demo.jsonl
[DEBUG] [JSONL] Line 1: empty, skipped
[DEBUG] [JSONL] Received DONE, closing stream
```

---

## 💡 最佳实践

### 1. 使用 try-catch

虽然错误会转换为 ERROR 事件，但仍建议使用 try-catch：

```dart
try {
  await for (final event in stream) {
    // 处理事件
  }
} catch (e) {
  // 处理意外异常（极少发生）
  print('Unexpected error: $e');
}
```

### 2. 检查 sessionId

所有事件都包含 `sessionId`，用于关联多个事件：

```dart
final sessionId = event['sessionId'];
print('Session: $sessionId');
```

### 3. 设置合理的超时

桌面模式建议设置 15 秒超时：

```dart
final stream = analysisEventsFromCli(
  dartBin: 'dart',
  args: [...],
  warmupTimeout: Duration(seconds: 15),
);
```

### 4. 清理资源

取消订阅会自动清理资源：

```dart
final subscription = stream.listen((event) {
  // 处理事件
});

// 稍后取消
await subscription.cancel(); // 自动释放文件/进程/Isolate
```

---

## 📝 完整示例

```dart
import 'package:aiwa_app/services/event_bus.dart';

Future<void> analyzeVideo(String videoPath) async {
  print('开始分析视频: $videoPath');
  
  final stream = analysisEventsFromCli(
    dartBin: 'dart',
    args: [
      'run',
      '../aiwa_cli/bin/aiwa_cli.dart',
      '--input', videoPath,
      '--out', 'build/offline_out',
      '--config', 'assets/config/angles_vB1.json',
    ],
    warmupTimeout: Duration(seconds: 15),
    debugLog: (msg) => print('[DEBUG] $msg'),
  );

  try {
    await for (final event in stream) {
      final eventName = event['event'];
      
      switch (eventName) {
        case 'START':
          final input = event['input'] as Map;
          print('📹 视频: ${input['path']}');
          print('⏱️  时长: ${input['durationMs']}ms');
          break;
          
        case 'PROGRESS':
          final processed = event['processed'];
          final total = event['total'];
          final percentage = (processed / total * 100).toInt();
          final etaSec = event['etaSec'] ?? 0;
          print('⏳ 进度: $percentage% (预计剩余 ${etaSec}s)');
          break;
          
        case 'EVIDENCE':
          final frame = event['frame'];
          final files = event['files'] as List;
          print('⚠️  发现证据: 帧 $frame');
          print('   文件: ${files.join(', ')}');
          break;
          
        case 'DONE':
          final artifacts = event['artifacts'] as Map;
          final root = artifacts['root'];
          final files = artifacts['files'] as List;
          print('✅ 分析完成！');
          print('📁 产物目录: $root');
          print('📄 生成文件: ${files.join(', ')}');
          break;
          
        case 'ERROR':
          final code = event['code'];
          final message = event['message'];
          print('❌ 错误: $code');
          print('   详情: $message');
          
          // 如果有 stderr 日志，打印最后几行
          if (event.containsKey('details')) {
            final details = event['details'] as Map;
            if (details.containsKey('stderrTail')) {
              print('   stderr 尾部:');
              for (final line in details['stderrTail'] as List) {
                print('     $line');
              }
            }
          }
          break;
      }
    }
  } catch (e) {
    print('💥 意外异常: $e');
  }
  
  print('流已关闭');
}

void main() async {
  await analyzeVideo('assets/videos/squat_sample.mp4');
}
```

---

## 🧪 快速测试

### 1. 运行演示示例

```bash
cd aiwa_app
dart run lib/services/event_bus_example.dart
```

### 2. 运行单元测试

```bash
cd aiwa_app
flutter test test/event_bus_test.dart
```

### 3. 使用演示数据

`dev/stdout_demo.jsonl` 包含完整的事件流，适合快速测试：

```dart
final stream = analysisEventsFromJsonlFile('dev/stdout_demo.jsonl');
await for (final event in stream) {
  print('Event: ${event['event']}');
}
```

---

## 📚 更多资源

- **完整文档：** `lib/services/README.md`
- **使用示例：** `lib/services/event_bus_example.dart`
- **单元测试：** `test/event_bus_test.dart`
- **实现总结：** `lib/services/IMPLEMENTATION_SUMMARY.md`
- **事件契约：** `docs/protocols/stdout_events.md`
- **产物规范：** `docs/protocols/artifacts_layout.md`

---

## ❓ 常见问题

### Q: 为什么收到 `408_WARMUP_TIMEOUT` 错误？

A: CLI 进程在 10 秒内未产生任何事件。可能原因：
- CLI 启动失败
- 路径错误
- 参数错误

解决方法：
1. 增加超时时间：`warmupTimeout: Duration(seconds: 20)`
2. 启用调试日志查看详情
3. 检查 stderr 输出

### Q: 如何获取产物文件？

A: 监听 `DONE` 事件：

```dart
if (event['event'] == 'DONE') {
  final artifacts = event['artifacts'] as Map;
  final root = artifacts['root']; // 例如: "build/offline_out/20251028_101320_7f2c/"
  final resultFile = '$root/result.json';
  final data = await File(resultFile).readAsString();
}
```

### Q: 如何取消正在运行的分析？

A: 取消订阅即可：

```dart
final subscription = stream.listen(...);
subscription.cancel(); // 自动终止 CLI 进程
```

### Q: Isolate 模式何时可用？

A: 当前为桩实现，需要 CLI 提供 Isolate 入口函数。预计在下一版本完成。

### Q: 支持多个并发分析吗？

A: 支持！每个分析都有独立的 `sessionId`，可以并发运行多个流。

---

## 🎉 开始使用

现在你已经掌握了基础知识，开始构建你的应用吧！

```dart
import 'package:aiwa_app/services/event_bus.dart';

void main() async {
  final stream = analysisEventsFromJsonlFile('dev/stdout_demo.jsonl');
  
  await for (final event in stream) {
    print('收到事件: ${event['event']}');
  }
  
  print('完成！');
}
```

祝编码愉快！ 🚀

