import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

import 'package:aiwa_milestone_a/pipeline/offline_pipeline.dart';
import 'package:aiwa_milestone_a/pose/kp_models.dart';
import 'package:aiwa_milestone_a/spec/rule_models.dart';
import 'package:aiwa_milestone_a/spec/rule_parser.dart';

void main() {
  test('golden alignment', () async {
    final root = Directory.current.path;
    final kpPath = p.join(root, 'test', 'fixtures', 'kp_sample.json');
    final rulePath = p.join(root, 'test', 'fixtures', 'squat.v1.json');

    final kp = parseKeypointSeries(await File(kpPath).readAsString());
    final rs = parseRuleSet(await File(rulePath).readAsString());
    final pipe = OfflinePipeline(rs, Strictness.relaxed);
    final out = await pipe.run(kp);

    final tmpDir = await Directory.systemTemp.createTemp('aiwa_baseline_');
    try {
      final anglesPath = p.join(tmpDir.path, 'angles.csv');
      final resultPath = p.join(tmpDir.path, 'result.json');
      final baselineScript = p.join(root, 'tools', 'python_baseline.py');
      final pythonExecutable = Platform.isWindows ? 'python' : 'python3';
      final proc = await Process.run(pythonExecutable, [
        baselineScript,
        '--kp',
        kpPath,
        '--rule',
        rulePath,
        '--angles',
        anglesPath,
        '--result',
        resultPath,
        '--strictness',
        'relaxed',
      ]);
      expect(proc.exitCode, 0, reason: 'python baseline failed: ${proc.stderr}');

      final baselineAngles = await File(anglesPath).readAsString();
      final baselineResult = json.decode(await File(resultPath).readAsString())
          as Map<String, dynamic>;

      _expectAnglesClose(out.anglesCsv, baselineAngles);
      final result = out.resultJson;
      expect(result['repCount'], baselineResult['repCount'],
          reason: 'rep count mismatch');

      _expectScoresClose(result['scores'] as Map<String, dynamic>,
          baselineResult['scores'] as Map<String, dynamic>);
      _expectIssuesAligned(result['issues'] as List,
          baselineResult['issues'] as List<dynamic>);
      _expectEvidenceAligned(result['evidence'] as List,
          baselineResult['evidence'] as List<dynamic>);
    } finally {
      await tmpDir.delete(recursive: true);
    }
  });
}

class _AngleRow {
  final int t;
  final double? kneeL;
  final double? kneeR;
  final double? trunk;
  _AngleRow(this.t, this.kneeL, this.kneeR, this.trunk);
}

void _expectAnglesClose(String actualCsv, String baselineCsv) {
  final converter = const CsvToListConverter(eol: '\n');
  final actualRows = converter.convert(actualCsv);
  final baselineRows = converter.convert(baselineCsv);
  expect(actualRows.length, baselineRows.length,
      reason: 'angle csv row count mismatch');

  final actual = _parseAngleRows(actualRows);
  final baseline = _parseAngleRows(baselineRows);

  double totalAbsError = 0.0;
  var count = 0;
  for (var i = 0; i < actual.length; i++) {
    expect(actual[i].t, baseline[i].t, reason: 'timestamp mismatch at row $i');

    for (final pair in [
      (actual[i].kneeL, baseline[i].kneeL),
      (actual[i].kneeR, baseline[i].kneeR),
      (actual[i].trunk, baseline[i].trunk)
    ]) {
      final a = pair.$1;
      final b = pair.$2;
      if (a != null && b != null) {
        totalAbsError += (a - b).abs();
        count++;
      }
    }
  }
  final mae = count == 0 ? 0.0 : totalAbsError / count;
  expect(mae <= 2.0,isTrue, reason: 'Angle MAE too large: $mae');
}

List<_AngleRow> _parseAngleRows(List<List<dynamic>> rows) {
  return rows.skip(1).map((row) {
    double? parseDynamic(dynamic value) {
      if (value == null || value == '') return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return _AngleRow(
      (row[0] as num).toInt(),
      parseDynamic(row[1]),
      parseDynamic(row[2]),
      parseDynamic(row[3]),
    );
  }).toList();
}

void _expectScoresClose(
    Map<String, dynamic> actual, Map<String, dynamic> baseline) {
  for (final key in const ['overall', 'form', 'stability', 'tempo']) {
    final a = (actual[key] as num).toDouble();
    final b = (baseline[key] as num).toDouble();
    final diff = (a - b).abs();
    expect(diff <= 2.0,isTrue, reason: 'Score $key differs by $diff');
  }
}

void _expectIssuesAligned(List<dynamic> actual, List<dynamic> baseline) {
  Map<String, Map<String, dynamic>> toMap(List<dynamic> issues) {
    return {
      for (final issue in issues.cast<Map<String, dynamic>>())
        issue['code'] as String: issue,
    };
  }

  final actualMap = toMap(actual);
  final baselineMap = toMap(baseline);
  expect(actualMap.keys.toSet(), baselineMap.keys.toSet(),
      reason: 'issue codes mismatch');

  for (final code in actualMap.keys) {
    final a = actualMap[code]!;
    final b = baselineMap[code]!;
    expect(a['severity'], b['severity'],
        reason: 'severity mismatch for $code');
    final framesA = (a['frames'] as List).cast<num>().map((e) => e.toInt()).toList()
      ..sort();
    final framesB = (b['frames'] as List).cast<num>().map((e) => e.toInt()).toList()
      ..sort();
    expect(framesA.length, framesB.length,
        reason: 'frame count mismatch for $code');
    for (var i = 0; i < framesA.length; i++) {
      final diff = (framesA[i] - framesB[i]).abs();
      expect(diff <= 33,isTrue,
          reason: 'issue $code frame mismatch (>33ms): ${framesA[i]} vs ${framesB[i]}');
    }
    if (a.containsKey('worst') && b.containsKey('worst')) {
      final worstDiff = ((a['worst'] as num) - (b['worst'] as num)).abs();
      expect(worstDiff <= 2.0,isTrue,
          reason: 'issue $code worst value mismatch: diff=$worstDiff');
    }
  }
}

void _expectEvidenceAligned(List<dynamic> actual, List<dynamic> baseline) {
  List<Map<String, dynamic>> filter(String type, List<dynamic> source) => source
      .whereType<Map<String, dynamic>>()
      .where((e) => e['type'] == type)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  void expectPhase(String type) {
    final a = filter(type, actual)
      ..sort((x, y) => (x['startMs'] as num).compareTo(y['startMs'] as num));
    final b = filter(type, baseline)
      ..sort((x, y) => (x['startMs'] as num).compareTo(y['startMs'] as num));
    expect(a.length, b.length, reason: '$type count mismatch');
    for (var i = 0; i < a.length; i++) {
      final startDiff =
          ((a[i]['startMs'] as num) - (b[i]['startMs'] as num)).abs();
      final endDiff = ((a[i]['endMs'] as num) - (b[i]['endMs'] as num)).abs();
      expect(startDiff <= 33,isTrue,
          reason: '$type start mismatch (>33ms): ${a[i]} vs ${b[i]}');
      expect(endDiff <= 33,isTrue,
          reason: '$type end mismatch (>33ms): ${a[i]} vs ${b[i]}');
    }
  }

  expectPhase('phaseDown');
  expectPhase('phaseUp');

  final repsA = filter('rep', actual)
    ..sort((x, y) => (x['index'] as num).compareTo(y['index'] as num));
  final repsB = filter('rep', baseline)
    ..sort((x, y) => (x['index'] as num).compareTo(y['index'] as num));
  expect(repsA.length, repsB.length, reason: 'rep evidence count mismatch');
  for (var i = 0; i < repsA.length; i++) {
    final a = repsA[i];
    final b = repsB[i];
    for (final key in const ['startMs', 'valleyMs', 'endMs']) {
      final diff = ((a[key] as num) - (b[key] as num)).abs();
      expect(diff <= 33,isTrue,
          reason: 'rep ${a['index']} $key mismatch (>33ms): ${a[key]} vs ${b[key]}');
    }
    if (a.containsKey('kneeValleyAngle') && b.containsKey('kneeValleyAngle')) {
      final angleDiff =
          ((a['kneeValleyAngle'] as num) - (b['kneeValleyAngle'] as num)).abs();
      expect(angleDiff <= 2.0,isTrue,
          reason:
              'rep ${a['index']} kneeValleyAngle mismatch: diff=$angleDiff');
    }
  }

  final issuesA = filter('issue', actual)
    ..sort((x, y) => (x['frameMs'] as num).compareTo(y['frameMs'] as num));
  final issuesB = filter('issue', baseline)
    ..sort((x, y) => (x['frameMs'] as num).compareTo(y['frameMs'] as num));
  expect(issuesA.length, issuesB.length,
      reason: 'issue evidence count mismatch');
  for (var i = 0; i < issuesA.length; i++) {
    final a = issuesA[i];
    final b = issuesB[i];
    expect(a['code'], b['code']);
    final frameDiff = ((a['frameMs'] as num) - (b['frameMs'] as num)).abs();
    expect(frameDiff <= 33,isTrue,
        reason: 'issue evidence frame mismatch: ${a['code']} diff=$frameDiff');
  }
}