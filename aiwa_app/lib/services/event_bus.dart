// event_bus.dart
// Version: v2.0
// Purpose: 事件层服务 - 统一输出分析事件流（基于 docs/protocols/stdout_events.md）
//
// 实现三种事件源：
// 1. analysisEventsFromJsonlFile - 从 JSONL 文件读取（离线演示/测试）
// 2. analysisEventsFromCli - 从 CLI 子进程读取（开发/桌面）
// 3. analysisEventsFromIsolate - 从 Isolate 读取（移动端）
//
// 契约要求：
// - 事件名: START | PHASE | PROGRESS | METRIC | EVIDENCE | DONE | ERROR
// - 所有事件必须包含 "event" 字段
// - START 必须包含 input 和 params 对象
// - PROGRESS 必须包含 processed、total 非负数
// - DONE 必须包含 artifacts.root 非空字符串
// - ERROR 必须包含 code 和 message 字符串
//
// 使用示例：
// ```dart
// // 1) 从 JSONL 文件
// final stream = analysisEventsFromJsonlFile('dev/stdout_demo.jsonl');
// await for (final event in stream) {
//   print('Event: ${event['event']}, sessionId: ${event['sessionId']}');
// }
//
// // 2) 从 CLI 子进程
// final stream = analysisEventsFromCli(
//   dartBin: 'dart',
//   args: ['run', 'aiwa_cli/bin/aiwa_cli.dart', '--input', videoPath, '--out', sessionRoot],
//   warmupTimeout: Duration(seconds: 10),
// );
//
// // 3) 从 Isolate
// final stream = analysisEventsFromIsolate(
//   inputPath: videoPath,
//   sessionRoot: outputDir,
//   configPath: configFile,
// );
// ```

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aiwa_app/services/video_analysis_service.dart';
import 'package:aiwa_app/services/cancellation_token.dart';
import 'package:aiwa_core/spec/rule_models.dart';

// ============================================================================
// 异常类型（契约违反/解析错误/CLI 异常）
// ============================================================================

/// JSON 解析异常（行级错误）
class EventParseException implements Exception {
  final int line;
  final String raw;
  final Object? cause;

  EventParseException({required this.line, required this.raw, this.cause});

  @override
  String toString() => 'EventParseException(line=$line, cause=$cause)';
}

/// 契约违反异常（字段缺失/类型错误）
class ContractViolation implements Exception {
  final String message;

  ContractViolation(this.message);

  @override
  String toString() => 'ContractViolation($message)';
}

/// CLI 子进程退出异常
class CliExitException implements Exception {
  final int exitCode;

  CliExitException(this.exitCode);

  @override
  String toString() => 'CliExitException(exitCode=$exitCode)';
}

// ============================================================================
// 公开接口 1: 从 JSONL 文件读取事件
// ============================================================================

/// 从 JSONL 文件读取分析事件流
///
/// 参数:
/// - [jsonlPath]: JSONL 文件路径（每行一个 JSON 对象）
/// - [sessionId]: 可选会话 ID，若未提供则从事件中读取或生成
/// - [debugLog]: 可选调试日志回调
///
/// 返回: 广播流，发出 Map<String, dynamic> 事件
///
/// 行为:
/// - 忽略空白行
/// - JSON 解析错误会触发 ERROR 事件并关闭流
/// - 收到 DONE 或 ERROR 后自动关闭流
/// - 取消订阅时关闭文件句柄
Stream<Map<String, dynamic>> analysisEventsFromJsonlFile(
  String jsonlPath, {
  String? sessionId,
  void Function(String msg)? debugLog,
}) {
  late StreamController<Map<String, dynamic>> controller;
  StreamSubscription<String>? lineSubscription;
  String? currentSessionId = sessionId;
  int lineNumber = 0;

  controller = StreamController<Map<String, dynamic>>.broadcast(
    onListen: () {
      debugLog?.call('[JSONL] Start reading: $jsonlPath');

      try {
        final file = File(jsonlPath);
        if (!file.existsSync()) {
          _emitErrorAndClose(
            controller: controller,
            sessionId: currentSessionId ?? _generateSessionId(),
            code: '404_FILE_NOT_FOUND',
            message: 'JSONL file not found: $jsonlPath',
            debugLog: debugLog,
          );
          return;
        }

        final lines = file
            .openRead()
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter());

        lineSubscription = lines.listen(
          (line) {
            lineNumber++;
            final trimmed = line.trim();

            // 忽略空白与注释行
            if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('//')) {
              debugLog?.call('[JSONL] Line $lineNumber: empty, skipped');
              return;
            }

            try {
              final json = jsonDecode(trimmed) as Map<String, dynamic>;

              // 如果事件中有 sessionId，使用它
              if (json.containsKey('sessionId') && json['sessionId'] is String) {
                currentSessionId = json['sessionId'] as String;
              } else {
                // 注入 sessionId
                currentSessionId ??= _generateSessionId();
                json['sessionId'] = currentSessionId;
              }

              // 校验事件
              _validateEvent(json);

              // 发出事件
              controller.add(json);

              // DONE 或 ERROR 后关闭
              final eventName = json['event'] as String;
              if (eventName == 'DONE' || eventName == 'ERROR') {
                debugLog?.call('[JSONL] Received $eventName, closing stream');
                controller.close();
              }
            } on FormatException catch (e) {
              // 跳过畸形 JSON 行但不关闭流
              debugLog?.call('[JSONL] Line $lineNumber: JSON parse error, skipped: $e');
              return;
            } on ContractViolation catch (e) {
              _emitErrorAndClose(
                controller: controller,
                sessionId: currentSessionId ?? _generateSessionId(),
                code: '422_CONTRACT',
                message: e.message,
                details: {'line': lineNumber, 'raw': trimmed},
                debugLog: debugLog,
              );
            } catch (e) {
              _emitErrorAndClose(
                controller: controller,
                sessionId: currentSessionId ?? _generateSessionId(),
                code: '500_INTERNAL',
                message: 'Unexpected error at line $lineNumber: $e',
                details: {'line': lineNumber, 'raw': trimmed},
                debugLog: debugLog,
              );
            }
          },
          onError: (Object error) {
            debugLog?.call('[JSONL] Stream error: $error');
            _emitErrorAndClose(
              controller: controller,
              sessionId: currentSessionId ?? _generateSessionId(),
              code: '500_INTERNAL',
              message: 'File read error: $error',
              debugLog: debugLog,
            );
          },
          onDone: () {
            debugLog?.call('[JSONL] File read complete');
            if (!controller.isClosed) {
              controller.close();
            }
          },
          cancelOnError: false,
        );
      } catch (e) {
        debugLog?.call('[JSONL] Setup error: $e');
        _emitErrorAndClose(
          controller: controller,
          sessionId: currentSessionId ?? _generateSessionId(),
          code: '500_INTERNAL',
          message: 'Failed to open file: $e',
          debugLog: debugLog,
        );
      }
    },
    onCancel: () {
      debugLog?.call('[JSONL] Stream cancelled, cleaning up');
      lineSubscription?.cancel();
    },
  );

  return controller.stream;
}

// ============================================================================
// 公开接口 2: 从 CLI 子进程读取事件
// ============================================================================

/// 从 CLI 子进程读取分析事件流
///
/// 参数:
/// - [dartBin]: Dart 可执行文件路径（例如 'dart'）
/// - [args]: CLI 参数列表
/// - [sessionId]: 可选会话 ID
/// - [warmupTimeout]: 首条事件超时时间（默认 10 秒）
/// - [debugLog]: 可选调试日志回调
///
/// 返回: 广播流，发出 Map<String, dynamic> 事件
///
/// 行为:
/// - 缓存最近 50 行 stderr
/// - warmupTimeout 内未收到首条事件 → 抛 ContractViolation，下发 ERROR
/// - 子进程退出码非 0 → 抛 CliExitException，下发 ERROR（附带 stderr 尾部）
/// - 收到 DONE 或 ERROR 后关闭流并终止子进程
/// - 取消订阅时优雅终止子进程（2 秒超时后强杀）
Stream<Map<String, dynamic>> analysisEventsFromCli({
  required String dartBin,
  required List<String> args,
  String? sessionId,
  Duration? warmupTimeout,
  void Function(String msg)? debugLog,
}) {
  late StreamController<Map<String, dynamic>> controller;
  Process? process;
  StreamSubscription<String>? stdoutSubscription;
  StreamSubscription<String>? stderrSubscription;
  Timer? warmupTimer;
  String? currentSessionId = sessionId;
  int lineNumber = 0;
  bool firstEventReceived = false;
  final stderrBuffer = <String>[];
  const maxStderrLines = 50;

  final timeout = warmupTimeout ?? const Duration(seconds: 10);

  controller = StreamController<Map<String, dynamic>>.broadcast(
    onListen: () async {
      debugLog?.call('[CLI] Starting process: $dartBin ${args.join(' ')}');

      try {
        process = await Process.start(dartBin, args);
        debugLog?.call('[CLI] Process started: PID ${process!.pid}');

        // 设置 warmup 超时
        warmupTimer = Timer(timeout, () {
          if (!firstEventReceived && !controller.isClosed) {
            debugLog?.call('[CLI] Warmup timeout: no events received in $timeout');
            _emitErrorAndClose(
              controller: controller,
              sessionId: currentSessionId ?? _generateSessionId(),
              code: '408_WARMUP_TIMEOUT',
              message: 'No events received within $timeout',
              debugLog: debugLog,
            );
            _killProcess(process, debugLog);
          }
        });

        // 监听 stdout（JSONL 事件流）
        stdoutSubscription = process!.stdout
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .listen(
          (line) {
            lineNumber++;
            final trimmed = line.trim();

            if (trimmed.isEmpty) {
              debugLog?.call('[CLI] Line $lineNumber: empty, skipped');
              return;
            }

            try {
              final json = jsonDecode(trimmed) as Map<String, dynamic>;

              // 首条事件收到，取消 warmup 定时器
              if (!firstEventReceived) {
                firstEventReceived = true;
                warmupTimer?.cancel();
                debugLog?.call('[CLI] First event received');
              }

              // 处理 sessionId
              if (json.containsKey('sessionId') && json['sessionId'] is String) {
                currentSessionId = json['sessionId'] as String;
              } else {
                currentSessionId ??= _generateSessionId();
                json['sessionId'] = currentSessionId;
              }

              // 校验事件
              _validateEvent(json);

              // 发出事件
              controller.add(json);

              // DONE 或 ERROR 后关闭
              final eventName = json['event'] as String;
              if (eventName == 'DONE' || eventName == 'ERROR') {
                debugLog?.call('[CLI] Received $eventName, closing stream');
                controller.close();
                _killProcess(process, debugLog);
              }
            } on FormatException catch (e) {
              // 跳过畸形 JSON 行但不关闭流
              debugLog?.call('[CLI] Line $lineNumber: JSON parse error, skipped: $e');
              return;
            } on ContractViolation catch (e) {
              _emitErrorAndClose(
                controller: controller,
                sessionId: currentSessionId ?? _generateSessionId(),
                code: '422_CONTRACT',
                message: e.message,
                details: {'line': lineNumber, 'raw': trimmed},
                debugLog: debugLog,
              );
              _killProcess(process, debugLog);
            } catch (e) {
              _emitErrorAndClose(
                controller: controller,
                sessionId: currentSessionId ?? _generateSessionId(),
                code: '500_INTERNAL',
                message: 'Unexpected error at line $lineNumber: $e',
                details: {'line': lineNumber, 'raw': trimmed},
                debugLog: debugLog,
              );
              _killProcess(process, debugLog);
            }
          },
          onError: (Object error) {
            debugLog?.call('[CLI] stdout error: $error');
            _emitErrorAndClose(
              controller: controller,
              sessionId: currentSessionId ?? _generateSessionId(),
              code: '500_INTERNAL',
              message: 'stdout read error: $error',
              debugLog: debugLog,
            );
            _killProcess(process, debugLog);
          },
          onDone: () {
            debugLog?.call('[CLI] stdout closed');
          },
          cancelOnError: false,
        );

        // 监听 stderr（缓存最近 50 行）
        stderrSubscription = process!.stderr
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            stderrBuffer.add(line);
            if (stderrBuffer.length > maxStderrLines) {
              stderrBuffer.removeAt(0);
            }
            debugLog?.call('[CLI] stderr: $line');
          },
          cancelOnError: false,
        );

        // 监听进程退出
        final exitCode = await process!.exitCode;
        debugLog?.call('[CLI] Process exited with code $exitCode');

        if (exitCode != 0 && !controller.isClosed) {
          _emitErrorAndClose(
            controller: controller,
            sessionId: currentSessionId ?? _generateSessionId(),
            code: '500_CLI_EXIT_$exitCode',
            message: 'CLI process exited with code $exitCode',
            details: {'exitCode': exitCode, 'stderrTail': stderrBuffer},
            debugLog: debugLog,
          );
        } else if (!controller.isClosed) {
          // 正常退出但未收到 DONE 事件
          controller.close();
        }
      } catch (e) {
        debugLog?.call('[CLI] Failed to start process: $e');
        _emitErrorAndClose(
          controller: controller,
          sessionId: currentSessionId ?? _generateSessionId(),
          code: '500_INTERNAL',
          message: 'Failed to start CLI process: $e',
          debugLog: debugLog,
        );
      }
    },
    onCancel: () {
      debugLog?.call('[CLI] Stream cancelled, cleaning up');
      warmupTimer?.cancel();
      stdoutSubscription?.cancel();
      stderrSubscription?.cancel();
      _killProcess(process, debugLog);
    },
  );

  return controller.stream;
}

// ============================================================================
// 公开接口 3: 从 Isolate 读取事件
// ============================================================================

/// 从 Isolate 读取分析事件流
///
/// 参数:
/// - [inputPath]: 输入视频路径
/// - [sessionRoot]: 输出目录
/// - [configPath]: 配置文件路径
/// - [sessionId]: 可选会话 ID
/// - [debugLog]: 可选调试日志回调
///
/// 返回: 广播流，发出 Map<String, dynamic> 事件
///
/// 行为:
/// - 在新 Isolate 中执行分析逻辑（需要 CLI 代码支持 Isolate 入口）
/// - 通过 ReceivePort 接收事件
/// - 收到 DONE 或 ERROR 后关闭流并销毁 Isolate
/// - 取消订阅时强杀 Isolate
///
/// 注意: 此实现为桩，需要 CLI 提供 Isolate 入口函数
Stream<Map<String, dynamic>> analysisEventsFromIsolate({
  required String inputPath,
  required String sessionRoot,
  required String configPath,
  String? sessionId,
  Strictness? strictness,
  void Function(String msg)? debugLog,
}) {
  // 注意: ML Kit 和 VideoPlayer 需要主 Isolate，所以这里不使用真正的 Isolate
  // 而是在主线程中异步运行，通过 VideoAnalysisService 生成事件流
  
  debugLog?.call('[VideoAnalysis] Starting video analysis: $inputPath');
  
  final currentSessionId = sessionId ?? _generateSessionId();
  
  // ✅ 创建临时取消令牌（用于 Isolate 模式）
  // 注意：此模式下的取消需要通过 stream 取消订阅来触发
  final token = CancellationToken(
    id: currentSessionId,
    sessionId: currentSessionId,
  );
  
  // 使用传入的 strictness，或默认为 relaxed
  final effectiveStrictness = strictness ?? Strictness.relaxed;
  debugLog?.call('[VideoAnalysis] Using strictness: ${effectiveStrictness.value}');
  
  // ✅ VideoAnalysisService.analyzeVideo() 现在返回 record，需要提取 stream
  final result = VideoAnalysisService.analyzeVideo(
    token: token,
    strictness: effectiveStrictness,
    videoPath: inputPath,
    sessionRoot: sessionRoot,
    configPath: configPath,
    sessionId: currentSessionId,
  );
  
  return result.stream;
}

// ============================================================================
// 私有辅助函数：事件校验
// ============================================================================

/// 校验事件是否符合契约
void _validateEvent(Map<String, dynamic> event) {
  // 1. 必须有 event 字段
  if (!event.containsKey('event') || event['event'] is! String) {
    throw ContractViolation('Missing or invalid "event" field');
  }

  final eventName = event['event'] as String;

  // 2. 校验已知事件类型
  const validEvents = {'START', 'PHASE', 'PROGRESS', 'METRIC', 'EVIDENCE', 'DONE', 'ERROR'};
  if (!validEvents.contains(eventName)) {
    throw ContractViolation('Unknown event type: $eventName');
  }

  // 3. START 特定字段
  if (eventName == 'START') {
    if (!event.containsKey('input') || event['input'] is! Map) {
      throw ContractViolation('START event missing "input" object');
    }
    if (!event.containsKey('params') || event['params'] is! Map) {
      throw ContractViolation('START event missing "params" object');
    }
  }

  // 4. PROGRESS 特定字段
  if (eventName == 'PROGRESS') {
    if (!event.containsKey('processed') || event['processed'] is! num) {
      throw ContractViolation('PROGRESS event missing "processed" number');
    }
    if (!event.containsKey('total') || event['total'] is! num) {
      throw ContractViolation('PROGRESS event missing "total" number');
    }
    if ((event['processed'] as num) < 0 || (event['total'] as num) < 0) {
      throw ContractViolation('PROGRESS numbers must be non-negative');
    }
  }

  // 5. DONE 特定字段
  if (eventName == 'DONE') {
    if (!event.containsKey('artifacts') || event['artifacts'] is! Map) {
      throw ContractViolation('DONE event missing "artifacts" object');
    }
    final artifacts = event['artifacts'] as Map;
    if (!artifacts.containsKey('root') || artifacts['root'] is! String || (artifacts['root'] as String).isEmpty) {
      throw ContractViolation('DONE event missing "artifacts.root" string');
    }
  }

  // 6. ERROR 特定字段
  if (eventName == 'ERROR') {
    if (!event.containsKey('code') || event['code'] is! String) {
      throw ContractViolation('ERROR event missing "code" string');
    }
    if (!event.containsKey('message') || event['message'] is! String) {
      throw ContractViolation('ERROR event missing "message" string');
    }
  }

  // 7. 禁止 NaN/Infinity
  _checkForInvalidNumbers(event);
}

/// 递归检查对象中是否有 NaN/Infinity
void _checkForInvalidNumbers(dynamic obj) {
  if (obj is num) {
    if (obj.isNaN || obj.isInfinite) {
      throw ContractViolation('Event contains NaN or Infinity');
    }
  } else if (obj is Map) {
    for (final value in obj.values) {
      _checkForInvalidNumbers(value);
    }
  } else if (obj is List) {
    for (final item in obj) {
      _checkForInvalidNumbers(item);
    }
  }
}

// ============================================================================
// 私有辅助函数：错误处理
// ============================================================================

/// 发出标准 ERROR 事件并关闭流
void _emitErrorAndClose({
  required StreamController<Map<String, dynamic>> controller,
  required String sessionId,
  required String code,
  required String message,
  Map<String, dynamic>? details,
  void Function(String msg)? debugLog,
}) {
  if (controller.isClosed) return;

  debugLog?.call('[ERROR] $code: $message');

  final errorEvent = <String, dynamic>{
    'event': 'ERROR',
    'sessionId': sessionId,
    'code': code,
    'message': message,
  };

  if (details != null) {
    errorEvent['details'] = details;
  }

  controller.add(errorEvent);
  controller.close();
}

// ============================================================================
// 私有辅助函数：资源释放
// ============================================================================

/// 优雅终止子进程（2 秒超时后强杀）
void _killProcess(Process? process, void Function(String msg)? debugLog) {
  if (process == null) return;

  debugLog?.call('[CLI] Terminating process PID ${process.pid}');

  // 尝试优雅终止
  process.kill(ProcessSignal.sigterm);

  // 2 秒后强杀
  Timer(const Duration(seconds: 2), () {
    try {
      process.kill(ProcessSignal.sigkill);
      debugLog?.call('[CLI] Force killed process PID ${process.pid}');
    } catch (e) {
      debugLog?.call('[CLI] Failed to kill process: $e');
    }
  });
}

// ============================================================================
// 私有辅助函数：会话 ID 生成
// ============================================================================

/// 生成唯一会话 ID（格式: yyyyMMdd_HHmmss_<rand>）
String _generateSessionId() {
  final now = DateTime.now();
  final dateStr = now.toIso8601String().substring(0, 10).replaceAll('-', '');
  final timeStr = '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
  final rand = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
  return '${dateStr}_${timeStr}_$rand';
}

// ============================================================================
// 演示用 JSONL 示例（保存为 dev/stdout_demo.jsonl）
// ============================================================================
/*
{"event":"START","sessionId":"demo_session_001",
 "input":{"path":"(mock)/squat.mp4","durationMs":32000,"fps":30,"resolution":"1280x720"},
 "params":{"stride":2,"engine":"MoveNet","strictness":"strict"}}
{"event":"PHASE","phase":"decode"}
{"event":"PROGRESS","phase":"infer","processed":240,"total":960,"p95MsPerFrame":32,"etaSec":18}
{"event":"PROGRESS","phase":"analyze","processed":480,"total":960,"p95MsPerFrame":33,"etaSec":9}
{"event":"METRIC","lowConfidenceRatio":0.24,"usableFrameRatio":0.76}
{"event":"EVIDENCE","frame":612,"t":"00:00:20.4","files":["evidence/frame_612.jpg"]}
{"event":"DONE","artifacts":{"root":"build/offline_out/2025_demo_session/","files":["result.json","logs/perf.json"]}}
*/

// ============================================================================
// 错误事件标准格式示例
// ============================================================================
/*
{
  "event": "ERROR",
  "sessionId": "20251028_103045_a1b2",
  "code": "400_PARSE | 422_CONTRACT | 500_CLI_EXIT_<code> | 500_INTERNAL | 408_WARMUP_TIMEOUT | 404_FILE_NOT_FOUND | 501_NOT_IMPLEMENTED",
  "message": "Human readable error message",
  "details": {
    "line": 12,
    "raw": "malformed json...",
    "cause": "FormatException: ...",
    "stderrTail": ["stderr line 1", "stderr line 2"],
    "exitCode": 1
  }
}
*/

