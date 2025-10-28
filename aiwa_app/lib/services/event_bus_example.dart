// event_bus_example.dart
// 使用示例：演示如何使用 event_bus.dart 的三个接口

import 'dart:async';
import 'package:aiwa_app/services/event_bus.dart';

/// 示例 1: 从 JSONL 文件读取事件（离线演示）
Future<void> exampleJsonlFile() async {
  print('=== Example 1: Reading from JSONL file ===');

  final stream = analysisEventsFromJsonlFile(
    'dev/stdout_demo.jsonl',
    debugLog: (msg) => print('[DEBUG] $msg'),
  );

  await for (final event in stream) {
    final eventName = event['event'];
    final sessionId = event['sessionId'];
    print('Event: $eventName, sessionId: $sessionId');

    switch (eventName) {
      case 'START':
        final input = event['input'] as Map;
        print('  → Input: ${input['path']}, ${input['durationMs']}ms');
        break;

      case 'PROGRESS':
        final processed = event['processed'];
        final total = event['total'];
        final percentage = ((processed / total) * 100).toStringAsFixed(1);
        print('  → Progress: $processed/$total ($percentage%)');
        break;

      case 'DONE':
        final artifacts = event['artifacts'] as Map;
        print('  → Output: ${artifacts['root']}');
        print('  → Files: ${artifacts['files']}');
        break;

      case 'ERROR':
        final code = event['code'];
        final message = event['message'];
        print('  ✗ Error: $code - $message');
        break;
    }
  }

  print('Stream closed.\n');
}

/// 示例 2: 从 CLI 子进程读取事件（开发/桌面）
Future<void> exampleCliProcess() async {
  print('=== Example 2: Reading from CLI subprocess ===');

  try {
    final stream = analysisEventsFromCli(
      dartBin: 'dart',
      args: [
        'run',
        '../aiwa_cli/bin/aiwa_cli.dart',
        '--input',
        'assets/videos/squat_sample.mp4',
        '--out',
        'build/offline_out/test_session',
        '--config',
        'assets/config/angles_vB1.json',
      ],
      warmupTimeout: const Duration(seconds: 15),
      debugLog: (msg) => print('[DEBUG] $msg'),
    );

    await for (final event in stream) {
      final eventName = event['event'];
      print('Event: $eventName');

      if (eventName == 'DONE') {
        final artifacts = event['artifacts'] as Map;
        print('✓ Analysis complete: ${artifacts['root']}');
      } else if (eventName == 'ERROR') {
        final code = event['code'];
        final message = event['message'];
        print('✗ Analysis failed: $code - $message');
        
        // 检查是否有 stderr 日志
        if (event.containsKey('details')) {
          final details = event['details'] as Map;
          if (details.containsKey('stderrTail')) {
            print('  Last stderr lines:');
            for (final line in details['stderrTail'] as List) {
              print('    $line');
            }
          }
        }
      }
    }
  } catch (e) {
    print('Exception: $e');
  }

  print('Stream closed.\n');
}

/// 示例 3: 从 Isolate 读取事件（移动端）
Future<void> exampleIsolate() async {
  print('=== Example 3: Reading from Isolate ===');

  try {
    final stream = analysisEventsFromIsolate(
      inputPath: 'assets/videos/squat_sample.mp4',
      sessionRoot: 'build/offline_out/test_session',
      configPath: 'assets/config/angles_vB1.json',
      debugLog: (msg) => print('[DEBUG] $msg'),
    );

    await for (final event in stream) {
      final eventName = event['event'];
      print('Event: $eventName');

      if (eventName == 'ERROR' && event['code'] == '501_NOT_IMPLEMENTED') {
        print('  → Isolate mode not implemented yet');
      }
    }
  } catch (e) {
    print('Exception: $e');
  }

  print('Stream closed.\n');
}

/// 示例 4: 错误处理和超时
Future<void> exampleErrorHandling() async {
  print('=== Example 4: Error handling ===');

  // 测试文件不存在
  print('Test 1: Non-existent file');
  final stream1 = analysisEventsFromJsonlFile('non_existent.jsonl');
  await for (final event in stream1) {
    if (event['event'] == 'ERROR') {
      print('  → Got expected error: ${event['code']}');
    }
  }

  // 测试 warmup 超时（使用极短超时）
  print('\nTest 2: Warmup timeout');
  final stream2 = analysisEventsFromCli(
    dartBin: 'dart',
    args: ['--version'], // 不会产生 JSONL 输出
    warmupTimeout: const Duration(milliseconds: 100),
  );

  await for (final event in stream2) {
    if (event['event'] == 'ERROR' && event['code'] == '408_WARMUP_TIMEOUT') {
      print('  → Got expected timeout error');
    }
  }

  print('Error handling complete.\n');
}

/// 示例 5: 取消订阅（资源释放测试）
Future<void> exampleCancellation() async {
  print('=== Example 5: Stream cancellation ===');

  final stream = analysisEventsFromJsonlFile(
    'dev/stdout_demo.jsonl',
    debugLog: (msg) => print('[DEBUG] $msg'),
  );

  var eventCount = 0;
  late StreamSubscription<Map<String, dynamic>> subscription;
  
  subscription = stream.listen((event) {
    eventCount++;
    print('Event $eventCount: ${event['event']}');

    // 收到 3 个事件后取消订阅
    if (eventCount >= 3) {
      print('Cancelling subscription...');
      subscription.cancel();
    }
  });

  await subscription.asFuture<void>();
  print('Subscription cancelled, resources released.\n');
}

/// 主入口（运行所有示例）
Future<void> main() async {
  print('╔════════════════════════════════════════════╗');
  print('║  Event Bus Usage Examples                 ║');
  print('╚════════════════════════════════════════════╝\n');

  // 示例 1: JSONL 文件（最简单，适合快速测试）
  await exampleJsonlFile();

  // 示例 2: CLI 子进程（真实分析场景）
  // 注意: 需要确保 aiwa_cli 可用
  // await exampleCliProcess();

  // 示例 3: Isolate（移动端场景）
  // await exampleIsolate();

  // 示例 4: 错误处理
  // await exampleErrorHandling();

  // 示例 5: 取消订阅
  // await exampleCancellation();

  print('All examples complete!');
}

