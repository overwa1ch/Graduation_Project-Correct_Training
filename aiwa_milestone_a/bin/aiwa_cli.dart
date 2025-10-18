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
import 'package:aiwa_milestone_a/pose/keypoint_names.dart';
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
const _defaultHybridPolicy = 'configs/hybrid_policy.json';
const _defaultEvidenceConfig = 'configs/evidence_config.json';
const _defaultCueAdviceMap = 'rules/cue_advice_map.json';

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
        negatable: false,
        help: 'Force overlay.mp4 export when evidence pipeline is enabled (placeholder).')
    ..addFlag('hybrid',
        negatable: false, help: 'Enable Hybrid placeholder workflow outputs.')
    ..addOption('hybrid-policy',
        defaultsTo: _defaultHybridPolicy,
        help: 'Hybrid policy JSON path (default: $_defaultHybridPolicy).')
    ..addOption('cloud-mock',
        help: 'Mock cloud response JSON used when Hybrid triggers.')
    ..addFlag('cloud-video-fragment',
        negatable: false,
        help: 'Include optional video fragment reference in cloud payload audit.')
    ..addFlag('evidence',
        negatable: false, help: 'Enable evidence pipeline outputs.')
    ..addOption('evidence-config',
        defaultsTo: _defaultEvidenceConfig,
        help: 'Evidence pipeline config JSON (default: $_defaultEvidenceConfig).')
    ..addMultiOption('evidence-param',
        valueHelp: 'key=value',
        help: 'Override evidence config entries (e.g. --evidence-param topK=8).');
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
  final pipelineWatch = Stopwatch()..start();
  late final ({String anglesCsv, Map<String, dynamic> resultJson}) out;
  try {
    out = await pipeline.run(poseSeries);
  } catch (e) {
    throw _CliException('Offline pipeline failed: $e', _exitInferenceError);
  } finally {
    pipelineWatch.stop();
  }

  final outRoot = Directory(opts['out'] as String? ?? _defaultOutDir);
  final baseName = path.basenameWithoutExtension(keypointsPath);
  final outDir = Directory(path.join(outRoot.path, baseName))
    ..createSync(recursive: true);

  final perfContext = {
    'mode': 'file',
    'pipelineMs': pipelineWatch.elapsedMilliseconds,
  };

  await _finalizeOutputs(
    mode: 'file',
    opts: opts,
    baseName: baseName,
    outDir: outDir,
    poseSeries: poseSeries,
    neutralSeries: neutralSeries,
    anglesCsv: out.anglesCsv,
    resultJson: out.resultJson,
    perfContext: perfContext,
  );

  stdout.writeln('[DONE] Offline pipeline completed → ${outDir.path}');
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
  final pipelineWatch = Stopwatch()..start();
  late final ({String anglesCsv, Map<String, dynamic> resultJson}) pipelineOut;
  try {
    pipelineOut = await pipeline.run(poseSeries);
  } catch (e) {
    throw _CliException('Offline pipeline failed: $e', _exitInferenceError);
  } finally {
    pipelineWatch.stop();
  }

  final perfContext = {
    'mode': 'engine',
    'decodeMs': decodeResult.decodeMs,
    'processedFrames': frames.length,
    'totalFrames': decodeResult.frameCount,
    'avgInferenceMs': _average(inferenceTimes),
    'p95InferenceMs': _p95(inferenceTimes),
    'lowConfidenceFrames': lowConfidenceFrames,
    'pipelineMs': pipelineWatch.elapsedMilliseconds,
    'stride': stride,
    'resolution': resolution,
    'durationMs': durationMs,
  };

  await _finalizeOutputs(
    mode: 'engine',
    opts: opts,
    baseName: baseName,
    outDir: outDir,
    poseSeries: poseSeries,
    neutralSeries: neutralSeries,
    anglesCsv: pipelineOut.anglesCsv,
    resultJson: Map<String, dynamic>.from(pipelineOut.resultJson)
      ..['engine'] = 'mlkit'
      ..['engineVersion'] = '0.14.0'
      ..['inputResolution'] = resolution
      ..['samplingStride'] = stride,
    perfContext: perfContext,
    engineLogs: runLog,
  );

  log('DONE', 'Artifacts written → ${outDir.path}');

  final avgMs = perfContext['avgInferenceMs'] as double? ?? 0.0;
  final usableRatio = frames.isEmpty
      ? 0.0
      : (frames.length - lowConfidenceFrames) / frames.length;
  final lowRatio = frames.isEmpty ? 0.0 : lowConfidenceFrames / frames.length;

  if (avgMs > 35.0) {
    log('WARN', 'Average inference time ${avgMs.toStringAsFixed(2)} ms exceeds target ≤ 35 ms.');
  }
  if (usableRatio < 0.70) {
    log('WARN',
        'Usable frame ratio ${(usableRatio * 100).toStringAsFixed(2)}% below target ≥ 70%.');
  }
  if (lowRatio > 0.10) {
    log('WARN',
        'Low confidence ratio ${(lowRatio * 100).toStringAsFixed(2)}% above target ≤ 10%.');
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

Future<void> _finalizeOutputs({
  required String mode,
  required ArgResults opts,
  required String baseName,
  required Directory outDir,
  required PoseSeries poseSeries,
  required String anglesCsv,
  required Map<String, dynamic> resultJson,
  required Map<String, dynamic> perfContext,
  NeutralKeypointSeries? neutralSeries,
  List<String>? engineLogs,
}) async {
  final logsDir = Directory(path.join(outDir.path, 'logs'))
    ..createSync(recursive: true);

  final anglesFile = File(path.join(outDir.path, 'angles.csv'));
  final resultFile = File(path.join(outDir.path, 'result.json'));
  final neutralFile =
      neutralSeries != null ? File(path.join(outDir.path, 'neutral_keypoints.json')) : null;
  final artifactPaths = <String>[];

  try {
    await anglesFile.writeAsString(anglesCsv);
    artifactPaths.add(anglesFile.path);
    if (neutralSeries != null && neutralFile != null) {
      await neutralFile.writeAsString(
        jsonPretty(neutralKeypointSeriesToJson(neutralSeries)),
      );
      artifactPaths.add(neutralFile.path);
    }
  } on IOException catch (e) {
    throw _CliException('Failed to write outputs: $e', _exitOutputError);
  }

  final evidenceOverrides =
      (opts['evidence-param'] as Iterable?)?.cast<String>().toList() ?? const <String>[];
  _EvidenceGenerationResult? evidence;
  Map<String, dynamic>? evidenceSummary;
  var evidenceMs = 0;
  try {
    final evidenceConfig =
        await _loadEvidenceConfig(opts['evidence-config'] as String, overrides: evidenceOverrides);
    final cueAdvice = await _loadCueAdvice();
    final evidenceWatch = Stopwatch()..start();
    evidence = _generateEvidence(
      poseSeries: poseSeries,
      resultJson: resultJson,
      config: evidenceConfig,
      cueAdvice: cueAdvice,
    );
    evidenceWatch.stop();
    evidenceMs = evidenceWatch.elapsedMilliseconds;
    evidenceSummary = evidence.summary;
    resultJson['evidence'] = evidence.records;

    if (opts['evidence'] == true) {
      final evidenceFile = File(path.join(outDir.path, 'evidence.json'));
      await evidenceFile.writeAsString(jsonPretty(evidence.records));
      artifactPaths.add(evidenceFile.path);

      if (opts['overlay'] == true) {
        try {
          await _exportBlankOverlay(
            path.join(outDir.path, 'overlay.mp4'),
            durationMs: evidence.overlayDurationMs,
            resolution: poseSeries.metadata.height ?? 540,
          );
          artifactPaths.add(path.join(outDir.path, 'overlay.mp4'));
        } catch (e) {
          stderr.writeln('[WARN] Overlay export failed: $e');
        }
      }
    }
  } catch (e) {
    if (e is _CliException) rethrow;
    throw _CliException('Evidence pipeline failed: $e', _exitOutputError);
  }

  final bool hybridEnabled = opts['hybrid'] == true;
  Map<String, dynamic>? hybridTrigger;
  Map<String, dynamic>? cloudPayload;
  Map<String, dynamic>? payloadAudit;
  Map<String, dynamic>? hybridDiff;
  Map<String, dynamic>? hybridInfo;
  var hybridMs = 0;

  if (hybridEnabled) {
    final hybridPolicy = await _loadHybridPolicy(opts['hybrid-policy'] as String);
    final hybridWatch = Stopwatch()..start();
    final evaluation = _evaluateHybrid(
      policy: hybridPolicy,
      poseSeries: poseSeries,
      resultJson: resultJson,
    );
    hybridWatch.stop();
    hybridMs = hybridWatch.elapsedMilliseconds;
    hybridTrigger = evaluation.toJson();

    Map<String, dynamic>? cloudMock;
    final cloudMockPath = opts['cloud-mock'] as String?;
    if (evaluation.triggered && cloudMockPath != null && cloudMockPath.isNotEmpty) {
      final cloudStr = await _readFile(cloudMockPath, 'cloud mock');
      cloudMock = jsonDecode(cloudStr) as Map<String, dynamic>;
    }

    if (evaluation.triggered) {
      final includeVideo = opts['cloud-video-fragment'] == true;
      cloudPayload = _buildCloudPayload(
        baseName: baseName,
        policy: hybridPolicy,
        poseSeries: poseSeries,
        evaluation: evaluation,
        includeVideoFragment: includeVideo,
      );
      payloadAudit = _buildPayloadAudit(
        payload: cloudPayload,
        includeVideo: includeVideo,
      );

      if (cloudMock != null) {
        final merge = _mergeHybridResults(
          localResult: resultJson,
          cloudResult: cloudMock,
          reasons: evaluation.reasons,
        );
        resultJson = merge.finalResult;
        hybridDiff = merge.diff;
        hybridInfo = merge.hybridInfo;
      } else {
        hybridInfo = {
          'triggered': true,
          'reason': evaluation.reasons,
          'cloudEnhanced': false,
          'mergeStrategy': 'local_only',
        };
        resultJson['hybrid'] = hybridInfo;
      }
    } else {
      hybridInfo = {
        'triggered': false,
        'reason': evaluation.reasons,
        'cloudEnhanced': false,
        'mergeStrategy': 'skip',
      };
      resultJson['hybrid'] = hybridInfo;
    }
  } else {
    resultJson['hybrid'] ??= {
      'triggered': false,
      'cloudEnhanced': false,
    };
  }

  try {
    await resultFile.writeAsString(jsonPretty(resultJson));
    artifactPaths.add(resultFile.path);
  } on IOException catch (e) {
    throw _CliException('Failed to write result.json: $e', _exitOutputError);
  }

  final timings = Map<String, dynamic>.from(perfContext);
  final modeStr = (timings.remove('mode') ?? mode).toString();
  if (evidence != null) {
    timings['evidenceMs'] = evidenceMs;
  }
  if (hybridEnabled) {
    timings['hybridMs'] = hybridMs;
  }

  final perfData = {
    'timestamp': DateTime.now().toIso8601String(),
    'mode': modeStr,
    'frames': poseSeries.frames.length,
    'fps': poseSeries.fps,
    'timings': timings,
    if (hybridInfo != null) 'hybrid': hybridInfo,
    if (evidenceSummary != null) 'evidence': evidenceSummary,
    'device': {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'hostname': Platform.localHostname,
    },
  };

  final perfFile = File(path.join(logsDir.path, 'perf.json'));
  await perfFile.writeAsString(jsonPretty(perfData));

  if (engineLogs != null && engineLogs.isNotEmpty) {
    final runLogFile = File(path.join(logsDir.path, 'run.log'));
    await runLogFile.writeAsString(engineLogs.join('\n'));
  }

  if (hybridTrigger != null) {
    final triggerFile = File(path.join(outDir.path, 'hybrid_trigger.json'));
    await triggerFile.writeAsString(jsonPretty(hybridTrigger));
    artifactPaths.add(triggerFile.path);
  }
  if (cloudPayload != null) {
    final payloadFile = File(path.join(outDir.path, 'cloud_payload.json'));
    await payloadFile.writeAsString(jsonPretty(cloudPayload));
    artifactPaths.add(payloadFile.path);
  }
  if (payloadAudit != null) {
    final auditFile = File(path.join(outDir.path, 'payload_audit.json'));
    await auditFile.writeAsString(jsonPretty(payloadAudit));
    artifactPaths.add(auditFile.path);
  }
  if (hybridDiff != null) {
    final diffFile = File(path.join(outDir.path, 'hybrid_diff.json'));
    await diffFile.writeAsString(jsonPretty(hybridDiff));
    artifactPaths.add(diffFile.path);
  }

  final hybridSummary = resultJson['hybrid'] as Map?;
  if (hybridEnabled && hybridSummary != null) {
    final triggered = hybridSummary['triggered'] == true;
    final reasons = (hybridSummary['reason'] as List?)?.join(',') ?? 'none';
    final delta = hybridSummary['delta'] as Map? ?? const {};
    final localCount = (delta['countLocal'] as num?)?.toInt() ??
        (resultJson['repCount'] as num?)?.toInt() ?? 0;
    final cloudCount = (delta['countCloud'] as num?)?.toInt();
    final finalCount = (delta['countFinal'] as num?)?.toInt() ?? localCount;
    final enhanced = hybridSummary['cloudEnhanced'] == true;
    stdout.writeln(
        'HYBRID ${triggered ? 'on' : 'off'} | reasons=[$reasons] | ${enhanced ? 'cloudEnhanced' : 'localOnly'} | finalCount=$finalCount (local=$localCount${cloudCount != null ? ', cloud=$cloudCount' : ''})');
  }

  if (artifactPaths.isNotEmpty) {
    stdout.writeln('Artifacts generated → ${outDir.path}:');
    for (final artifact in artifactPaths) {
      stdout.writeln('  - $artifact');
    }
  }
}

Future<_HybridPolicy> _loadHybridPolicy(String pathStr) async {
  final policyStr = await _readFile(pathStr, 'hybrid policy');
  final root = jsonDecode(policyStr) as Map<String, dynamic>;
  return _HybridPolicy.fromJson(root);
}

Future<_EvidenceConfig> _loadEvidenceConfig(String pathStr,
    {List<String> overrides = const []}) async {
  final configStr = await _readFile(pathStr, 'evidence config');
  final root = jsonDecode(configStr) as Map<String, dynamic>;
  for (final override in overrides) {
    final parts = override.split('=');
    if (parts.length != 2) continue;
    final key = parts.first.trim();
    final value = parts.last.trim();
    if (key.isEmpty) continue;
    if (num.tryParse(value) != null) {
      root[key] = num.tryParse(value);
    } else if (value == 'true' || value == 'false') {
      root[key] = value == 'true';
    } else {
      root[key] = value;
    }
  }
  return _EvidenceConfig.fromJson(root);
}

Future<Map<String, dynamic>> _loadCueAdvice() async {
  final adviceStr = await _readFile(_defaultCueAdviceMap, 'cue advice map');
  return jsonDecode(adviceStr) as Map<String, dynamic>;
}

class _HybridPolicy {
  final String version;
  final Map<String, num> global;
  final Map<String, Map<String, num>> byEngine;
  final Map<String, double> weights;
  final List<String> triggerRules;
  final bool fireIfAnyRuleTrue;
  final int sliceMsBefore;
  final int sliceMsAfter;
  final String privacy;
  final double confThreshold;

  _HybridPolicy({
    required this.version,
    required this.global,
    required this.byEngine,
    required this.weights,
    required this.triggerRules,
    required this.fireIfAnyRuleTrue,
    required this.sliceMsBefore,
    required this.sliceMsAfter,
    required this.privacy,
    required this.confThreshold,
  });

  factory _HybridPolicy.fromJson(Map<String, dynamic> json) {
    final global = <String, num>{};
    for (final entry in (json['global'] as Map<String, dynamic>).entries) {
      if (entry.value is num) {
        global[entry.key] = entry.value as num;
      }
    }
    final byEngineRaw = json['byEngine'] as Map<String, dynamic>? ?? {};
    final byEngine = <String, Map<String, num>>{};
    for (final entry in byEngineRaw.entries) {
      final raw = entry.value as Map<String, dynamic>;
      byEngine[entry.key] = {
        for (final e in raw.entries)
          if (e.value is num) e.key: e.value as num,
      };
    }
    final weights = <String, double>{};
    for (final entry in (json['weights'] as Map<String, dynamic>? ?? {}).entries) {
      if (entry.value is num) {
        weights[entry.key] = (entry.value as num).toDouble();
      }
    }
    final confThreshold = (json['global']?['confThreshold'] as num?)?.toDouble() ??
        (json['confThreshold'] as num?)?.toDouble() ??
        0.5;
    return _HybridPolicy(
      version: json['version'] as String? ?? 'C1',
      global: global,
      byEngine: byEngine,
      weights: weights,
      triggerRules:
          (json['triggerRules'] as List?)?.cast<String>().toList() ?? const [],
      fireIfAnyRuleTrue: json['fireIfAnyRuleTrue'] == true,
      sliceMsBefore: (json['sliceMsBefore'] as num?)?.toInt() ?? 1500,
      sliceMsAfter: (json['sliceMsAfter'] as num?)?.toInt() ?? 1500,
      privacy: json['privacy'] as String? ?? 'keypoints_only',
      confThreshold: confThreshold,
    );
  }

  Map<String, num> thresholdsForEngine(String? engine) {
    final combined = Map<String, num>.from(global);
    final overrides = engine != null ? byEngine[engine] : null;
    if (overrides != null) {
      combined.addAll(overrides);
    }
    return combined;
  }
}

class _HybridEvaluation {
  final bool triggered;
  final List<String> reasons;
  final Map<String, double> metrics;
  final Map<String, num> thresholds;
  final double weightedScore;

  _HybridEvaluation({
    required this.triggered,
    required this.reasons,
    required this.metrics,
    required this.thresholds,
    required this.weightedScore,
  });

  Map<String, dynamic> toJson() => {
        'triggered': triggered,
        'reasons': reasons,
        'metrics': metrics,
        'thresholds': thresholds,
        'weightedScore': weightedScore,
      };
}

_HybridEvaluation _evaluateHybrid({
  required _HybridPolicy policy,
  required PoseSeries poseSeries,
  required Map<String, dynamic> resultJson,
}) {
  final thresholds = policy.thresholdsForEngine(poseSeries.metadata.engine);

  final coverage =
      (resultJson['quality']?['coverage'] as num?)?.toDouble() ?? 0.0;
  final lowConfFrames =
      poseSeries.frames.where((frame) => frame.lowConfidence).length;
  final totalFrames = poseSeries.frames.length;
  final lowConfPct = totalFrames == 0
      ? 0.0
      : lowConfFrames / totalFrames;
  final jitter = _computeJitterPx(poseSeries);
  final fps = _computeMedianFps(poseSeries);

  final metrics = {
    'coverage': coverage,
    'lowConfPct': lowConfPct,
    'jitterPx': jitter,
    'fps': fps,
  };

  final reasons = <String>[];
  var ruleTriggered = false;

  bool evaluateRule(String rule) {
    final parts = rule.split(' ');
    if (parts.length != 3) return false;
    final metricName = parts[0];
    final op = parts[1];
    final thresholdKey = parts[2];
    final metricValue = metrics[metricName];
    final thresholdValue = thresholds[thresholdKey];
    if (metricValue == null || thresholdValue == null) {
      return false;
    }
    final thresholdDouble = thresholdValue.toDouble();
    switch (op) {
      case '<':
        return metricValue < thresholdDouble;
      case '>':
        return metricValue > thresholdDouble;
      case '<=':
        return metricValue <= thresholdDouble;
      case '>=':
        return metricValue >= thresholdDouble;
      default:
        return false;
    }
  }

  for (final rule in policy.triggerRules) {
    final hit = evaluateRule(rule);
    if (hit) {
      reasons.add(rule);
      ruleTriggered = true;
    }
  }

  final normalized = <String, double>{
    'coverage': _normalizeHighGood(
      metrics['coverage'] ?? 0.0,
      thresholds['minCoveragePct']?.toDouble() ?? 1.0,
    ),
    'lowConfPct': _normalizeLowGood(
      metrics['lowConfPct'] ?? 0.0,
      thresholds['maxLowConfPct']?.toDouble() ?? 1.0,
    ),
    'jitterPx': _normalizeLowGood(
      metrics['jitterPx'] ?? 0.0,
      thresholds['maxJitterPx']?.toDouble() ?? 10.0,
    ),
    'fps': _normalizeHighGood(
      metrics['fps'] ?? 0.0,
      thresholds['minFps']?.toDouble() ?? 30.0,
    ),
  };

  var weightSum = 0.0;
  var weightedScore = 0.0;
  policy.weights.forEach((metric, weight) {
    final value = normalized[metric];
    if (value != null) {
      weightSum += weight;
      weightedScore += value * weight;
    }
  });
  if (weightSum > 0) {
    weightedScore /= weightSum;
  }

  final aggregateTriggered = weightedScore < policy.confThreshold;
  if (aggregateTriggered) {
    reasons.add('score<${policy.confThreshold.toStringAsFixed(2)}');
  }

  final triggered = policy.fireIfAnyRuleTrue
      ? (ruleTriggered || aggregateTriggered)
      : aggregateTriggered;

  return _HybridEvaluation(
    triggered: triggered,
    reasons: reasons,
    metrics: metrics,
    thresholds: thresholds,
    weightedScore: weightedScore,
  );
}

double _normalizeHighGood(double value, double threshold) {
  if (threshold <= 0) return 0.0;
  if (value >= threshold) return 1.0;
  return (value / threshold).clamp(0.0, 1.0);
}

double _normalizeLowGood(double value, double threshold) {
  if (threshold <= 0) return 1.0;
  if (value <= threshold) return 1.0;
  if (value == 0) return 1.0;
  return (threshold / value).clamp(0.0, 1.0);
}

double _computeMedianFps(PoseSeries series) {
  if (series.frames.length < 2) return series.fps;
  final diffs = <int>[];
  for (var i = 1; i < series.frames.length; i++) {
    final delta = series.frames[i].timestampMs - series.frames[i - 1].timestampMs;
    if (delta > 0) {
      diffs.add(delta);
    }
  }
  if (diffs.isEmpty) return series.fps;
  diffs.sort();
  final median = diffs[diffs.length ~/ 2];
  if (median == 0) return series.fps;
  return 1000.0 / median;
}

double _computeJitterPx(PoseSeries series) {
  if (series.frames.length < 2) return 0.0;
  final width = (series.metadata.width ?? 1).toDouble();
  final height = (series.metadata.height ?? 1).toDouble();
  final hasPixelScale = width > 1 && height > 1;

  var sumSquares = 0.0;
  var count = 0;
  for (var i = 1; i < series.frames.length; i++) {
    final prev = series.frames[i - 1];
    final curr = series.frames[i];
    for (final name in kPrimaryLowerBodyJoints) {
      final p1 = prev.keypoints[name];
      final p2 = curr.keypoints[name];
      if (p1 == null || p2 == null) continue;
      if (!p1.isReliable || !p2.isReliable) continue;
      final dx = (p2.x - p1.x) * (hasPixelScale ? width : 1.0);
      final dy = (p2.y - p1.y) * (hasPixelScale ? height : 1.0);
      sumSquares += dx * dx + dy * dy;
      count++;
    }
  }
  if (count == 0) return 0.0;
  return math.sqrt(sumSquares / count);
}

Map<String, dynamic> _buildCloudPayload({
  required String baseName,
  required _HybridPolicy policy,
  required PoseSeries poseSeries,
  required _HybridEvaluation evaluation,
  required bool includeVideoFragment,
}) {
  final timestamps = poseSeries.frames.map((f) => f.timestampMs).toList();
  if (timestamps.isEmpty) {
    return {
      'version': policy.version,
      'videoId': baseName,
      'engine': poseSeries.metadata.engine ?? 'unknown',
      'privacy': policy.privacy,
      'slice': {'startMs': 0, 'endMs': 0},
      'keypoints': {
        'fps': poseSeries.fps,
        'coordinateMode': 'normalized',
        'points': <Map<String, dynamic>>[],
      },
      'metrics': evaluation.metrics,
    };
  }

  final startMs = timestamps.first;
  final endMs = timestamps.last;
  final center = (startMs + endMs) ~/ 2;
  final sliceStart = math.max(startMs, center - policy.sliceMsBefore);
  final sliceEnd = math.min(endMs, center + policy.sliceMsAfter);
  final coordinateMode = poseSeries.metadata.width != null &&
          poseSeries.metadata.height != null &&
          poseSeries.metadata.width! > 1
      ? 'pixel'
      : 'normalized';

  final points = <Map<String, dynamic>>[];
  for (final frame in poseSeries.frames) {
    if (frame.timestampMs < sliceStart || frame.timestampMs > sliceEnd) {
      continue;
    }
    final tRel = frame.timestampMs - sliceStart;
    for (final entry in frame.keypoints.entries) {
      final name = entry.key;
      final kp = entry.value;
      final idx = kNeutralKeypointNames.indexOf(name);
      if (idx < 0) continue;
      final width = (poseSeries.metadata.width ?? 1).toDouble();
      final height = (poseSeries.metadata.height ?? 1).toDouble();
      final x = coordinateMode == 'pixel' ? kp.x * width : kp.x;
      final y = coordinateMode == 'pixel' ? kp.y * height : kp.y;
      points.add({
        't': tRel,
        'id': idx,
        'name': name,
        'x': double.parse(x.toStringAsFixed(6)),
        'y': double.parse(y.toStringAsFixed(6)),
        'conf': double.parse(kp.score.toStringAsFixed(3)),
      });
    }
  }

  final payload = {
    'version': policy.version,
    'videoId': baseName,
    'engine': poseSeries.metadata.engine ?? 'unknown',
    'privacy': policy.privacy,
    'slice': {
      'startMs': sliceStart,
      'endMs': sliceEnd,
    },
    'keypoints': {
      'fps': poseSeries.fps,
      'coordinateMode': coordinateMode,
      'points': points,
    },
    'metrics': evaluation.metrics,
  };

  if (includeVideoFragment) {
    payload['optional'] = {
      'video': '${baseName}_fragment.mp4',
      'angles': '${baseName}_angles.csv',
    };
  }

  return payload;
}

Map<String, dynamic> _buildPayloadAudit({
  required Map<String, dynamic> payload,
  required bool includeVideo,
}) {
  return {
    'timestamp': DateTime.now().toIso8601String(),
    'privacy': payload['privacy'],
    'triggered': true,
    'files': [
      {
        'path': 'cloud_payload.json',
        'size': jsonEncode(payload).length,
      },
      if (includeVideo)
        {
          'path': payload['optional']?['video'] ?? 'payload_segment.mp4',
          'consent': true,
        },
    ],
  };
}

class _HybridMergeResult {
  final Map<String, dynamic> finalResult;
  final Map<String, dynamic> diff;
  final Map<String, dynamic> hybridInfo;

  _HybridMergeResult({
    required this.finalResult,
    required this.diff,
    required this.hybridInfo,
  });
}

_HybridMergeResult _mergeHybridResults({
  required Map<String, dynamic> localResult,
  required Map<String, dynamic> cloudResult,
  required List<String> reasons,
}) {
  final merged = Map<String, dynamic>.from(localResult);
  final localCount = (localResult['repCount'] as num?)?.toInt() ?? 0;
  final cloudCount = (cloudResult['counts'] as num?)?.toInt() ?? localCount;

  final diff = <String, dynamic>{
    'localCount': localCount,
    'cloudCount': cloudCount,
    'localReps': localResult['reps'],
    'cloudReps': cloudResult['reps'],
    'notes': cloudResult['notes'],
  };

  final delta = {
    'countLocal': localCount,
    'countCloud': cloudCount,
    'countFinal': localCount,
  };

  var reconcileNote = '';
  var cloudEnhanced = false;
  var mergeStrategy = 'local_only';

  if ((localCount - cloudCount).abs() <= 1) {
    delta['countFinal'] = cloudCount;
    merged['repCount'] = cloudCount;
    cloudEnhanced = true;
    mergeStrategy = 'count_priority_cloud';
  } else {
    reconcileNote = 'Count delta > 1, fallback to local.';
  }

  final hybridInfo = {
    'triggered': true,
    'reason': reasons,
    'cloudEnhanced': cloudEnhanced,
    'mergeStrategy': mergeStrategy,
    'delta': delta,
    if (reconcileNote.isNotEmpty) 'reconcileNote': reconcileNote,
  };

  merged['hybrid'] = hybridInfo;

  return _HybridMergeResult(
    finalResult: merged,
    diff: diff,
    hybridInfo: hybridInfo,
  );
}

class _EvidenceConfig {
  final String version;
  final int topK;
  final int windowMs;
  final bool overlay;
  final List<String> angles;
  final Map<String, double> thresholds;

  const _EvidenceConfig({
    required this.version,
    required this.topK,
    required this.windowMs,
    required this.overlay,
    required this.angles,
    required this.thresholds,
  });

  factory _EvidenceConfig.fromJson(Map<String, dynamic> json) {
    final thresholdsRaw = (json['thresholds'] as Map<String, dynamic>? ?? {});
    final thresholds = <String, double>{};
    for (final entry in thresholdsRaw.entries) {
      if (entry.value is num) {
        thresholds[entry.key] = (entry.value as num).toDouble();
      }
    }
    return _EvidenceConfig(
      version: json['version'] as String? ?? 'C1',
      topK: (json['topK'] as num?)?.toInt() ?? 10,
      windowMs: (json['windowMs'] as num?)?.toInt() ?? 1200,
      overlay: json['export']?['overlay'] == true,
      angles: (json['angles'] as List?)?.cast<String>().toList() ?? const [],
      thresholds: thresholds,
    );
  }
}

class _EvidenceGenerationResult {
  final List<Map<String, dynamic>> records;
  final Map<String, dynamic> summary;
  final int overlayDurationMs;

  const _EvidenceGenerationResult({
    required this.records,
    required this.summary,
    required this.overlayDurationMs,
  });
}

_EvidenceGenerationResult _generateEvidence({
  required PoseSeries poseSeries,
  required Map<String, dynamic> resultJson,
  required _EvidenceConfig config,
  required Map<String, dynamic> cueAdvice,
}) {
  final reps = (resultJson['reps'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];
  final issues = (resultJson['issues'] as List?)?.cast<Map<String, dynamic>>() ??
      const <Map<String, dynamic>>[];

  final issueFrames = <String, Set<int>>{};
  for (final issue in issues) {
    final code = issue['code'] as String?;
    if (code == null) continue;
    final frames = (issue['frames'] as List?)?.cast<num>() ?? const <num>[];
    issueFrames[code] = frames.map((e) => e.toInt()).toSet();
  }

  final sortedReps = reps.toList()
    ..sort((a, b) {
      final aval = (b['kneeValleyAngle'] as num?)?.toDouble() ?? 0.0;
      final bval = (a['kneeValleyAngle'] as num?)?.toDouble() ?? 0.0;
      return aval.compareTo(bval);
    });

  final limit = config.topK <= 0 ? sortedReps.length : math.min(sortedReps.length, config.topK);
  final records = <Map<String, dynamic>>[];
  var minTs = poseSeries.frames.isEmpty ? 0 : poseSeries.frames.first.timestampMs;
  var maxTs = poseSeries.frames.isEmpty ? 0 : poseSeries.frames.last.timestampMs;

  final registeredCues = cueAdvice.keys.cast<String>().toSet();

  for (var i = 0; i < limit; i++) {
    final rep = sortedReps[i];
    final repIndex = (rep['index'] as num?)?.toInt() ?? (i + 1);
    final timestampMs = (rep['valleyMs'] as num?)?.toInt() ??
        (rep['startMs'] as num?)?.toInt() ?? 0;
    minTs = math.min(minTs, timestampMs);
    maxTs = math.max(maxTs, timestampMs);
    final frameIndex = _findFrameIndexByTimestamp(poseSeries, timestampMs);

    final cues = <String>{};
    for (final entry in issueFrames.entries) {
      if (entry.value.contains(timestampMs)) {
        final mapped = _mapIssueCodeToCue(entry.key);
        if (mapped != null) cues.add(mapped);
      }
    }

    final kneeValley = (rep['kneeValleyAngle'] as num?)?.toDouble();
    final minKneeOut = (rep['minKneeOutAngle'] as num?)?.toDouble();
    final forwardLean = (rep['maxForwardLean'] as num?)?.toDouble();

    final depthThreshold = config.thresholds['depth_minHipAngle'] ?? 90.0;
    if (kneeValley != null && kneeValley > depthThreshold) {
      cues.add('depth_insufficient');
    }
    final valgusThreshold = config.thresholds['leftKnee_maxValgus'] ?? 160.0;
    if (minKneeOut != null && minKneeOut < valgusThreshold) {
      cues.add('knee_inward');
    }
    final normalizedCues = cues.where(registeredCues.contains).toList();
    if (normalizedCues.isEmpty) {
      normalizedCues.add('asymmetry');
    }

    final angles = <String, double>{};
    if (kneeValley != null) {
      angles['leftKnee'] = kneeValley;
      angles['rightKnee'] = kneeValley;
    }
    if (forwardLean != null) {
      angles['hipFlexion'] = forwardLean;
    }

    final thresholds = {
      for (final entry in config.thresholds.entries)
        entry.key: entry.value,
    };

    final record = {
      'type': 'segment',
      'timestampMs': timestampMs,
      'frameIndex': frameIndex,
      'repIndex': repIndex,
      'cues': normalizedCues,
      'angles': angles,
      'thresholds': thresholds,
      'scoreImpact': _estimateScoreImpact(resultJson, normalizedCues.length),
      'snapshotPath': 'overlay.mp4#t=${(timestampMs / 1000).toStringAsFixed(2)}',
    };

    records.add(record);
  }

  final overlayDuration = config.windowMs + (maxTs - minTs);
  final summary = {
    'version': config.version,
    'count': records.length,
    'topK': config.topK,
    'windowMs': config.windowMs,
    'angles': config.angles,
  };

  return _EvidenceGenerationResult(
    records: records,
    summary: summary,
    overlayDurationMs: overlayDuration <= 0 ? config.windowMs : overlayDuration,
  );
}

String? _mapIssueCodeToCue(String code) {
  switch (code) {
    case 'DEPTH_INSUFFICIENT':
      return 'depth_insufficient';
    case 'KNEE_VALGUS':
      return 'knee_inward';
    case 'TRUNK_LEAN_EXCESSIVE':
      return 'asymmetry';
    default:
      return null;
  }
}

int _findFrameIndexByTimestamp(PoseSeries series, int timestampMs) {
  if (series.frames.isEmpty) return 0;
  var bestIndex = series.frames.first.index;
  var bestDelta = (series.frames.first.timestampMs - timestampMs).abs();
  for (final frame in series.frames) {
    final delta = (frame.timestampMs - timestampMs).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      bestIndex = frame.index;
    }
  }
  return bestIndex;
}

double _estimateScoreImpact(Map<String, dynamic> resultJson, int cueCount) {
  if (cueCount <= 0) return 0.0;
  final overall = (resultJson['scores']?['overall'] as num?)?.toDouble() ?? 0.0;
  final penalty = cueCount * 5.0;
  return double.parse((overall - penalty).toStringAsFixed(2));
}

Future<void> _exportBlankOverlay(String overlayPath,
    {required int durationMs, required int resolution}) async {
  final seconds = (durationMs / 1000.0).clamp(1.0, 30.0);
  final size = '${resolution}x$resolution';
  try {
    final result = await Process.run('ffmpeg', [
      '-y',
      '-f',
      'lavfi',
      '-i',
      'color=c=black:s=$size:d=$seconds',
      overlayPath,
    ], runInShell: true);
    if (result.exitCode != 0) {
      throw 'ffmpeg exited with ${result.exitCode}: ${result.stderr}';
    }
  } on ProcessException catch (e) {
    throw 'ffmpeg unavailable: $e';
  }
}

// End of helpers
