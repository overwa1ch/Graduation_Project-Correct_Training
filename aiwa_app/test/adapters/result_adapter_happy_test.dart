// result_adapter_happy_test.dart
// Purpose: 测试 result_adapter.dart 的快乐路径
// 覆盖: readResultJson, assertResultContract, mapToLite

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // 创建临时目录
    tempDir = await Directory.systemTemp.createTemp('result_adapter_happy_test_');
  });

  tearDown(() async {
    // 清理临时目录
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('result_adapter happy path', () {
    test('readResultJson - 成功读取 UTF-8 JSON (无 BOM)', () async {
      // 准备：将 dev/result_demo.json 复制到临时会话目录
      final sessionRoot = '${tempDir.path}/session_001';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_demo.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      // 执行：读取 result.json
      final raw = await readResultJson(sessionRoot);

      // 断言：成功解析为 Map
      expect(raw, isA<Map<String, dynamic>>());
      expect(raw.containsKey('scores'), isTrue);
      expect(raw.containsKey('repCount'), isTrue);
      expect(raw.containsKey('meta'), isTrue);
    });

    test('assertResultContract - 不抛异常', () async {
      // 准备：读取 dev/result_demo.json
      final sessionRoot = '${tempDir.path}/session_002';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_demo.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行 & 断言：不抛异常
      expect(() => assertResultContract(raw), returnsNormally);
    });

    test('mapToLite - 字段映射正确', () async {
      // 准备：读取 dev/result_demo.json
      final sessionRoot = '${tempDir.path}/session_003';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_demo.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行：映射为轻量模型
      final lite = mapToLite(raw);

      // 断言：分数映射正确 (form→posture, tempo→rhythm)
      expect(lite.posture, equals(84), reason: 'posture ← scores.form');
      expect(lite.stability, equals(77), reason: 'stability ← scores.stability');
      expect(lite.rhythm, equals(71), reason: 'rhythm ← scores.tempo');
      expect(lite.total, equals(78), reason: 'total ← scores.overall');

      // 断言：次数
      expect(lite.reps, equals(12), reason: 'reps ← repCount');

      // 断言：证据路径
      expect(lite.evidencePath, equals('evidence/frame_612.jpg'), 
             reason: 'evidencePath ← evidence[0].snapshotPath');

      // 断言：质量指标
      expect(lite.lowConfidence, equals(false), reason: 'lowConfidence ← quality.lowConfidence');
      expect(lite.coverage, equals(0.76), reason: 'coverage ← quality.coverage');

      // 断言：元信息
      expect(lite.templateName, equals('squat'), reason: 'templateName ← meta.template');
      expect(lite.strictness, equals('strict'), reason: 'strictness ← meta.strictness');
      expect(lite.engine, equals('MoveNet'), reason: 'engine ← meta.engine');
      expect(lite.fps, equals(30), reason: 'fps ← meta.fps');
    });

    test('mapToLite - 分数浮点数正确取整', () async {
      // 准备：构造浮点数分数的 JSON
      final sessionRoot = '${tempDir.path}/session_004';
      await Directory(sessionRoot).create(recursive: true);
      
      final resultFile = File('$sessionRoot/result.json');
      await resultFile.writeAsString('''
{
  "scores": {
    "form": 84.6,
    "stability": 77.4,
    "tempo": 71.5,
    "overall": 78.2
  },
  "repCount": 12.8,
  "meta": {
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "fps": 30
  }
}
''');

      final raw = await readResultJson(sessionRoot);

      // 执行：映射为轻量模型
      final lite = mapToLite(raw);

      // 断言：浮点数正确 round 取整
      expect(lite.posture, equals(85), reason: '84.6 rounds to 85');
      expect(lite.stability, equals(77), reason: '77.4 rounds to 77');
      expect(lite.rhythm, equals(72), reason: '71.5 rounds to 72');
      expect(lite.total, equals(78), reason: '78.2 rounds to 78');
      expect(lite.reps, equals(13), reason: '12.8 rounds to 13');
    });

    test('mapToLite - coverage 截断到 [0,1] 区间', () async {
      // 准备：构造 coverage 越界的 JSON
      final sessionRoot = '${tempDir.path}/session_005';
      await Directory(sessionRoot).create(recursive: true);
      
      final resultFile = File('$sessionRoot/result.json');
      await resultFile.writeAsString('''
{
  "scores": {
    "form": 80,
    "stability": 75,
    "tempo": 70,
    "overall": 75
  },
  "repCount": 10,
  "quality": {
    "coverage": 1.5
  },
  "meta": {
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "fps": 30
  }
}
''');

      final raw = await readResultJson(sessionRoot);
      final lite = mapToLite(raw);

      // 断言：coverage 截断为 1.0
      expect(lite.coverage, equals(1.0), reason: 'coverage > 1.0 should be clamped to 1.0');
    });

    test('mapToLite - 可选字段缺失不崩溃', () async {
      // 准备：构造仅有必填字段的最小 JSON
      final sessionRoot = '${tempDir.path}/session_006';
      await Directory(sessionRoot).create(recursive: true);
      
      final resultFile = File('$sessionRoot/result.json');
      await resultFile.writeAsString('''
{
  "scores": {
    "form": 70,
    "stability": 68,
    "tempo": 72,
    "overall": 70
  },
  "repCount": 8,
  "meta": {}
}
''');

      final raw = await readResultJson(sessionRoot);

      // 执行 & 断言：不抛异常
      expect(() => mapToLite(raw), returnsNormally);
      
      final lite = mapToLite(raw);
      
      // 可选字段应为 null
      expect(lite.evidencePath, isNull);
      expect(lite.lowConfidence, isNull);
      expect(lite.coverage, isNull);
      expect(lite.templateName, isNull);
      expect(lite.strictness, isNull);
      expect(lite.engine, isNull);
      expect(lite.fps, isNull);
    });
  });
}

