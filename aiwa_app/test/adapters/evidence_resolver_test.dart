// evidence_resolver_test.dart
// Purpose: 测试 evidence_resolver.dart 的证据降级策略
// 覆盖: resolveSnapshotPath, resolveEvidenceWindow

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';
import 'package:aiwa_app/adapters/evidence_resolver.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('evidence_resolver_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('evidence_resolver', () {
    test('resolveSnapshotPath - 有 snapshotPath 返回非空', () async {
      // 准备：读取 dev/result_demo.json（包含 snapshotPath）
      final sessionRoot = '${tempDir.path}/session_with_snapshot';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_demo.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行：解析快照路径
      final snapshotPath = resolveSnapshotPath(raw);

      // 断言：返回非空路径
      expect(snapshotPath, isNotNull);
      expect(snapshotPath, equals('evidence/frame_612.jpg'));
    });

    test('resolveSnapshotPath - 有 snapshotPath，resolveEvidenceWindow 也返回非空', () async {
      // 准备：读取 dev/result_demo.json（包含 snapshotPath + window）
      final sessionRoot = '${tempDir.path}/session_both';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_demo.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行：解析时间窗
      final window = resolveEvidenceWindow(raw);

      // 断言：两者都存在时，window 也返回非空
      expect(window, isNotNull);
      expect(window!.startMs, equals(20000));
      expect(window.endMs, equals(21000));
    });

    test('resolveSnapshotPath - 仅有 window，snapshotPath 返回 null', () async {
      // 准备：读取 dev/result_evidence_window_only.json（仅有 window）
      final sessionRoot = '${tempDir.path}/session_window_only';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_evidence_window_only.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行：解析快照路径
      final snapshotPath = resolveSnapshotPath(raw);

      // 断言：返回 null
      expect(snapshotPath, isNull);
    });

    test('resolveEvidenceWindow - 仅有 window，返回时间窗', () async {
      // 准备：读取 dev/result_evidence_window_only.json
      final sessionRoot = '${tempDir.path}/session_window_only2';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_evidence_window_only.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行：解析时间窗
      final window = resolveEvidenceWindow(raw);

      // 断言：返回非空，值正确
      expect(window, isNotNull);
      expect(window!.startMs, equals(12000));
      expect(window.endMs, equals(12750));
    });

    test('resolveSnapshotPath - evidence 缺失，返回 null', () async {
      // 准备：读取 dev/result_no_evidence.json（无 evidence）
      final sessionRoot = '${tempDir.path}/session_no_evidence';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_no_evidence.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行：解析快照路径
      final snapshotPath = resolveSnapshotPath(raw);

      // 断言：返回 null（不抛异常）
      expect(snapshotPath, isNull);
    });

    test('resolveEvidenceWindow - evidence 缺失，返回 null', () async {
      // 准备：读取 dev/result_no_evidence.json
      final sessionRoot = '${tempDir.path}/session_no_evidence2';
      await Directory(sessionRoot).create(recursive: true);
      
      final sourceFile = File('dev/result_no_evidence.json');
      final targetFile = File('$sessionRoot/result.json');
      await sourceFile.copy(targetFile.path);

      final raw = await readResultJson(sessionRoot);

      // 执行：解析时间窗
      final window = resolveEvidenceWindow(raw);

      // 断言：返回 null（不抛异常）
      expect(window, isNull);
    });

    test('resolveSnapshotPath - snapshotPath 为空字符串，返回 null', () async {
      // 准备：构造 snapshotPath 为空串的 JSON
      final sessionRoot = '${tempDir.path}/session_empty_snapshot';
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
  "meta": {},
  "evidence": [
    {
      "snapshotPath": "   ",
      "window": {
        "startMs": 10000,
        "endMs": 11000
      }
    }
  ]
}
''');

      final raw = await readResultJson(sessionRoot);

      // 执行：解析快照路径
      final snapshotPath = resolveSnapshotPath(raw);

      // 断言：空白字符串应返回 null
      expect(snapshotPath, isNull);
    });

    test('resolveEvidenceWindow - endMs <= startMs，返回 null', () async {
      // 准备：构造非法时间窗的 JSON
      final sessionRoot = '${tempDir.path}/session_invalid_window';
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
  "meta": {},
  "evidence": [
    {
      "window": {
        "startMs": 15000,
        "endMs": 15000
      }
    }
  ]
}
''');

      final raw = await readResultJson(sessionRoot);

      // 执行：解析时间窗
      final window = resolveEvidenceWindow(raw);

      // 断言：非法窗口返回 null（不抛异常）
      expect(window, isNull);
    });

    test('resolveEvidenceWindow - startMs < 0，返回 null', () async {
      // 准备：构造负数时间的 JSON
      final sessionRoot = '${tempDir.path}/session_negative_time';
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
  "meta": {},
  "evidence": [
    {
      "window": {
        "startMs": -1000,
        "endMs": 5000
      }
    }
  ]
}
''');

      final raw = await readResultJson(sessionRoot);

      // 执行：解析时间窗
      final window = resolveEvidenceWindow(raw);

      // 断言：负数时间返回 null（不抛异常）
      expect(window, isNull);
    });

    test('resolveEvidenceWindow - 缺失 startMs 或 endMs，返回 null', () async {
      // 准备：构造缺失 endMs 的 JSON
      final sessionRoot = '${tempDir.path}/session_missing_endms';
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
  "meta": {},
  "evidence": [
    {
      "window": {
        "startMs": 10000
      }
    }
  ]
}
''');

      final raw = await readResultJson(sessionRoot);

      // 执行：解析时间窗
      final window = resolveEvidenceWindow(raw);

      // 断言：缺失字段返回 null（不抛异常）
      expect(window, isNull);
    });

    test('resolveSnapshotPath - evidence 为空数组，返回 null', () async {
      // 准备：构造 evidence 为空数组的 JSON
      final sessionRoot = '${tempDir.path}/session_empty_evidence';
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
  "meta": {},
  "evidence": []
}
''');

      final raw = await readResultJson(sessionRoot);

      // 执行：解析快照路径
      final snapshotPath = resolveSnapshotPath(raw);

      // 断言：空数组返回 null（不抛异常）
      expect(snapshotPath, isNull);
    });
  });
}

