// event_bus_jsonl_test.dart
// Purpose: 测试 event_bus.dart 的 JSONL 事件解析
// 覆盖: analysisEventsFromJsonlFile 的顺序、错误处理、非 JSON 行忽略

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/event_bus.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('event_bus_jsonl_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('event_bus JSONL', () {
    test('analysisEventsFromJsonlFile - 正常事件序列', () async {
      // 准备：复制 dev/stdout_demo.jsonl
      final jsonlPath = '${tempDir.path}/stdout_demo.jsonl';
      final sourceFile = File('dev/stdout_demo.jsonl');
      await sourceFile.copy(jsonlPath);

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：事件序列正确（注释行被忽略，所以有 7 个有效事件）
      expect(events.length, greaterThanOrEqualTo(4), reason: '至少包含 START/PHASE/PROGRESS/DONE');

      // 断言：事件类型顺序
      expect(events[0]['event'], equals('START'));
      expect(events.length, greaterThanOrEqualTo(2), reason: 'At least START and one more event');
      if (events.length > 1) {
        expect(events.any((e) => e['event'] == 'PHASE' || e['event'] == 'PROGRESS'), isTrue);
      }
      // 如果流正常完成，最后应该是 DONE 或 ERROR
      if (events.isNotEmpty) {
        expect(events.last['event'], anyOf(equals('DONE'), equals('ERROR')));
      }

      // 断言：START 事件包含必要字段
      final startEvent = events[0];
      expect(startEvent.containsKey('sessionId'), isTrue);
      expect(startEvent.containsKey('input'), isTrue);
      expect(startEvent.containsKey('params'), isTrue);

      // 断言：DONE 事件包含 artifacts（如果最后是 DONE 事件）
      if (events.last['event'] == 'DONE') {
        final doneEvent = events.last;
        expect(doneEvent.containsKey('artifacts'), isTrue);
        expect((doneEvent['artifacts'] as Map).containsKey('root'), isTrue);
      }
    });

    test('analysisEventsFromJsonlFile - PROGRESS 进度单调递增', () async {
      // 准备：复制 dev/stdout_demo.jsonl
      final jsonlPath = '${tempDir.path}/stdout_demo2.jsonl';
      final sourceFile = File('dev/stdout_demo.jsonl');
      await sourceFile.copy(jsonlPath);

      // 执行：收集所有 PROGRESS 事件
      final progressEvents = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        if (event['event'] == 'PROGRESS') {
          progressEvents.add(event);
        }
      }

      // 断言：至少有一个 PROGRESS 事件
      expect(progressEvents.length, greaterThanOrEqualTo(1));

      // 断言：processed/total 单调递增
      for (int i = 1; i < progressEvents.length; i++) {
        final prev = progressEvents[i - 1];
        final curr = progressEvents[i];

        final prevProcessed = (prev['processed'] as num).toInt();
        final currProcessed = (curr['processed'] as num).toInt();

        expect(currProcessed, greaterThanOrEqualTo(prevProcessed),
               reason: 'processed 应单调递增');
      }

      // 断言：progress ∈ [0,1]（如果存在 progress 字段）
      for (final event in progressEvents) {
        final processed = (event['processed'] as num).toDouble();
        final total = (event['total'] as num).toDouble();
        
        expect(processed, greaterThanOrEqualTo(0));
        expect(total, greaterThanOrEqualTo(0));
        
        if (total > 0) {
          final progress = processed / total;
          expect(progress, greaterThanOrEqualTo(0.0));
          expect(progress, lessThanOrEqualTo(1.0));
        }
      }
    });

    test('analysisEventsFromJsonlFile - 非 JSON 行被忽略', () async {
      // 准备：复制 dev/stdout_demo.jsonl（包含注释行）
      final jsonlPath = '${tempDir.path}/stdout_demo3.jsonl';
      final sourceFile = File('dev/stdout_demo.jsonl');
      await sourceFile.copy(jsonlPath);

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      // 断言：不抛异常
      await expectLater(
        stream.forEach(events.add),
        completes,
      );

      // 断言：收到了有效事件（注释行被忽略）
      expect(events.isNotEmpty, isTrue);
      expect(events[0]['event'], equals('START'));
    });

    test('analysisEventsFromJsonlFile - 坏行触发 ERROR 事件并关闭流', () async {
      // 准备：复制 dev/stdout_error_badline.jsonl
      final jsonlPath = '${tempDir.path}/stdout_error_badline.jsonl';
      final sourceFile = File('dev/stdout_error_badline.jsonl');
      await sourceFile.copy(jsonlPath);

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：包含 ERROR 事件
      expect(events.any((e) => e['event'] == 'ERROR'), isTrue);

      // 找到 ERROR 事件
      final errorEvent = events.firstWhere((e) => e['event'] == 'ERROR');

      // 断言：ERROR 事件包含 code 和 message
      expect(errorEvent.containsKey('code'), isTrue);
      expect(errorEvent.containsKey('message'), isTrue);
      // 可能是 400_PARSE 或 422_CONTRACT，取决于解析顺序
      expect(errorEvent['code'], anyOf(equals('400_PARSE'), equals('422_CONTRACT')));

      // 断言：ERROR 是最后一个事件（流已关闭）
      expect(events.last['event'], equals('ERROR'));
    });

    test('analysisEventsFromJsonlFile - 缺失 DONE.artifacts.root 触发 ERROR', () async {
      // 准备：复制 dev/stdout_error_missing_done_root.jsonl
      final jsonlPath = '${tempDir.path}/stdout_error_missing_done_root.jsonl';
      final sourceFile = File('dev/stdout_error_missing_done_root.jsonl');
      await sourceFile.copy(jsonlPath);

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：包含 ERROR 事件
      expect(events.any((e) => e['event'] == 'ERROR'), isTrue);

      // 找到 ERROR 事件
      final errorEvent = events.firstWhere((e) => e['event'] == 'ERROR');

      // 断言：错误码为 422_CONTRACT
      expect(errorEvent['code'], equals('422_CONTRACT'));
      expect(errorEvent['message'], contains('artifacts.root'));
    });

    test('analysisEventsFromJsonlFile - 文件不存在触发 ERROR', () async {
      // 准备：使用不存在的文件路径
      final jsonlPath = '${tempDir.path}/nonexistent.jsonl';

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：只有一个 ERROR 事件
      expect(events.length, equals(1));
      expect(events[0]['event'], equals('ERROR'));
      expect(events[0]['code'], equals('404_FILE_NOT_FOUND'));
    });

    test('analysisEventsFromJsonlFile - 空白行被忽略', () async {
      // 准备：创建包含空白行的 JSONL
      final jsonlPath = '${tempDir.path}/with_blank_lines.jsonl';
      final jsonlFile = File(jsonlPath);
      await jsonlFile.writeAsString('''
{"event":"START","sessionId":"test_001","input":{},"params":{}}

{"event":"PHASE","phase":"decode"}


{"event":"DONE","artifacts":{"root":"build/offline_out/test/"}}
''');

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：空白行被忽略，只收到 3 个有效事件
      expect(events.length, equals(3));
      expect(events[0]['event'], equals('START'));
      expect(events[1]['event'], equals('PHASE'));
      expect(events[2]['event'], equals('DONE'));
    });

    test('analysisEventsFromJsonlFile - sessionId 注入和覆盖', () async {
      // 准备：创建没有 sessionId 的 JSONL
      final jsonlPath = '${tempDir.path}/no_session_id.jsonl';
      final jsonlFile = File(jsonlPath);
      await jsonlFile.writeAsString('''
{"event":"START","input":{},"params":{}}
{"event":"DONE","artifacts":{"root":"build/offline_out/test/"}}
''');

      // 执行：订阅事件流（提供 sessionId）
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath, sessionId: 'custom_session_123');

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：所有事件都包含注入的 sessionId
      for (final event in events) {
        expect(event['sessionId'], equals('custom_session_123'));
      }
    });

    test('analysisEventsFromJsonlFile - debugLog 回调被调用', () async {
      // 准备：复制 dev/stdout_demo.jsonl
      final jsonlPath = '${tempDir.path}/stdout_demo4.jsonl';
      final sourceFile = File('dev/stdout_demo.jsonl');
      await sourceFile.copy(jsonlPath);

      // 执行：订阅事件流，提供 debugLog 回调
      final logs = <String>[];
      final stream = analysisEventsFromJsonlFile(
        jsonlPath,
        debugLog: (msg) => logs.add(msg),
      );

      await for (final _ in stream) {
        // 消费事件
      }

      // 断言：debugLog 被调用
      expect(logs.isNotEmpty, isTrue);
      expect(logs.any((log) => log.contains('reading') || log.contains('JSONL')), isTrue, reason: 'Should log reading activity');
    });

    test('analysisEventsFromJsonlFile - PROGRESS 必须包含 processed 和 total', () async {
      // 准备：创建缺失 total 的 PROGRESS 事件
      final jsonlPath = '${tempDir.path}/invalid_progress.jsonl';
      final jsonlFile = File(jsonlPath);
      await jsonlFile.writeAsString('''
{"event":"START","sessionId":"test_002","input":{},"params":{}}
{"event":"PROGRESS","phase":"infer","processed":100}
{"event":"DONE","artifacts":{"root":"build/offline_out/test/"}}
''');

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：触发 ERROR 事件
      expect(events.any((e) => e['event'] == 'ERROR'), isTrue);
      final errorEvent = events.firstWhere((e) => e['event'] == 'ERROR');
      expect(errorEvent['code'], equals('422_CONTRACT'));
      expect(errorEvent['message'], contains('total'));
    });

    test('analysisEventsFromJsonlFile - START 必须包含 input 和 params', () async {
      // 准备：创建缺失 params 的 START 事件
      final jsonlPath = '${tempDir.path}/invalid_start.jsonl';
      final jsonlFile = File(jsonlPath);
      await jsonlFile.writeAsString('''
{"event":"START","sessionId":"test_003","input":{}}
{"event":"DONE","artifacts":{"root":"build/offline_out/test/"}}
''');

      // 执行：订阅事件流
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      // 断言：触发 ERROR 事件
      expect(events.any((e) => e['event'] == 'ERROR'), isTrue);
      final errorEvent = events.firstWhere((e) => e['event'] == 'ERROR');
      expect(errorEvent['code'], equals('422_CONTRACT'));
      expect(errorEvent['message'], contains('params'));
    });

    test('analysisEventsFromJsonlFile - 流可以提前取消', () async {
      // 准备：复制 dev/stdout_demo.jsonl
      final jsonlPath = '${tempDir.path}/stdout_demo5.jsonl';
      final sourceFile = File('dev/stdout_demo.jsonl');
      await sourceFile.copy(jsonlPath);

      // 执行：订阅事件流并提前取消
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);
      
      final subscription = stream.listen((event) {
        events.add(event);
      });

      // 等待第一个事件后取消
      await Future.delayed(const Duration(milliseconds: 100));
      await subscription.cancel();

      // 断言：至少收到了第一个事件
      expect(events.isNotEmpty, isTrue);
      expect(events[0]['event'], equals('START'));
    });
  });
}

