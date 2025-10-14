import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:aiwa_milestone_a/core/io.dart'; // 提供 jsonPretty
import 'package:aiwa_milestone_a/spec/rule_parser.dart';
import 'package:aiwa_milestone_a/spec/rule_models.dart';
import 'package:aiwa_milestone_a/pipeline/offline_pipeline.dart';
import 'package:aiwa_milestone_a/pipeline/pose_input_converter.dart';
import 'package:aiwa_milestone_a/pipeline/pose_series.dart';
import 'package:aiwa_milestone_a/pose/kp_models.dart';
import 'package:aiwa_milestone_a/pose/neutral_keypoint_series.dart';


void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('keypoints',
        abbr: 'k',
        help: 'Path to kp.json',
        defaultsTo: 'test/fixtures/kp_sample.json')
    ..addOption('rule',
        abbr: 'r',
        help: 'Path to squat.v1.json',
        defaultsTo: 'test/fixtures/squat.v1.json')
    ..addOption('strictness',
        defaultsTo: 'relaxed', allowed: ['relaxed', 'strict'])
    ..addOption('out',
        abbr: 'o', help: 'Output dir', defaultsTo: 'build/offline_out')
    ..addOption('video',
        help: 'Path to original video (used for naming outputs)');
  final opts = parser.parse(args);

  try {
    final kpStr = await File(opts['keypoints']).readAsString();
    final dynamic kpRoot = jsonDecode(kpStr);
    if (kpRoot is! Map<String, dynamic>) {
      throw FormatException('Keypoints JSON must be an object.');
    }

    late final PoseSeries poseSeries;
    if ((kpRoot['version'] as Object?) == 'vB1.1') {
      final neutral = parseNeutralKeypointSeriesFromMap(kpRoot);
      poseSeries = poseSeriesFromNeutral(neutral);
    } else {
      final legacy = parseKeypointSeriesFromMap(kpRoot);
      poseSeries = poseSeriesFromLegacy(legacy);
    }
    final ruleStr = await File(opts['rule']).readAsString();
    final rs = parseRuleSet(ruleStr);

    final pipeline = OfflinePipeline(
        rs,
        opts['strictness'] == 'strict'
            ? Strictness.strict
            : Strictness.relaxed);

    final out = await pipeline.run(poseSeries);

    final baseName = opts['video'] != null
        ? path.basenameWithoutExtension(opts['video'])
        : path.basenameWithoutExtension(opts['keypoints']);

    final outDir = Directory(path.join(opts['out'], baseName))
      ..createSync(recursive: true);
    await File('${outDir.path}/angles.csv').writeAsString(out.anglesCsv);
    await File('${outDir.path}/result.json')
      .writeAsString(jsonPretty(out.resultJson));

    stdout.writeln('Done → ${outDir.path}');
  } catch (e) {
    stderr.writeln(e);
    exit(1);
  }
}
