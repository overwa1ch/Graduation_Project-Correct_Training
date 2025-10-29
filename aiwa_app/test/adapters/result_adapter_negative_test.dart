// result_adapter_negative_test.dart
// Purpose: 测试 result_adapter.dart 的错误处理
// 覆盖: 字段缺失、越界、类型错误

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('result_adapter_negative_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('result_adapter negative cases', () {
    test('assertResultContract - 缺失 scores.form 字段', () async {
      // 准备：复制 result_missing_form.json
      final sessionRoot = '${tempDir.path}/session_missing_form';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_missing_form.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('scores.form'),
        )),
      );
    });

    test('assertResultContract - 缺失 repCount 字段', () async {
      // 准备：构造缺失 repCount 的 JSON
      final sessionRoot = '${tempDir.path}/session_missing_repcount';
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
  "meta": {
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "fps": 30
  }
}
''');

      final raw = await readResultJson(sessionRoot);

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('repCount'),
        )),
      );
    });

    test('assertResultContract - scores.overall 越界 (>100)', () async {
      // 准备：复制 result_overall_out_of_range.json
      final sessionRoot = '${tempDir.path}/session_overall_out';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_overall_out_of_range.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('overall'),
            anyOf(contains('out of range'), contains('invalid')),
          ),
        )),
      );
    });

    test('assertResultContract - repCount 为负数', () async {
      // 准备：构造 repCount 为负数的 JSON
      final sessionRoot = '${tempDir.path}/session_negative_reps';
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
  "repCount": -1,
  "meta": {
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "fps": 30
  }
}
''');

      final raw = await readResultJson(sessionRoot);

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('repCount'),
            anyOf(contains('negative'), contains('non-negative')),
          ),
        )),
      );
    });

    test('assertResultContract - scores.tempo 为字符串 (类型错误)', () async {
      // 准备：构造 scores.tempo 为字符串的 JSON
      final sessionRoot = '${tempDir.path}/session_tempo_string';
      await Directory(sessionRoot).create(recursive: true);
      
      final resultFile = File('$sessionRoot/result.json');
      await resultFile.writeAsString('''
{
  "scores": {
    "form": 80,
    "stability": 75,
    "tempo": "fast",
    "overall": 75
  },
  "repCount": 10,
  "meta": {
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "fps": 30
  }
}
''');

      final raw = await readResultJson(sessionRoot);

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('tempo'),
            contains('number'),
          ),
        )),
      );
    });

    test('assertResultContract - scores.form < 0 (越界)', () async {
      // 准备：构造 scores.form 为负数的 JSON
      final sessionRoot = '${tempDir.path}/session_form_negative';
      await Directory(sessionRoot).create(recursive: true);
      
      final resultFile = File('$sessionRoot/result.json');
      await resultFile.writeAsString('''
{
  "scores": {
    "form": -10,
    "stability": 75,
    "tempo": 70,
    "overall": 75
  },
  "repCount": 10,
  "meta": {
    "template": "squat",
    "strictness": "strict",
    "engine": "MoveNet",
    "fps": 30
  }
}
''');

      final raw = await readResultJson(sessionRoot);

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('form'),
            contains('out of range'),
          ),
        )),
      );
    });

    test('assertResultContract - 缺失 meta 对象', () async {
      // 准备：构造缺失 meta 的 JSON
      final sessionRoot = '${tempDir.path}/session_missing_meta';
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
  "repCount": 10
}
''');

      final raw = await readResultJson(sessionRoot);

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          contains('meta'),
        )),
      );
    });

    test('readResultJson - 文件不存在', () async {
      // 准备：不创建 result.json
      final sessionRoot = '${tempDir.path}/session_not_exist';
      await Directory(sessionRoot).create(recursive: true);

      // 断言：抛出 ResultReadException 异常
      expect(
        () => readResultJson(sessionRoot),
        throwsA(isA<ResultReadException>().having(
          (e) => e.message,
          'message',
          contains('not found'),
        )),
      );
    });

    test('readResultJson - JSON 解析失败', () async {
      // 准备：构造非法 JSON
      final sessionRoot = '${tempDir.path}/session_malformed_json';
      await Directory(sessionRoot).create(recursive: true);
      
      final resultFile = File('$sessionRoot/result.json');
      await resultFile.writeAsString('{ this is not valid json }');

      // 断言：抛出 ResultReadException 异常
      expect(
        () => readResultJson(sessionRoot),
        throwsA(isA<ResultReadException>().having(
          (e) => e.message,
          'message',
          contains('parse'),
        )),
      );
    });

    test('assertResultContract - scores.overall 为 NaN', () async {
      // 准备：构造 NaN 值的 JSON（通过字符串注入）
      final sessionRoot = '${tempDir.path}/session_nan';
      await Directory(sessionRoot).create(recursive: true);
      
      final resultFile = File('$sessionRoot/result.json');
      // 注意：Dart 的 jsonDecode 会拒绝 NaN，所以这里测试我们的校验逻辑
      // 实际上我们需要通过代码构造包含 NaN 的 Map
      await resultFile.writeAsString('''
{
  "scores": {
    "form": 80,
    "stability": 75,
    "tempo": 70,
    "overall": 75
  },
  "repCount": 10,
  "meta": {}
}
''');

      final raw = await readResultJson(sessionRoot);
      
      // 手动注入 NaN（模拟某些极端情况）
      (raw['scores'] as Map<String, dynamic>)['overall'] = double.nan;

      // 断言：抛出 SchemaMismatch 异常
      expect(
        () => assertResultContract(raw),
        throwsA(isA<SchemaMismatch>().having(
          (e) => e.message,
          'message',
          anyOf(contains('NaN'), contains('Infinity')),
        )),
      );
    });
  });
}

