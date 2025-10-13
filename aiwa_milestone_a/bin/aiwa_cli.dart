import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'package:aiwa_milestone_a/core/io.dart'; // 提供 jsonPretty
import 'package:aiwa_milestone_a/spec/rule_parser.dart';
import 'package:aiwa_milestone_a/spec/rule_models.dart';
import 'package:aiwa_milestone_a/pipeline/offline_pipeline.dart';
import 'package:aiwa_milestone_a/pose/kp_models.dart';


void main(List<String> args) async {
  final p = ArgParser()
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
  final opts = p.parse(args);

  try {
    final kpStr = await File(opts['keypoints']).readAsString();
    final kp = parseKeypointSeries(kpStr); // 你可在 kp_models.dart 补 parse
    final ruleStr = await File(opts['rule']).readAsString();
    final rs = parseRuleSet(ruleStr);

    final pipeline = OfflinePipeline(rs,
      opts['strictness']=='strict' ? Strictness.strict : Strictness.relaxed);

    final out = await pipeline.run(kp);

    final baseName = opts['video'] != null
        ? p.basenameWithoutExtension(opts['video'])
        : p.basenameWithoutExtension(opts['keypoints']);

    final outDir = Directory(p.join(opts['out'], baseName))
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
