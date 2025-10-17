import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:aiwa_milestone_a/core/io.dart';
import 'package:aiwa_milestone_a/pipeline/offline_pipeline.dart';
import 'package:aiwa_milestone_a/pipeline/pose_input_converter.dart';
import 'package:aiwa_milestone_a/pipeline/pose_series.dart';
import 'package:aiwa_milestone_a/pose/frame_streamer.dart';
import 'package:aiwa_milestone_a/pose/kp_models.dart';
import 'package:aiwa_milestone_a/pose/mlkit_pose_engine.dart';
import 'package:aiwa_milestone_a/pose/neutral_keypoint_series.dart';
import 'package:aiwa_milestone_a/pose/pose_engine.dart';
import 'package:aiwa_milestone_a/spec/rule_models.dart';
import 'package:aiwa_milestone_a/spec/rule_parser.dart';

const _exitOk = 0;
const _exitParamError = 2;
const _exitDecodeError = 3;
const _exitEngineInitError = 4;
const _exitInferenceError = 5;
const _exitOutputError = 6;
const _exitSchemaError = 7;

const _defaultOutDir = 'build/offline_out';
const _defaultEngine = 'mlkit';
const _defaultSamplingStride = 2;
const _defaultInputResolution = '720p';
const _defaultFps = 30.0;

ArgParser _buildParser() {
  return ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show usage information.')
    ..addOption('keypoints',
        abbr: 'k', help: 'Path to keypoints JSON file (file mode).')
    ..addOption('video', help: 'Path to source video file (engine mode).')
    ..addOption('rule',
        abbr: 'r', help: 'Path to squat rule JSON file (required).')
    ..addOption('strictness',
        defaultsTo: 'relaxed', allowed: ['relaxed', 'strict'])
    ..addOption('out',
        abbr: 'o',
        defaultsTo: _defaultOutDir,
        help: 'Output directory root (default: $_defaultOutDir).')
    ..addOption('engine',
        defaultsTo: _defaultEngine,
        allowed: ['mlkit', 'movenet'],
        help: 'Engine mode inference backend (default: $_defaultEngine).')
    ..addOption('sampling-stride',
        defaultsTo: _defaultSamplingStride.toString(),
        help:
            'Frame sampling stride when decoding video (default: $_defaultSamplingStride).')
    ..addOption('input-resolution',
        defaultsTo: _defaultInputResolution,
        allowed: ['720p', '540p'],
        help:
            'Input resolution for the inference engine (default: $_defaultInputResolution).')
    ..addOption('mirror-applied',
        defaultsTo: 'auto',
        allowed: ['auto', 'true', 'false'],
        help:
            'Whether to mirror keypoints horizontally in engine mode. "auto" keeps the video orientation.')
    ..addFlag('overlay',
        negatable: false, help: 'Export overlay video in engine mode (optional).');
}

String _usage(ArgParser parser) => '''
AIWA CLI — Offline Squat Pipeline

Usage:
  dart run bin/aiwa_cli.dart --keypoints <kp.json> --rule <rule.json> [options]
  dart run bin/aiwa_cli.dart --video <video.mp4> --rule <rule.json> [engine options]

Examples:
  # File mode (existing keypoints JSON)
  dart run bin/aiwa_cli.dart \
    --keypoints test/fixtures/kp_sample.json \
    --rule test/fixtures/squat.v1.json \
    --out build/offline_out

  # Engine mode (video → ML Kit → neutral keypoints → pipeline)
  dart run bin/aiwa_cli.dart \
    --video assets/demo.mp4 \
    --rule configs/squat.v1.json \
    --engine mlkit \
    --sampling-stride 2 \
    --input-resolution 720p \
    --out build/offline_out

Options:
${parser.usage}
''';

class _CliException implements Exception {
  final String message;
  final int exitCode;
  final bool showUsage;

  const _CliException(this.message, this.exitCode, {this.showUsage = false});

  @override
  String toString() => message;
}

class _VideoProbeResult {
  final int width;
  final int height;
  final double fps;
  final int durationMs;

  const _VideoProbeResult({
    required this.width,
    required this.height,
    required this.fps,
    required this.durationMs,
  });
}

class _VideoDecodeResult {
  final List<RawImageFrame> frames;
  final int width;
  final int height;
  final double fps;
  final int durationMs;
  final int decodeMs;

  const _VideoDecodeResult({
    required this.frames,
    required this.width,
    required this.height,
    required this.fps,
    required this.durationMs,
    required this.decodeMs,
  });

  int get frameCount => frames.length;
}

Future<void> main(List<String> args) async {
  final parser = _buildParser();
  late final ArgResults opts;
  try {
    opts = parser.parse(args);
  } on FormatException catch (e) {
    stderr.writeln('[ERROR] ${e.message}');
    stdout.writeln(_usage(parser));
    exit(_exitParamError);
  }

  if (opts['help'] == true) {
    stdout.write(_usage(parser));
    exit(_exitOk);
  }

  try {
    _validateOptions(opts);
    final rulePath = opts['rule'] as String;
    final ruleStr = await _readFile(rulePath, 'rule definition');
    final ruleSet = parseRuleSet(ruleStr);

    final strictness = (opts['strictness'] as String) == 'strict'
        ? Strictness.strict
        : Strictness.relaxed;

    if (opts['video'] != null) {
      await _runEngineMode(opts, ruleSet, strictness);
    } else {
      await _runFileMode(opts, ruleSet, strictness);
    }
    exit(_exitOk);
  } on NeutralKeypointParseError catch (e) {   // 先抓具体解析错误
    stderr.writeln('[ERROR] ${e.message}');
    exit(_exitSchemaError);
  } on _CliException catch (e) {               // 再抓 CLI 的统一错误
    stderr.writeln('[ERROR] ${e.message}');
    if (e.showUsage) {
      stdout.write(_usage(parser));
    }
    exit(e.exitCode);
  } catch (e, stack) {                         // 最后兜底
    stderr.writeln('[FATAL] $e');
    stderr.writeln(stack);
    exit(1);
  }
}

void _validateOptions(ArgResults opts) {
  final keypointsProvided = opts['keypoints'] != null;
  final videoProvided = opts['video'] != null;

  if (keypointsProvided == videoProvided) {
    throw _CliException(
      'Provide exactly one of --keypoints or --video.',
      _exitParamError,
      showUsage: true,
    );
  }

  final rulePath = opts['rule'] as String?;
  if (rulePath == null || rulePath.isEmpty) {
    throw _CliException(
      '--rule is required and must point to a rule JSON file.',
      _exitParamError,
      showUsage: true,
    );
  }

  final strideStr = opts['sampling-stride'] as String?;
  final stride = int.tryParse(strideStr ?? '');
  if (opts['video'] != null && (stride == null || stride <= 0)) {
    throw _CliException(
      '--sampling-stride must be a positive integer.',
      _exitParamError,
      showUsage: true,
    );
  }

  final mirrorOpt = opts['mirror-applied'] as String? ?? 'auto';
  if (!['auto', 'true', 'false'].contains(mirrorOpt)) {
    throw _CliException(
      '--mirror-applied must be one of auto|true|false.',
      _exitParamError,
      showUsage: true,
    );
  }
}

Future<void> _runFileMode(
  ArgResults opts,
  RuleSet ruleSet,
  Strictness strictness,
) async {
  final keypointsPath = opts['keypoints'] as String;
  final kpStr = await _readFile(keypointsPath, 'keypoints JSON');
  final dynamic kpRoot = jsonDecode(kpStr);
  if (kpRoot is! Map<String, dynamic>) {
    throw _CliException(
      'Keypoints JSON must be an object.',
      _exitSchemaError,
    );
  }

  late final PoseSeries poseSeries;
  if ((kpRoot['version'] as Object?) == 'vB1.1') {
    final neutralSeries = parseNeutralKeypointSeriesFromMap(kpRoot);
    poseSeries = poseSeriesFromNeutral(neutralSeries);
  } else {
    final legacySeries = parseKeypointSeriesFromMap(kpRoot);
    poseSeries = poseSeriesFromLegacy(legacySeries);
  }

  final pipeline = OfflinePipeline(ruleSet, strictness);
  late final ({String anglesCsv, Map<String, dynamic> resultJson}) out;
  try {
    out = await pipeline.run(poseSeries);
  } catch (e) {
    throw _CliException('Offline pipeline failed: $e', _exitInferenceError);
  }

  final outRoot = Directory(opts['out'] as String? ?? _defaultOutDir);
  final baseName = path.basenameWithoutExtension(keypointsPath);
  final outDir = Directory(path.join(outRoot.path, baseName))
    ..createSync(recursive: true);

  try {
    final anglesFile = File(path.join(outDir.path, 'angles.csv'));
    await anglesFile.writeAsString(out.anglesCsv);

    final resultFile = File(path.join(outDir.path, 'result.json'));
    await resultFile.writeAsString(jsonPretty(out.resultJson));

    stdout.writeln('[DONE] Offline pipeline completed → ${outDir.path}');
    stdout.writeln('  - ${anglesFile.path}');
    stdout.writeln('  - ${resultFile.path}');
  } on IOException catch (e) {
    throw _CliException('Failed to write outputs: $e', _exitOutputError);
  }
}

Future<void> _runEngineMode(
  ArgResults opts,
  RuleSet ruleSet,
  Strictness strictness,
) async {
  final videoPath = opts['video'] as String;
  final engineName = (opts['engine'] as String?) ?? _defaultEngine;
  if (engineName != 'mlkit') {
    throw _CliException(
      'Engine "$engineName" is not supported in this CLI build.',
      _exitEngineInitError,
    );
  }

  final stride = int.parse(opts['sampling-stride'] as String);
  final resolution = (opts['input-resolution'] as String?) ?? _defaultInputResolution;
  final mirrorOpt = (opts['mirror-applied'] as String?) ?? 'auto';
  final overlayRequested = opts['overlay'] == true;

  final shouldMirror = switch (mirrorOpt) {
    'true' => true,
    'false' => false,
    _ => false,
  };

  final mirrorSource = mirrorOpt == 'auto' ? 'auto→false' : mirrorOpt;

  final outRoot = Directory(opts['out'] as String? ?? _defaultOutDir);
  final baseName = path.basenameWithoutExtension(videoPath);
  final outDir = Directory(path.join(outRoot.path, baseName))
    ..createSync(recursive: true);
  final logsDir = Directory(path.join(outDir.path, 'logs'))
    ..createSync(recursive: true);

  final runLog = <String>[];
  void log(String level, String message) {
    final line = '[${DateTime.now().toIso8601String()}][$level] $message';
    runLog.add(line);
    if (level == 'ERROR') {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }

  log('INFO', 'Engine mode start → engine=$engineName, stride=$stride, resolution=$resolution');
  log('INFO', 'Video source: $videoPath');
  log('INFO', 'Mirror setting: $mirrorSource');
  log('INFO', 'Output directory: ${outDir.path}');

  if (overlayRequested) {
    log('WARN', 'Overlay export requested but not implemented in CLI mode. Skipping.');
  }

  final probe = await _probeVideo(videoPath);
  final targetHeight = resolution == '540p' ? 540 : 720;
  final targetWidth = _computeTargetWidth(probe, targetHeight);

  final decodeResult = await _decodeVideo(
    videoPath: videoPath,
    targetWidth: targetWidth,
    targetHeight: targetHeight,
    targetFps: _defaultFps,
  );

  log('INFO', 'Decoded ${decodeResult.frameCount} frames at ${decodeResult.width}x${decodeResult.height} (${decodeResult.decodeMs} ms).');

  final engine = MlKitPoseEngine();
  try {
    await engine.init(const PoseEngineConfig(
      preferAccurate: true,
      outputZ: true,
      minScore: 0.0,
      returnEmptyWhenLow: false,
    ));
  } catch (e) {
    throw _CliException('Failed to initialize ML Kit engine: $e', _exitEngineInitError);
  }

  final fpsIntended = _defaultFps;
  final frameIntervalMs = 1000.0 * stride / fpsIntended;

  final inferenceTimes = <int>[];
  final frames = <NeutralFrame>[];
  var processedIndex = 0;
  var timestampMs = 0.0;
  var lowConfidenceFrames = 0;
  final progressTimer = Stopwatch()..start();

  try {
    for (var sourceIndex = 0;
        sourceIndex < decodeResult.frames.length;
        sourceIndex++) {
      if (sourceIndex % stride != 0) {
        continue;
      }

      final raw = decodeResult.frames[sourceIndex];
      final stopwatch = Stopwatch()..start();
      NeutralFrame frame;
      try {
        frame = await engine.infer(PoseEngineInput(
          imageBytes: raw.bytes,
          width: raw.width,
          height: raw.height,
          rotationDeg: raw.rotationDeg,
          frameIndex: processedIndex,
          timestampMs: timestampMs.round(),
          mirrorHorizontally: shouldMirror,
        ));
      } catch (e) {
        throw _CliException(
          'Pose inference failed at frame $sourceIndex: $e',
          _exitInferenceError,
        );
      }
      stopwatch.stop();
      inferenceTimes.add(stopwatch.elapsedMicroseconds ~/ 1000);

      final filteredKeypoints = frame.keypoints
          .where((kp) => kp.score >= 0.3)
          .toList(growable: false);
      final lowConfidence = frame.lowConfidence;
      if (lowConfidence) {
        lowConfidenceFrames++;
      }

      frames.add(NeutralFrame(
        frameIndex: processedIndex,
        timestampMs: timestampMs.round(),
        width: raw.width,
        height: raw.height,
        keypoints: filteredKeypoints,
        lowConfidence: lowConfidence,
        mirrorApplied: frame.mirrorApplied,
      ));

      processedIndex++;
      timestampMs += frameIntervalMs;

      if (progressTimer.elapsedMilliseconds >= 2000) {
        final avgMs = _average(inferenceTimes);
        final usableRatio = processedIndex == 0
            ? 0.0
            : (processedIndex - lowConfidenceFrames) / processedIndex;
        final lowRatio = processedIndex == 0
            ? 0.0
            : lowConfidenceFrames / processedIndex;
        log(
          'PROG',
          'frames $processedIndex/${decodeResult.frameCount} | avg ${avgMs.toStringAsFixed(1)} ms | usable ${(usableRatio * 100).toStringAsFixed(1)}% | lowConf ${(lowRatio * 100).toStringAsFixed(1)}%',
        );
        progressTimer..reset()..start();
      }
    }
  } finally {
    await engine.close();
  }

  final durationMs = probe.durationMs > 0
      ? probe.durationMs
      : (decodeResult.durationMs > 0
          ? decodeResult.durationMs
          : (frames.isEmpty ? 0 : ((frames.length - 1) * frameIntervalMs).round()));

  final neutralSeries = NeutralKeypointSeries(
    version: 'vB1.1',
    video: NeutralVideoInfo(
      basename: baseName,
      fpsIntended: fpsIntended,
      width: decodeResult.width,
      height: decodeResult.height,
      durationMs: durationMs,
    ),
    engine: const NeutralEngineInfo(
      name: 'mlkit',
      model: 'blazepose-full',
      sdkVersion: '0.14.0',
    ),
    sampling: NeutralSamplingInfo(
      stride: stride,
      effectiveFps: fpsIntended / stride,
    ),
    frames: frames
        .map((frame) => NeutralFrameData(
              frameIndex: frame.frameIndex,
              timestampMs: frame.timestampMs,
              lowConfidence: frame.lowConfidence,
              mirrorApplied: frame.mirrorApplied,
              keypoints: frame.keypoints
                  .map((kp) => NeutralKeypointValue(
                        name: kp.name,
                        x: kp.x,
                        y: kp.y,
                        z: kp.z,
                        score: kp.score,
                      ))
                  .toList(growable: false),
            ))
        .toList(growable: false),
  );

  final poseSeries = poseSeriesFromNeutral(neutralSeries);
  final pipeline = OfflinePipeline(ruleSet, strictness);
  late final ({String anglesCsv, Map<String, dynamic> resultJson}) pipelineOut;
  try {
    pipelineOut = await pipeline.run(poseSeries);
  } catch (e) {
    throw _CliException('Offline pipeline failed: $e', _exitInferenceError);
  }

  final resultJson = Map<String, dynamic>.from(pipelineOut.resultJson)
    ..['engine'] = 'mlkit'
    ..['engineVersion'] = '0.14.0'
    ..['inputResolution'] = resolution
    ..['samplingStride'] = stride;

  final neutralJson = neutralKeypointSeriesToJson(neutralSeries);

  final anglesFile = File(path.join(outDir.path, 'angles.csv'));
  final resultFile = File(path.join(outDir.path, 'result.json'));
  final neutralFile = File(path.join(outDir.path, 'neutral_keypoints.json'));

  final writeStopwatch = Stopwatch()..start();
  try {
    await anglesFile.writeAsString(pipelineOut.anglesCsv);
    await resultFile.writeAsString(jsonPretty(resultJson));
    await neutralFile.writeAsString(jsonPretty(neutralJson));
  } on IOException catch (e) {
    throw _CliException('Failed to write outputs: $e', _exitOutputError);
  }
  writeStopwatch.stop();

  final perfFile = File(path.join(logsDir.path, 'perf.json'));
  final perfData = _buildPerfMetrics(
    decodeResult: decodeResult,
    processedFrames: frames.length,
    lowConfidenceFrames: lowConfidenceFrames,
    inferenceTimes: inferenceTimes,
    writeOutMs: writeStopwatch.elapsedMilliseconds,
    stride: stride,
    resolution: resolution,
    durationMs: durationMs,
  );
  await perfFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(perfData),
  );

  final runLogFile = File(path.join(logsDir.path, 'run.log'));
  await runLogFile.writeAsString(runLog.join('\n'));

  log('DONE', 'Outputs written:');
  log('DONE', '  - ${anglesFile.path}');
  log('DONE', '  - ${resultFile.path}');
  log('DONE', '  - ${neutralFile.path}');
  log('DONE', '  - ${perfFile.path}');

  final avgMs = perfData['avgInferenceMs'] as double;
  final usableRatio = perfData['usableFrameRatio'] as double;
  final lowRatio = perfData['lowConfidenceRatio'] as double;

  if (avgMs > 35.0) {
    log('WARN', 'Average inference time ${avgMs.toStringAsFixed(2)} ms exceeds target ≤ 35 ms.');
  }
  if (usableRatio < 0.70) {
    log('WARN', 'Usable frame ratio ${(usableRatio * 100).toStringAsFixed(2)}% below target ≥ 70%.');
  }
  if (lowRatio > 0.10) {
    log('WARN', 'Low confidence ratio ${(lowRatio * 100).toStringAsFixed(2)}% above target ≤ 10%.');
  }
}

Future<String> _readFile(String pathStr, String label) async {
  try {
    return await File(pathStr).readAsString();
  } on IOException catch (e) {
    throw _CliException('Failed to read $label from "$pathStr": $e', _exitParamError);
  }
}

Future<_VideoProbeResult> _probeVideo(String videoPath) async {
  try {
    final result = await Process.run('ffprobe', [
      '-v',
      'error',
      '-select_streams',
      'v:0',
      '-show_entries',
      'stream=width,height,avg_frame_rate',
      '-show_entries',
      'format=duration',
      '-of',
      'json',
      videoPath,
    ]);

    if (result.exitCode != 0) {
      throw _CliException(
        'ffprobe failed (${result.exitCode}): ${result.stderr}',
        _exitDecodeError,
      );
    }

    final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final streams = decoded['streams'] as List<dynamic>?;
    if (streams == null || streams.isEmpty) {
      throw _CliException(
        'ffprobe could not find a video stream in "$videoPath".',
        _exitDecodeError,
      );
    }
    final stream = streams.first as Map<String, dynamic>;
    final width = (stream['width'] as num?)?.toInt() ?? 0;
    final height = (stream['height'] as num?)?.toInt() ?? 0;
    final fpsStr = stream['avg_frame_rate'] as String? ?? '0/1';
    final fps = _parseFps(fpsStr);

    final format = decoded['format'] as Map<String, dynamic>?;
    final durationStr = format?['duration'] as String?;
    final durationMs = durationStr != null
        ? (double.tryParse(durationStr) ?? 0.0) * 1000
        : 0.0;

    return _VideoProbeResult(
      width: width,
      height: height,
      fps: fps > 0 ? fps : _defaultFps,
      durationMs: durationMs.round(),
    );
  } on ProcessException catch (e) {
    throw _CliException(
      'ffprobe not available or failed to start: $e',
      _exitDecodeError,
    );
  }
}

Future<_VideoDecodeResult> _decodeVideo({
  required String videoPath,
  required int targetWidth,
  required int targetHeight,
  required double targetFps,
}) async {
  final stopwatch = Stopwatch()..start();
  final frames = <RawImageFrame>[];
  final bytesPerFrame = (targetWidth * targetHeight * 3) ~/ 2;

  Process process;
  try {
    process = await Process.start('ffmpeg', [
      '-hide_banner',
      '-loglevel',
      'error',
      '-i',
      videoPath,
      '-vf',
      'fps=$targetFps,scale=$targetWidth:$targetHeight',
      '-pix_fmt',
      'nv21',
      '-f',
      'rawvideo',
      'pipe:1',
    ]);
  } on ProcessException catch (e) {
    throw _CliException('ffmpeg not available: $e', _exitDecodeError);
  }

  final stderrFuture = process.stderr.transform(utf8.decoder).join();

  List<int> buffer = [];
  await for (final chunk in process.stdout) {
    buffer.addAll(chunk);
    var offset = 0;
    while (buffer.length - offset >= bytesPerFrame) {
      final frameBytes = Uint8List.fromList(
        buffer.sublist(offset, offset + bytesPerFrame),
      );
      frames.add(RawImageFrame(
        bytes: frameBytes,
        width: targetWidth,
        height: targetHeight,
        rotationDeg: 0,
      ));
      offset += bytesPerFrame;
    }
    if (offset > 0) {
      buffer = buffer.sublist(offset);
    }
  }

  final exitCode = await process.exitCode;
  final stderrText = await stderrFuture;
  stopwatch.stop();

  if (exitCode != 0) {
    throw _CliException(
      'ffmpeg decode failed ($exitCode): $stderrText',
      _exitDecodeError,
    );
  }

  final durationMs = (frames.length * (1000 / targetFps)).round();

  return _VideoDecodeResult(
    frames: frames,
    width: targetWidth,
    height: targetHeight,
    fps: targetFps,
    durationMs: durationMs,
    decodeMs: stopwatch.elapsedMilliseconds,
  );
}

int _computeTargetWidth(_VideoProbeResult probe, int targetHeight) {
  if (probe.width > 0 && probe.height > 0) {
    var width = (probe.width * targetHeight / probe.height).round();
    if (width.isOdd) {
      width += 1;
    }
    return math.max(width, 2);
  }
  if (targetHeight == 540) {
    return 960;
  }
  return 1280;
}

double _parseFps(String fpsStr) {
  if (fpsStr.contains('/')) {
    final parts = fpsStr.split('/');
    final numerator = double.tryParse(parts.first) ?? 0.0;
    final denominator = double.tryParse(parts.last) ?? 1.0;
    if (denominator == 0) {
      return 0.0;
    }
    return numerator / denominator;
  }
  return double.tryParse(fpsStr) ?? 0.0;
}

double _average(List<int> values) {
  if (values.isEmpty) {
    return 0.0;
  }
  final sum = values.fold<int>(0, (acc, v) => acc + v);
  return sum / values.length;
}

double _p95(List<int> values) {
  if (values.isEmpty) {
    return 0.0;
  }
  final sorted = values.toList()..sort();
  final index = (sorted.length * 0.95).ceil() - 1;
  return sorted[index.clamp(0, sorted.length - 1)].toDouble();
}

Map<String, dynamic> _buildPerfMetrics({
  required _VideoDecodeResult decodeResult,
  required int processedFrames,
  required int lowConfidenceFrames,
  required List<int> inferenceTimes,
  required int writeOutMs,
  required int stride,
  required String resolution,
  required int durationMs,
}) {
  final avgMs = _average(inferenceTimes);
  final p95Ms = _p95(inferenceTimes);
  final usableRatio = processedFrames == 0
      ? 0.0
      : (processedFrames - lowConfidenceFrames) / processedFrames;
  final lowRatio = processedFrames == 0
      ? 0.0
      : lowConfidenceFrames / processedFrames;

  return {
    'totalFrames': decodeResult.frameCount,
    'processedFrames': processedFrames,
    'droppedFrames': decodeResult.frameCount - processedFrames,
    'avgInferenceMs': double.parse(avgMs.toStringAsFixed(3)),
    'p95InferenceMs': double.parse(p95Ms.toStringAsFixed(3)),
    'decodeMs': decodeResult.decodeMs,
    'writeOutMs': writeOutMs,
    'usableFrameRatio': double.parse(usableRatio.toStringAsFixed(4)),
    'lowConfidenceRatio': double.parse(lowRatio.toStringAsFixed(4)),
    'deviceInfo': {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
    },
    'engine': {
      'name': 'mlkit',
      'model': 'blazepose-full',
      'sdkVersion': '0.14.0',
    },
    'inputResolution': resolution,
    'samplingStride': stride,
    'durationSec': durationMs / 1000.0,
  };
}