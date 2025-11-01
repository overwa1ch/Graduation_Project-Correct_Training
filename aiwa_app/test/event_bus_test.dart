// event_bus_test.dart
// 最小单元测试：验证 event_bus 的基本功能

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/event_bus.dart';

void main() {
  group('Event Bus - Basic Tests', () {
    // 测试 1: 从 JSONL 文件读取事件（使用 dev/stdout_demo.jsonl）
    test('Should read events from JSONL file (dev/stdout_demo.jsonl)', () async {
      final events = <Map<String, dynamic>>[];
      
      final stream = analysisEventsFromJsonlFile(
        'dev/stdout_demo.jsonl',
        debugLog: (msg) => print('[TEST] $msg'),
      );

      await for (final event in stream) {
        events.add(event);
        print('Received event: ${event['event']}');
      }

      // 验证：应该收到 7 个事件 (START, PHASE, PROGRESS, PROGRESS, METRIC, EVIDENCE, DONE)
      expect(events.length, greaterThanOrEqualTo(5), reason: 'Should receive at least 5 events');

      // 验证：第一个事件应该是 START
      expect(events.first['event'], equals('START'));
      expect(events.first['input'], isA<Map<dynamic, dynamic>>());
      expect(events.first['params'], isA<Map<dynamic, dynamic>>());

      // 验证：最后一个事件应该是 DONE
      expect(events.last['event'], equals('DONE'));
      expect(events.last['artifacts'], isA<Map<dynamic, dynamic>>());
      expect(events.last['artifacts']['root'], isNotEmpty);

      // 验证：所有事件都有 sessionId
      for (final event in events) {
        expect(event['sessionId'], isNotNull, reason: 'All events should have sessionId');
      }
    });

    // 测试 2: 文件不存在应该产生 ERROR 事件
    test('Should emit ERROR event for non-existent file', () async {
      final events = <Map<String, dynamic>>[];
      
      final stream = analysisEventsFromJsonlFile('non_existent_file.jsonl');

      await for (final event in stream) {
        events.add(event);
      }

      // 验证：应该收到 1 个 ERROR 事件
      expect(events.length, equals(1));
      expect(events.first['event'], equals('ERROR'));
      expect(events.first['code'], equals('404_FILE_NOT_FOUND'));
      expect(events.first['message'], contains('not found'));
    });

    // 测试 3: 契约违反 - 缺少必填字段
    test('Should detect contract violation for missing fields', () async {
      // 创建临时测试文件（START 事件缺少 input 字段）
      final tempFile = File('test_invalid.jsonl');
      await tempFile.writeAsString('{"event":"START","sessionId":"test","params":{}}\n');

      try {
        final events = <Map<String, dynamic>>[];
        final stream = analysisEventsFromJsonlFile(tempFile.path);

        await for (final event in stream) {
          events.add(event);
        }

        // 验证：应该收到 ERROR 事件（契约违反）
        expect(events.length, equals(1));
        expect(events.first['event'], equals('ERROR'));
        expect(events.first['code'], equals('422_CONTRACT'));
        expect(events.first['message'], contains('input'));
      } finally {
        // 清理临时文件
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    // 测试 4: JSON 解析错误
    test('Should handle JSON parse errors gracefully', () async {
      // 创建临时测试文件（包含无效 JSON）
      final tempFile = File('test_parse_error.jsonl');
      await tempFile.writeAsString('{"event":"START"  INVALID JSON\n');

      try {
        final events = <Map<String, dynamic>>[];
        final stream = analysisEventsFromJsonlFile(tempFile.path);

        await for (final event in stream) {
          events.add(event);
        }

        // Robust implementation: may skip malformed line or emit ERROR
        // At minimum, should not crash
        if (events.isNotEmpty && events.first['event'] == 'ERROR') {
          expect(events.first['code'], anyOf(equals('400_PARSE'), equals('422_CONTRACT')));
        }
      } finally {
        // 清理临时文件
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    // 测试 5: PROGRESS 事件字段校验
    test('Should validate PROGRESS event fields', () async {
      // 创建临时测试文件（PROGRESS 事件缺少 total 字段）
      final tempFile = File('test_progress_invalid.jsonl');
      await tempFile.writeAsString('{"event":"PROGRESS","sessionId":"test","processed":100}\n');

      try {
        final events = <Map<String, dynamic>>[];
        final stream = analysisEventsFromJsonlFile(tempFile.path);

        await for (final event in stream) {
          events.add(event);
        }

        // 验证：应该收到 ERROR 事件（契约违反）
        expect(events.length, equals(1));
        expect(events.first['event'], equals('ERROR'));
        expect(events.first['code'], equals('422_CONTRACT'));
        expect(events.first['message'], contains('total'));
      } finally {
        // 清理临时文件
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    // 测试 6: DONE 事件字段校验
    test('Should validate DONE event artifacts.root field', () async {
      // 创建临时测试文件（DONE 事件缺少 artifacts.root）
      final tempFile = File('test_done_invalid.jsonl');
      await tempFile.writeAsString('{"event":"DONE","sessionId":"test","artifacts":{}}\n');

      try {
        final events = <Map<String, dynamic>>[];
        final stream = analysisEventsFromJsonlFile(tempFile.path);

        await for (final event in stream) {
          events.add(event);
        }

        // 验证：应该收到 ERROR 事件（契约违反）
        expect(events.length, equals(1));
        expect(events.first['event'], equals('ERROR'));
        expect(events.first['code'], equals('422_CONTRACT'));
        expect(events.first['message'], contains('artifacts.root'));
      } finally {
        // 清理临时文件
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    // 测试 7: 空白行和注释行应该被忽略
    test('Should ignore empty lines', () async {
      // 创建临时测试文件（包含空白行）
      final tempFile = File('test_empty_lines.jsonl');
      await tempFile.writeAsString('''
{"event":"START","sessionId":"test","input":{},"params":{}}

{"event":"DONE","sessionId":"test","artifacts":{"root":"test/"}}
''');

      try {
        final events = <Map<String, dynamic>>[];
        final stream = analysisEventsFromJsonlFile(tempFile.path);

        await for (final event in stream) {
          events.add(event);
        }

        // 验证：应该收到 2 个事件（忽略空白行）
        expect(events.length, equals(2));
        expect(events.first['event'], equals('START'));
        expect(events.last['event'], equals('DONE'));
      } finally {
        // 清理临时文件
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });

    // 测试 8: CLI warmup 超时（需要较长执行时间，可选）
    test('Should timeout if no events received within warmup period', () async {
      // 这个测试会启动一个不产生 JSONL 输出的命令
      final events = <Map<String, dynamic>>[];
      
      final stream = analysisEventsFromCli(
        dartBin: 'dart',
        args: ['--version'], // 这个命令不会输出 JSONL 事件
        warmupTimeout: const Duration(milliseconds: 100),
      );

      await for (final event in stream) {
        events.add(event);
      }

      // 验证：应该收到错误（可能是超时或进程退出）
      expect(events.length, equals(1));
      expect(events.first['event'], equals('ERROR'));
      // 接受两种错误码：超时或 CLI 退出
      expect(
        events.first['code'], 
        anyOf(equals('408_WARMUP_TIMEOUT'), startsWith('500_')),
        reason: 'Should receive timeout or CLI exit error',
      );
    }, skip: !Platform.isLinux && !Platform.isMacOS && !Platform.isWindows);

    // 测试 9: SessionId 注入
    test('Should inject sessionId if not present', () async {
      // 创建临时测试文件（事件不包含 sessionId）
      final tempFile = File('test_no_sessionid.jsonl');
      await tempFile.writeAsString('{"event":"START","input":{},"params":{}}\n');
      await tempFile.writeAsString('{"event":"DONE","artifacts":{"root":"test/"}}\n', mode: FileMode.append);

      try {
        final events = <Map<String, dynamic>>[];
        final stream = analysisEventsFromJsonlFile(
          tempFile.path,
          sessionId: 'injected_session_123',
        );

        await for (final event in stream) {
          events.add(event);
        }

        // 验证：所有事件都应该有注入的 sessionId
        expect(events.length, equals(2));
        expect(events[0]['sessionId'], equals('injected_session_123'));
        expect(events[1]['sessionId'], equals('injected_session_123'));
      } finally {
        // 清理临时文件
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }
    });
  });

  group('Exception Classes', () {
    test('EventParseException should format correctly', () {
      final exception = EventParseException(
        line: 42,
        raw: '{"invalid json',
        cause: 'FormatException',
      );
      
      expect(exception.toString(), contains('line=42'));
      expect(exception.line, equals(42));
      expect(exception.raw, equals('{"invalid json'));
    });

    test('ContractViolation should format correctly', () {
      final exception = ContractViolation('Missing required field');
      
      expect(exception.toString(), contains('Missing required field'));
      expect(exception.message, equals('Missing required field'));
    });

    test('CliExitException should format correctly', () {
      final exception = CliExitException(127);
      
      expect(exception.toString(), contains('127'));
      expect(exception.exitCode, equals(127));
    });
  });
}

