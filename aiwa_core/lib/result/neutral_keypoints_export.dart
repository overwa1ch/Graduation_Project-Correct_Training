import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../pose/frame_streamer.dart';

Future<File> writeNeutralKeypointsJson({
  required FrameStreamResult result,
  required Directory outputRoot,
  bool pretty = true,
}) async {
  final outDir = Directory(
    p.join(outputRoot.path, result.config.videoBasename),
  );
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final file = File(p.join(outDir.path, 'neutral_keypoints.json'));
  final encoder =
      pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
  final jsonStr = encoder.convert(result.toNeutralKeypointsJson());
  await file.writeAsString(jsonStr);
  return file;
}
