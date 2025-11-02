// result_adapter_test.dart
// 单元测试：result_adapter.dart 与 evidence_resolver.dart
//
// 验收条件（DoD）：
// 1. happy path: 完整 result.json 正确映射
// 2. snapshot 缺失: 降级到 window
// 3. scores 缺字段: 抛 SchemaMismatch
// 4. repCount 缺失: 抛 SchemaMismatch
// 5. 数值越界/类型错: 抛 SchemaMismatch
// 6. 文件缺失/JSON 解析失败: 抛 ResultReadException

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/adapters/result_adapter.dart';
import '../lib/adapters/evidence_resolver.dart';

void main() {
  group('Result Adapter - Basic Tests', () {
    // 测试 1: Happy Path - 完整的 result.json
    test('Should map complete result.json correctly', () {
      final raw = {
        'version': '2.0',
        'scores': {
          'form': 84,
          'stability': 77,
          'tempo': 71,
          'overall': 78,
        },
        'repCount': 12,
        'quality': {
          'lowConfidence': false,
          'coverage': 0.76,
        },
        'meta': {
          'template': 'squat',
          'strictness': 'strict',
          'engine': 'MoveNet',
          'fps': 30,
        },
        'evidence': [
          {
            'snapshotPath': 'evidence/frame_612.jpg',
            'window': {'startMs': 20000, 'endMs': 21000},
          }
        ],
      };

      // 校验契约
      assertResultContract(raw);

      // 映射为轻量模型
      final lite = mapToLite(raw);

      // 验证：分数映射正确（form→posture, tempo→rhythm）
      expect(lite.posture, equals(84), reason: 'posture should map from scores.form');
      expect(lite.stability, equals(77));
      expect(lite.rhythm, equals(71), reason: 'rhythm should map from scores.tempo');
      expect(lite.total, equals(78), reason: 'total should map from scores.overall');

      // 验证：次数
      expect(lite.reps, equals(12));

      // 验证：证据路径
      expect(lite.evidencePath, equals('evidence/frame_612.jpg'));

      // 验证：质量指标
      expect(lite.lowConfidence, equals(false));
      expect(lite.coverage, equals(0.76));

      // 验证：元信息
      expect(lite.templateName, equals('squat'));
      expect(lite.strictness, equals('strict'));
      expect(lite.engine, equals('MoveNet'));
      expect(lite.fps, equals(30));
    });

    // 测试 2: Snapshot 缺失，降级到 Window
    test('Should fallback to window when snapshot missing', () {
      final raw = {
        'scores': {'form': 60, 'stability': 58, 'tempo': 65, 'overall': 61},
        'repCount': 8,
        'meta': {'template': 'squat'},
        'evidence': [
          {
            'window': {'startMs': 12000, 'endMs': 12750},
          }
        ],
      };

      // 校验契约
      assertResultContract(raw);

      // 验证：snapshot 为 null（缺失）
      final snapshot = resolveSnapshotPath(raw);
      expect(snapshot, isNull, reason: 'snapshot should be null when missing');

      // 验证：window 降级策略
      final window = resolveEvidenceWindow(raw);
      expect(window, isNotNull, reason: 'window should exist');
      expect(window?.startMs, equals(12000));
      expect(window?.endMs, equals(12750));

      // 验证：evidencePath 为 null
      final lite = mapToLite(raw);
      expect(lite.evidencePath, isNull);
    });

    // 测试 3: scores.form 缺失（契约违反）
    test('Should throw SchemaMismatch when scores.form missing', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{
          'stability': 77,
          'tempo': 71,
          'overall': 78,
          // 'form' 缺失
        },
        'repCount': 12,
        'meta': <String, dynamic>{},
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('scores.form missing'),
        )),
      );
    });

    // 测试 4: repCount 缺失（契约违反）
    test('Should throw SchemaMismatch when repCount missing', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        // 'repCount' 缺失
        'meta': <String, dynamic>{},
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('repCount missing'),
        )),
      );
    });

    // 测试 5a: scores.overall 越界（>100）
    test('Should throw SchemaMismatch when scores.overall out of range', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 120},
        'repCount': 12,
        'meta': <String, dynamic>{},
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('out of range'),
        )),
      );
    });

    // 测试 5b: repCount 为负数
    test('Should throw SchemaMismatch when repCount negative', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': -1,
        'meta': <String, dynamic>{},
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('non-negative'),
        )),
      );
    });

    // 测试 5c: scores.form 类型错误（字符串）
    test('Should throw SchemaMismatch when scores.form is not number', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 'invalid', 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{},
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('must be number'),
        )),
      );
    });

    // 测试 6: 浮点数分数（应该取整）
    test('Should round floating point scores', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84.7, 'stability': 77.3, 'tempo': 71.5, 'overall': 78.2},
        'repCount': 12.9,
        'meta': <String, dynamic>{},
      };

      assertResultContract(raw);
      final lite = mapToLite(raw);

      // 验证：使用 round() 取整
      expect(lite.posture, equals(85), reason: '84.7 rounds to 85');
      expect(lite.stability, equals(77), reason: '77.3 rounds to 77');
      expect(lite.rhythm, equals(72), reason: '71.5 rounds to 72');
      expect(lite.total, equals(78), reason: '78.2 rounds to 78');
      expect(lite.reps, equals(13), reason: '12.9 rounds to 13');
    });

    // 测试 7: coverage 越界（应该截断）
    test('Should clamp coverage to [0, 1]', () {
      final raw1 = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'quality': <String, dynamic>{'coverage': 1.5}, // >1
        'meta': <String, dynamic>{},
      };

      final lite1 = mapToLite(raw1);
      expect(lite1.coverage, equals(1.0), reason: 'coverage should be clamped to 1.0');

      final raw2 = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'quality': <String, dynamic>{'coverage': -0.2}, // <0
        'meta': <String, dynamic>{},
      };

      final lite2 = mapToLite(raw2);
      expect(lite2.coverage, equals(0.0), reason: 'coverage should be clamped to 0.0');
    });

    // 测试 8: meta 对象缺失（契约违反）
    test('Should throw SchemaMismatch when meta object missing', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        // 'meta' 缺失
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('meta'),
        )),
      );
    });

    // 测试 9: meta 子字段缺失（可容忍，不抛错）
    test('Should tolerate missing meta subfields', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{}, // 子字段全部缺失
      };

      // 验证：不抛异常
      assertResultContract(raw);

      final lite = mapToLite(raw);

      // 验证：可选字段为 null
      expect(lite.templateName, isNull);
      expect(lite.strictness, isNull);
      expect(lite.engine, isNull);
      expect(lite.fps, isNull);
    });

    // 测试 10: evidence 数组为空（可容忍，降级）
    test('Should handle empty evidence array gracefully', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{},
        'evidence': <Map<String, dynamic>>[], // 空数组
      };

      assertResultContract(raw);

      // 验证：snapshot 为 null
      final snapshot = resolveSnapshotPath(raw);
      expect(snapshot, isNull);

      // 验证：window 为 null
      final window = resolveEvidenceWindow(raw);
      expect(window, isNull);

      // 验证：evidencePath 为 null
      final lite = mapToLite(raw);
      expect(lite.evidencePath, isNull);
    });

    // 测试 11: evidence 缺失（可容忍，降级）
    test('Should handle missing evidence gracefully', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{},
        // 'evidence' 缺失
      };

      assertResultContract(raw);

      // 验证：snapshot 为 null
      final snapshot = resolveSnapshotPath(raw);
      expect(snapshot, isNull);

      // 验证：window 为 null
      final window = resolveEvidenceWindow(raw);
      expect(window, isNull);

      // 验证：evidencePath 为 null
      final lite = mapToLite(raw);
      expect(lite.evidencePath, isNull);
    });

    // 测试 12: snapshotPath 为空字符串（应降级）
    test('Should treat empty snapshotPath as null', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{},
        'evidence': <Map<String, dynamic>>[
          <String, dynamic>{'snapshotPath': '   '}, // 全空白
        ],
      };

      // 验证：snapshot 为 null（空白字符串）
      final snapshot = resolveSnapshotPath(raw);
      expect(snapshot, isNull);

      final lite = mapToLite(raw);
      expect(lite.evidencePath, isNull);
    });

    // 测试 13: window 非法（endMs <= startMs）
    test('Should reject invalid window (endMs <= startMs)', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{},
        'evidence': <Map<String, dynamic>>[
          <String, dynamic>{'window': <String, dynamic>{'startMs': 1000, 'endMs': 1000}}, // 相等
        ],
      };

      // 验证：window 为 null（非法）
      final window = resolveEvidenceWindow(raw);
      expect(window, isNull, reason: 'endMs must be greater than startMs');
    });

    // 测试 14: window 负数时间（非法）
    test('Should reject negative startMs', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{},
        'evidence': <Map<String, dynamic>>[
          <String, dynamic>{'window': <String, dynamic>{'startMs': -100, 'endMs': 1000}}, // 负数
        ],
      };

      // 验证：window 为 null（非法）
      final window = resolveEvidenceWindow(raw);
      expect(window, isNull, reason: 'startMs must be non-negative');
    });

    // 测试 15: NaN/Infinity 检测
    test('Should reject NaN in scores', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': double.nan, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': <String, dynamic>{},
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('NaN'),
        )),
      );
    });

    test('Should reject Infinity in repCount', () {
      final raw = <String, dynamic>{
        'scores': <String, dynamic>{'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': double.infinity,
        'meta': <String, dynamic>{},
      };

      // 验证：抛出 SchemaMismatch
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('Infinity'),
        )),
      );
    });
  });

  group('Result Adapter - File I/O Tests', () {
    const testDir = 'test_output';
    final sessionRoot = '$testDir/test_session';

    setUp(() async {
      // 创建测试目录
      await Directory(sessionRoot).create(recursive: true);
    });

    tearDown(() async {
      // 清理测试目录
      if (await Directory(testDir).exists()) {
        await Directory(testDir).delete(recursive: true);
      }
    });

    // 测试 16: 正常读取 result.json
    test('Should read result.json successfully', () async {
      // 创建测试文件
      final testData = {
        'scores': {'form': 84, 'stability': 77, 'tempo': 71, 'overall': 78},
        'repCount': 12,
        'meta': {'template': 'squat'},
      };

      final file = File('$sessionRoot/result.json');
      await file.writeAsString(_jsonEncode(testData));

      // 读取并验证
      final raw = await readResultJson(sessionRoot);
      expect(raw['scores'], isA<Map<dynamic, dynamic>>());
      expect(raw['repCount'], equals(12));
    });

    // 测试 17: 文件不存在
    test('Should throw ResultReadException when file not found', () async {
      // 验证：抛出 ResultReadException
      expect(
        () => readResultJson('$testDir/non_existent'),
        throwsA(isA<ResultReadException>().having(
          (e) => e.message,
          'message',
          contains('not found'),
        )),
      );
    });

    // 测试 18: JSON 解析失败
    test('Should throw ResultReadException on invalid JSON', () async {
      // 创建无效 JSON 文件
      final file = File('$sessionRoot/result.json');
      await file.writeAsString('{ invalid json }');

      // 验证：抛出 ResultReadException
      expect(
        () => readResultJson(sessionRoot),
        throwsA(isA<ResultReadException>().having(
          (e) => e.message,
          'message',
          contains('parse failed'),
        )),
      );
    });

    // 测试 19: 非对象 JSON（数组）
    test('Should throw ResultReadException when JSON is not object', () async {
      // 创建数组 JSON
      final file = File('$sessionRoot/result.json');
      await file.writeAsString('[1, 2, 3]');

      // 验证：抛出 ResultReadException
      expect(
        () => readResultJson(sessionRoot),
        throwsA(isA<ResultReadException>().having(
          (e) => e.message,
          'message',
          contains('not a JSON object'),
        )),
      );
    });
  });

  group('Evidence Resolver - Detailed Tests', () {
    // 测试 20: 快照路径优先级最高
    test('Should prioritize snapshot over window', () {
      final raw = {
        'evidence': [
          {
            'snapshotPath': 'evidence/frame_100.jpg',
            'window': {'startMs': 1000, 'endMs': 2000},
          }
        ],
      };

      // 验证：快照路径存在
      final snapshot = resolveSnapshotPath(raw);
      expect(snapshot, equals('evidence/frame_100.jpg'));

      // 验证：window 也存在（但优先级低）
      final window = resolveEvidenceWindow(raw);
      expect(window, isNotNull);
    });

    // 测试 21: 快照路径 trim 处理
    test('Should trim snapshot path whitespace', () {
      final raw = {
        'evidence': [
          {'snapshotPath': '  evidence/frame_100.jpg  '},
        ],
      };

      final snapshot = resolveSnapshotPath(raw);
      expect(snapshot, equals('evidence/frame_100.jpg'));
    });

    // 测试 22: window 浮点数时间（应取整）
    test('Should round window timestamps', () {
      final raw = {
        'evidence': [
          {'window': {'startMs': 1000.7, 'endMs': 2000.3}},
        ],
      };

      final window = resolveEvidenceWindow(raw);
      expect(window?.startMs, equals(1001), reason: '1000.7 rounds to 1001');
      expect(window?.endMs, equals(2000), reason: '2000.3 rounds to 2000');
    });
  });

  group('Exception Classes', () {
    test('SchemaMismatch should format correctly', () {
      final exception = SchemaMismatch('test message');

      expect(exception.toString(), contains('SchemaMismatch'));
      expect(exception.toString(), contains('test message'));
      expect(exception.message, equals('test message'));
    });

    test('ResultReadException should format correctly', () {
      final exception = ResultReadException('test error', cause: 'cause info');

      expect(exception.toString(), contains('ResultReadException'));
      expect(exception.toString(), contains('test error'));
      expect(exception.toString(), contains('cause info'));
      expect(exception.message, equals('test error'));
      expect(exception.cause, equals('cause info'));
    });
  });
}

// 辅助函数：将 Map 编码为 JSON 字符串（手动实现，避免依赖）
String _jsonEncode(Map<String, dynamic> data) {
  final buffer = StringBuffer();
  buffer.write('{');

  var first = true;
  data.forEach((key, value) {
    if (!first) buffer.write(',');
    first = false;

    buffer.write('"$key":');

    if (value is Map) {
      buffer.write(_jsonEncode(value as Map<String, dynamic>));
    } else if (value is num) {
      buffer.write(value);
    } else if (value is String) {
      buffer.write('"$value"');
    } else {
      buffer.write('null');
    }
  });

  buffer.write('}');
  return buffer.toString();
}

