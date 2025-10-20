import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;

import 'package:aiwa_core/core/io.dart';
import 'package:aiwa_core/pipeline/offline_pipeline.dart';
import 'package:aiwa_core/pipeline/pose_input_converter.dart';
import 'package:aiwa_core/pipeline/pose_series.dart';
import 'package:aiwa_core/pose/frame_streamer.dart';
import 'package:aiwa_core/pose/kp_models.dart';
import 'package:aiwa_core/pose/keypoint_names.dart';
import 'package:aiwa_core/pose/neutral_keypoint_series.dart';
import 'package:aiwa_core/pose/pose_engine.dart';
import 'package:aiwa_core/spec/rule_models.dart';
import 'package:aiwa_core/spec/rule_parser.dart';

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

const JsonEncoder _prettyJsonEncoder = JsonEncoder.withIndent('  ');

typedef _LogFn = void Function(String level, String message);

final Map<String, int> _neutralNameToIndex = {
  for (var i = 0; i < kNeutralKeypointNames.length; i++)
    kNeutralKeypointNames[i]: i,
};

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
        negatable: false, help: 'Export overlay video in engine mode (optional).')
    ..addFlag('hybrid',
        negatable: false, help: 'Enable hybrid escalation and cloud merge flow.')
    ..addOption('hybrid-policy',
        help: 'Path to hybrid policy JSON.',
        defaultsTo: 'configs/hybrid_policy.json')
    ..addOption('cloud-mock',
        help: 'Optional cloud mock JSON for merge simulation (hybrid mode).')
    ..addFlag('evidence',
        negatable: false, help: 'Enable evidence export and enrichment.')
    ..addOption('evidence-config',
        help: 'Path to evidence configuration JSON.',
        defaultsTo: 'configs/evidence_config.json')
    ..addFlag('cloud-video-fragment',
        negatable: false,
        help: 'Export placeholder cloud video fragment when hybrid payload fires.');
}

String _usage(ArgParser parser) => '''
AIWA CLI — Offline Squat Pipeline

Usage:
  dart run bin/aiwa_cli.dart --keypoints <kp.json> --rule <rule.json> [options]
  dart run bin/aiwa_cli.dart --video <video.mp4> --rule <rule.json> [engine options]

Examples:
  # File mode (existing keypoints JSON)
  dart run bin/aiwa_cli.dart \
    --keypoints ../aiwa_core/test/fixtures/kp_sample.json \
    --rule ../aiwa_core/test/fixtures/squat.v1.json \
    --out build/offline_out

  # Engine mode（视频→ML Kit）请使用 Flutter 工程 aiwa_app

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

  NeutralKeypointSeries? neutralSeries;
  late final PoseSeries poseSeries;
  if ((kpRoot['version'] as Object?) == 'vB1.1') {
    neutralSeries = parseNeutralKeypointSeriesFromMap(kpRoot);
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
  final logsDir = Directory(path.join(outDir.path, 'logs'))
    ..createSync(recursive: true);

  final logLines = <String>[];
  void log(String level, String message) {
    final line = '[${DateTime.now().toIso8601String()}][$level] $message';
    logLines.add(line);
    if (level == 'ERROR') {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }

  log('INFO', 'File mode start → keypoints=$keypointsPath');

  final hybridEnabled = opts['hybrid'] == true;
  final hybridPolicyPath =
      (opts['hybrid-policy'] as String?) ?? 'configs/hybrid_policy.json';
  final cloudMockPath = opts['cloud-mock'] as String?;
  final exportCloudFragment = opts['cloud-video-fragment'] == true;
  final evidenceEnabled = opts['evidence'] == true;
  final evidenceConfigPath =
      (opts['evidence-config'] as String?) ?? 'configs/evidence_config.json';
  final overlayRequested = opts['overlay'] == true;

  final resultJson = Map<String, dynamic>.from(out.resultJson);
  final reps = (resultJson['reps'] as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
      .toList(growable: true);
  resultJson['reps'] = reps;
  final existingEvidence = (resultJson['evidence'] as List<dynamic>? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
      .toList(growable: true);
  resultJson['evidence'] = existingEvidence;

  final anglesFile = File(path.join(outDir.path, 'angles.csv'));
  try {
    await anglesFile.writeAsString(out.anglesCsv);
  } on IOException catch (e) {
    throw _CliException('Failed to write angles.csv: $e', _exitOutputError);
  }

  final hybridOutcome = await _processHybrid(
    enabled: hybridEnabled,
    policyPath: hybridPolicyPath,
    cloudMockPath: cloudMockPath,
    exportCloudFragment: exportCloudFragment,
    logsDir: logsDir,
    resultJson: resultJson,
    perfData: null,
    neutralSeries: neutralSeries,
    baseName: baseName,
    log: log,
  );

  final evidenceOutcome = await _processEvidence(
    enabled: evidenceEnabled,
    configPath: evidenceConfigPath,
    outDir: outDir,
    logsDir: logsDir,
    resultJson: resultJson,
    overlayRequested: overlayRequested,
    log: log,
  );

  _validateHybridArtifacts(
    logsDir: logsDir,
    outcome: hybridOutcome,
    log: log,
  );
  _validateEvidenceArtifacts(
    outDir: outDir,
    logsDir: logsDir,
    resultJson: resultJson,
    outcome: evidenceOutcome,
    log: log,
  );

  final resultFile = File(path.join(outDir.path, 'result.json'));
  try {
    await resultFile.writeAsString(jsonPretty(resultJson));
  } on IOException catch (e) {
    throw _CliException('Failed to write result.json: $e', _exitOutputError);
  }

  final runLogFile = File(path.join(logsDir.path, 'run.log'));
  await runLogFile.writeAsString(logLines.join('\n'));

  log('DONE', 'Outputs written:');
  log('DONE', '  - ${anglesFile.path}');
  log('DONE', '  - ${resultFile.path}');
  log('DONE', '  - ${runLogFile.path}');

  final summary = _buildHybridSummary(hybridOutcome, evidenceOutcome);
  if (summary != null) {
    log('INFO', summary);
  }
}

Future<void> _runEngineMode(
  ArgResults opts,
  RuleSet ruleSet,
  Strictness strictness,
) async {
  throw _CliException(
    'Engine mode (--video) is only available in the Flutter build. '
    'This standalone CLI package supports --keypoints file mode only.',
    _exitEngineInitError,
  );
}

class _HybridOutcome {
  final bool enabled;
  final bool triggered;
  final List<String> reasons;
  final bool hadCloudMock;
  final bool cloudEnhanced;
  final int? countLocal;
  final int? countCloud;
  final int? countFinal;
  final String? mergeStrategy;
  final String? reconcileNote;
  final String? policyVersion;

  const _HybridOutcome({
    required this.enabled,
    required this.triggered,
    required this.reasons,
    required this.hadCloudMock,
    required this.cloudEnhanced,
    this.countLocal,
    this.countCloud,
    this.countFinal,
    this.mergeStrategy,
    this.reconcileNote,
    this.policyVersion,
  });
}

class _EvidenceOutcome {
  final bool enabled;
  final int topK;
  final int generatedCount;
  final int keptCount;
  final int droppedCount;
  final bool overlayGenerated;

  const _EvidenceOutcome({
    required this.enabled,
    required this.topK,
    required this.generatedCount,
    required this.keptCount,
    required this.droppedCount,
    required this.overlayGenerated,
  });
}

class _CloudMergeOutcome {
  final bool cloudEnhanced;
  final int countLocal;
  final int? countCloud;
  final int countFinal;
  final String mergeStrategy;
  final String? reconcileNote;
  final Map<String, String> sourceOfTruth;
  final Map<String, dynamic> diffLog;
  final List<Map<String, dynamic>> evidenceAdditions;

  const _CloudMergeOutcome({
    required this.cloudEnhanced,
    required this.countLocal,
    required this.countCloud,
    required this.countFinal,
    required this.mergeStrategy,
    required this.reconcileNote,
    required this.sourceOfTruth,
    required this.diffLog,
    required this.evidenceAdditions,
  });
}

class _HybridRuleEvaluation {
  final bool triggered;
  final List<String> reasons;

  const _HybridRuleEvaluation({
    required this.triggered,
    required this.reasons,
  });
}

double _roundDouble(double value, int fractionDigits) =>
    double.parse(value.toStringAsFixed(fractionDigits));

String? _buildHybridSummary(
  _HybridOutcome hybrid,
  _EvidenceOutcome evidence,
) {
  final parts = <String>[];
  if (hybrid.enabled || hybrid.hadCloudMock) {
    final status = hybrid.enabled
        ? 'HYBRID ${hybrid.triggered ? 'on' : 'off'}'
        : 'HYBRID off';
    parts.add(status);
    if (hybrid.triggered && hybrid.reasons.isNotEmpty) {
      parts.add('reasons=[${hybrid.reasons.join(',')}]');
    }
    if (hybrid.hadCloudMock) {
      parts.add(hybrid.cloudEnhanced ? 'cloudEnhanced' : 'cloudStatic');
      final local = hybrid.countLocal != null ? hybrid.countLocal.toString() : '-';
      final cloud = hybrid.countCloud != null ? hybrid.countCloud.toString() : '-';
      final finalCount = hybrid.countFinal != null ? hybrid.countFinal.toString() : '-';
      parts.add('finalCount=$finalCount (local=$local, cloud=$cloud)');
      if (hybrid.mergeStrategy != null) {
        parts.add('merge=${hybrid.mergeStrategy}');
      }
      if (hybrid.reconcileNote != null && hybrid.reconcileNote!.isNotEmpty) {
        parts.add('note=${hybrid.reconcileNote}');
      }
    }
  }
  if (evidence.enabled) {
    parts.add(
        'evidence=topK${evidence.topK} generated=${evidence.generatedCount} kept=${evidence.keptCount} dropped=${evidence.droppedCount}');
    parts.add('overlay=${evidence.overlayGenerated ? 'on' : 'off'}');
  }
  if (parts.isEmpty) {
    return null;
  }
  return parts.join(' | ');
}

void _validateHybridArtifacts({
  required Directory logsDir,
  required _HybridOutcome outcome,
  required _LogFn log,
}) {
  if (!outcome.enabled && !outcome.hadCloudMock) {
    return;
  }
  if (outcome.enabled && outcome.triggered) {
    final triggerFile = File(path.join(logsDir.path, 'hybrid_trigger.json'));
    if (!triggerFile.existsSync()) {
      log('WARN', 'Hybrid triggered but logs/hybrid_trigger.json is missing.');
    }
    final payloadFile = File(path.join(logsDir.path, 'cloud_payload.json'));
    if (!payloadFile.existsSync()) {
      log('WARN', 'Hybrid triggered but logs/cloud_payload.json is missing.');
    }
    final auditFile = File(path.join(logsDir.path, 'payload_audit.json'));
    if (!auditFile.existsSync()) {
      log('WARN', 'Hybrid triggered but logs/payload_audit.json is missing.');
    }
    if (outcome.hadCloudMock) {
      final diffFile = File(path.join(logsDir.path, 'hybrid_diff.json'));
      if (!diffFile.existsSync()) {
        log('WARN', 'Hybrid triggered with cloud mock but logs/hybrid_diff.json is missing.');
      }
    }
  } else if (outcome.hadCloudMock) {
    final diffFile = File(path.join(logsDir.path, 'hybrid_diff.json'));
    if (!diffFile.existsSync()) {
      log('WARN', 'Cloud mock provided but logs/hybrid_diff.json was not written.');
    }
  }
}

void _validateEvidenceArtifacts({
  required Directory outDir,
  required Directory logsDir,
  required Map<String, dynamic> resultJson,
  required _EvidenceOutcome outcome,
  required _LogFn log,
}) {
  if (!outcome.enabled) {
    return;
  }
  final evidenceFile = File(path.join(outDir.path, 'evidence.json'));
  if (!evidenceFile.existsSync()) {
    log('WARN', 'Evidence enabled but evidence.json is missing.');
  }
  final perfFile = File(path.join(logsDir.path, 'perf.json.evidence'));
  if (!perfFile.existsSync()) {
    log('WARN', 'Evidence enabled but logs/perf.json.evidence is missing.');
  }
  final evidenceItems = (resultJson['evidence'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final invalidCount =
      evidenceItems.where((item) => !_isEvidenceStructurallyValid(item)).length;
  if (invalidCount > 0) {
    log('WARN', 'Evidence validation found $invalidCount invalid items in result.json.');
  }
  if (outcome.overlayGenerated) {
    final overlayFile = File(path.join(outDir.path, 'overlay.mp4'));
    if (!overlayFile.existsSync()) {
      log('WARN', 'Evidence overlay flagged as generated but overlay.mp4 is missing.');
    }
    final missingSnapshots = evidenceItems
        .where((item) => (item['snapshotPath'] as String?)?.isNotEmpty != true)
        .length;
    if (missingSnapshots > 0) {
      log('WARN',
          'Evidence overlay generated but $missingSnapshots items are missing snapshotPath.');
    }
  }
}

double? _flexibleToDouble(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is bool) {
    return value ? 1.0 : 0.0;
  }
  if (value is String) {
    final parsed = double.tryParse(value.trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

double _resolveResultFps(Map<String, dynamic> resultJson) {
  final meta = resultJson['meta'] as Map<String, dynamic>?;
  final fps = _flexibleToDouble(meta?['fps']) ?? _flexibleToDouble(resultJson['fps']);
  if (fps != null && fps > 0) {
    return fps;
  }
  return _defaultFps;
}

int? _normalizeTimestamp(int? timestampMs, int? frameIndex, double fps) {
  if (timestampMs != null) {
    return timestampMs;
  }
  if (frameIndex != null && fps > 0) {
    return ((frameIndex / fps) * 1000).round();
  }
  return null;
}

int _normalizeFrameIndex(int? frameIndex, int timestampMs, double fps) {
  if (frameIndex != null) {
    return frameIndex;
  }
  if (fps > 0) {
    return ((timestampMs / 1000) * fps).round();
  }
  return 0;
}

List<String> _dedupeCues(Iterable<String> cues) {
  final seen = <String>{};
  final result = <String>[];
  for (final cue in cues) {
    if (seen.add(cue)) {
      result.add(cue);
    }
  }
  return result;
}

List<String> _buildPositiveCues(
  Map<String, dynamic>? rep,
  Map<String, dynamic> thresholds,
) {
  final cues = <String>[];
  final depth = (rep?['kneeValleyAngle'] as num?)?.toDouble();
  final depthThreshold = (thresholds['depth_minHipAngle'] as num?)?.toDouble();
  if (depth != null && depthThreshold != null && depth <= depthThreshold + 1e-6) {
    cues.add('depth_ok');
  }
  final tempo = rep?['tempo'] as Map<String, dynamic>?;
  final ratio = (tempo?['ratio'] as num?)?.toDouble();
  if (ratio != null && ratio >= 0.8 && ratio <= 1.2) {
    cues.add('tempo_ok');
  }
  final startMs = (rep?['startMs'] as num?)?.toInt();
  final endMs = (rep?['endMs'] as num?)?.toInt();
  final valleyMs = (rep?['valleyMs'] as num?)?.toInt();
  if (startMs != null && endMs != null && valleyMs != null) {
    cues.add('phase_boundary');
  }
  cues.add('good_form');
  return _dedupeCues(cues);
}

Map<String, dynamic> _mergeAngles(dynamic existingAngles, Map<String, dynamic>? rep) {
  final angles = <String, dynamic>{};
  if (existingAngles is Map<String, dynamic>) {
    for (final entry in existingAngles.entries) {
      final parsed = _flexibleToDouble(entry.value);
      if (parsed != null) {
        angles[entry.key] = _roundDouble(parsed, 2);
      }
    }
  }
  if (rep != null) {
    void addAngle(String key, dynamic value) {
      if (angles.containsKey(key)) {
        return;
      }
      final parsed = _flexibleToDouble(value);
      if (parsed != null) {
        angles[key] = _roundDouble(parsed, 2);
      }
    }

    addAngle('kneeValleyAngle', rep['kneeValleyAngle']);
    addAngle('minKneeOutAngle', rep['minKneeOutAngle']);
    addAngle('maxForwardLean', rep['maxForwardLean']);
  }
  if (angles.isEmpty) {
    final fallback = _flexibleToDouble(rep?['kneeValleyAngle']) ?? 0.0;
    angles['kneeValleyAngle'] = _roundDouble(fallback, 2);
  }
  return angles;
}

String? _thresholdKeyForAngle(String angleKey) {
  switch (angleKey) {
    case 'kneeValleyAngle':
      return 'depth_minHipAngle';
    case 'minKneeOutAngle':
      return 'leftKnee_maxValgus';
  }
  return null;
}

Map<String, dynamic> _thresholdsForAngles(
  Map<String, dynamic> configThresholds,
  Iterable<String> angleKeys,
) {
  final thresholds = <String, dynamic>{};
  for (final angle in angleKeys) {
    final key = _thresholdKeyForAngle(angle);
    if (key != null) {
      final value = configThresholds[key];
      final parsed = _flexibleToDouble(value);
      if (parsed != null) {
        thresholds[key] = _roundDouble(parsed, 2);
      }
    }
  }
  if (thresholds.isEmpty && configThresholds.isNotEmpty) {
    for (final entry in configThresholds.entries) {
      final parsed = _flexibleToDouble(entry.value);
      if (parsed != null) {
        thresholds[entry.key] = _roundDouble(parsed, 2);
        break;
      }
    }
  }
  if (thresholds.isEmpty) {
    thresholds['depth_minHipAngle'] = 0;
  }
  return thresholds;
}

bool _isEvidenceStructurallyValid(Map<String, dynamic> item) {
  final type = item['type'];
  if (type != 'segment' && type != 'frame') {
    return false;
  }
  final timestamp = item['timestampMs'];
  if (timestamp is! num) {
    return false;
  }
  final cues = item['cues'];
  if (cues is! List || cues.isEmpty) {
    return false;
  }
  final snapshot = item['snapshotPath'];
  if (snapshot is! String) {
    return false;
  }
  final angles = item['angles'];
  if (angles is! Map || angles.isEmpty) {
    return false;
  }
  final thresholds = item['thresholds'];
  if (thresholds is! Map) {
    return false;
  }
  return true;
}

bool _hasBasicEvidenceShape(Map<String, dynamic> item) {
  final type = item['type'];
  if (type != 'segment' && type != 'frame') {
    return false;
  }
  final timestamp = item['timestampMs'];
  if (timestamp is! num) {
    return false;
  }
  final cues = item['cues'];
  if (cues is! List || cues.isEmpty) {
    return false;
  }
  return true;
}

int _removeInvalidEvidenceEntries(List<Map<String, dynamic>> items,
    {bool strict = true}) {
  var removed = 0;
  items.removeWhere((item) {
    final valid = strict
        ? _isEvidenceStructurallyValid(item)
        : _hasBasicEvidenceShape(item);
    if (!valid) {
      removed++;
      return true;
    }
    return false;
  });
  return removed;
}

Map<String, dynamic>? _ensureSegmentEvidence(
  Map<String, dynamic> source, {
  required Map<String, dynamic>? rep,
  required Map<String, dynamic> thresholds,
  required double fallbackFps,
  required int windowMs,
}) {
  final type = (source['type'] as String?) ?? 'segment';
  if (type != 'segment' && type != 'frame') {
    return null;
  }
  final normalized = Map<String, dynamic>.from(source);
  normalized['type'] = type;

  final frameIndex = (normalized['frameIndex'] as num?)?.toInt();
  final timestamp = _normalizeTimestamp(
      (normalized['timestampMs'] as num?)?.toInt(), frameIndex, fallbackFps);
  if (timestamp == null) {
    return null;
  }
  normalized['timestampMs'] = timestamp;
  normalized['frameIndex'] = _normalizeFrameIndex(frameIndex, timestamp, fallbackFps);

  final resolvedRepIndex =
      (normalized['repIndex'] as num?)?.toInt() ?? (rep?['index'] as num?)?.toInt();
  if (resolvedRepIndex != null) {
    normalized['repIndex'] = resolvedRepIndex;
  }

  final rawCues = normalized['cues'];
  final cueBuffer = <String>[];
  if (rawCues is List) {
    for (final cue in rawCues) {
      if (cue is String && cue.trim().isNotEmpty) {
        cueBuffer.add(cue.trim());
      }
    }
  }
  if (!cueBuffer.any((cue) => !cue.startsWith('issue:'))) {
    cueBuffer.addAll(_buildPositiveCues(rep, thresholds));
  }
  normalized['cues'] = _dedupeCues(cueBuffer);

  final mergedAngles = _mergeAngles(normalized['angles'], rep);
  normalized['angles'] = mergedAngles;
  normalized['thresholds'] =
      _thresholdsForAngles(thresholds, mergedAngles.keys);

  final snapshot = normalized['snapshotPath'];
  normalized['snapshotPath'] = snapshot is String ? snapshot : '';

  final window = normalized['window'] as Map<String, dynamic>?;
  final startMs = (window?['startMs'] as num?)?.toInt() ??
      math.max(0, timestamp - windowMs ~/ 2);
  final endMs = (window?['endMs'] as num?)?.toInt() ?? timestamp + windowMs ~/ 2;
  normalized['window'] = {'startMs': startMs, 'endMs': endMs};

  return normalized;
}

Map<String, double> _buildHybridMetrics(
  Map<String, dynamic> resultJson,
  Map<String, dynamic>? perfData,
  NeutralKeypointSeries? neutralSeries,
) {
  final quality = resultJson['quality'] as Map<String, dynamic>?;
  final meta = resultJson['meta'] as Map<String, dynamic>?;

  final coverage = _flexibleToDouble(perfData?['usableFrameRatio']) ??
      _flexibleToDouble(quality?['coverage']) ??
      0.0;
  final lowConf = _flexibleToDouble(perfData?['lowConfidenceRatio']) ??
      _flexibleToDouble(quality?['lowConfidence']) ??
      0.0;
  final fps = neutralSeries?.sampling.effectiveFps ??
      _flexibleToDouble(meta?['fps']) ??
      0.0;
  final jitter = _flexibleToDouble(perfData?['jitterPx']) ?? 0.0;

  return {
    'coverage': _roundDouble(coverage, 4),
    'lowConfPct': _roundDouble(lowConf, 4),
    'fps': _roundDouble(fps, 2),
    'jitterPx': _roundDouble(jitter, 2),
  };
}

Map<String, double> _extractPolicyThresholds(
  Map<String, dynamic> policy,
  Map<String, dynamic> resultJson,
) {
  final thresholds = <String, double>{};
  final global = policy['global'] as Map<String, dynamic>? ?? {};
  for (final entry in global.entries) {
    final value = entry.value;
    if (value is num) {
      thresholds[entry.key] = value.toDouble();
    }
  }

  final byEngine = policy['byEngine'] as Map<String, dynamic>?;
  if (byEngine != null) {
    final engineName =
        (resultJson['engine'] ?? (resultJson['meta'] as Map<String, dynamic>? ?? {})['engine'])
            as String?;
    final engineVersion = (resultJson['engineVersion'] ??
            (resultJson['meta'] as Map<String, dynamic>? ?? {})['engineVersion'])
        as String?;
    if (engineName != null && engineVersion != null) {
      final versionDigits = engineVersion.replaceAll(RegExp(r'[^0-9]'), '');
      final candidates = <String>[
        if (versionDigits.isNotEmpty) '${engineName}_$versionDigits',
        '${engineName}_$engineVersion',
        engineName,
      ];
      for (final candidate in candidates) {
        final override = byEngine[candidate];
        if (override is Map<String, dynamic>) {
          for (final entry in override.entries) {
            final value = entry.value;
            if (value is num) {
              thresholds[entry.key] = value.toDouble();
            }
          }
          break;
        }
      }
    }
  }

  return thresholds;
}

bool _compareHybridMetric(double metric, double threshold, String op) {
  switch (op) {
    case '<':
      return metric < threshold;
    case '<=':
      return metric <= threshold;
    case '>':
      return metric > threshold;
    case '>=':
      return metric >= threshold;
    case '==':
      return (metric - threshold).abs() <= 1e-6;
    case '!=':
      return (metric - threshold).abs() > 1e-6;
    default:
      return false;
  }
}

_HybridRuleEvaluation _evaluateHybridRules(
  Map<String, dynamic> policy,
  Map<String, double> metrics,
  Map<String, double> thresholds,
) {
  final rules = (policy['triggerRules'] as List<dynamic>? ?? [])
      .whereType<String>()
      .toList(growable: false);
  final fireAny = policy['fireIfAnyRuleTrue'] == true;
  final reasons = <String>[];

  for (final rule in rules) {
    final tokens = rule.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (tokens.length != 3) {
      continue;
    }
    final metricKey = tokens[0];
    final op = tokens[1];
    final thresholdKey = tokens[2];
    final metricValue = metrics[metricKey];
    final thresholdValue = thresholds[thresholdKey];
    if (metricValue == null || thresholdValue == null) {
      continue;
    }
    if (_compareHybridMetric(metricValue, thresholdValue, op)) {
      reasons.add(
          '$metricKey$op$thresholdKey(${_roundDouble(metricValue, 3)} vs ${_roundDouble(thresholdValue, 3)})');
    }
  }

  final triggered = fireAny
      ? reasons.isNotEmpty
      : (rules.isNotEmpty && reasons.length == rules.length);

  return _HybridRuleEvaluation(triggered: triggered, reasons: reasons);
}

Map<String, dynamic>? _computeHybridSlice(
  Map<String, dynamic> resultJson,
  Map<String, dynamic> policy,
) {
  final reps = (resultJson['reps'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  if (reps.isEmpty) {
    return null;
  }
  Map<String, dynamic> candidate = reps.first;
  var bestScore = -double.infinity;
  for (final rep in reps) {
    final depth = (rep['kneeValleyAngle'] as num?)?.toDouble();
    if (depth != null && depth > bestScore) {
      bestScore = depth;
      candidate = rep;
    }
  }
  final center = (candidate['valleyMs'] as num?)?.toInt() ?? _repCenter(candidate);
  final before = (policy['sliceMsBefore'] as num?)?.toInt() ?? 0;
  final after = (policy['sliceMsAfter'] as num?)?.toInt() ?? 0;
  final start = math.max(0, center - before);
  final end = center + after;
  return {
    'repIndex': (candidate['index'] as num?)?.toInt(),
    'anchorMs': center,
    'startMs': start,
    'endMs': end,
  };
}

({
  Map<String, dynamic> payload,
  int framesIncluded,
  int lowConfidenceFrames,
  int sliceStart,
  int sliceEnd,
}) _buildCloudPayload({
  required Map<String, dynamic> policy,
  required NeutralKeypointSeries neutralSeries,
  required Map<String, dynamic>? slice,
  required String baseName,
  required bool exportCloudFragment,
}) {
  final privacy = policy['privacy'] as String? ?? 'keypoints_only';
  final startMs = (slice?['startMs'] as num?)?.toInt() ?? 0;
  final endMs = (slice?['endMs'] as num?)?.toInt() ?? neutralSeries.video.durationMs;
  final points = <Map<String, dynamic>>[];
  var framesIncluded = 0;
  var lowConfidenceFrames = 0;

  for (final frame in neutralSeries.frames) {
    if (frame.timestampMs < startMs || frame.timestampMs > endMs) {
      continue;
    }
    framesIncluded++;
    if (frame.lowConfidence) {
      lowConfidenceFrames++;
    }
    final relativeT = frame.timestampMs - startMs;
    for (final kp in frame.keypoints) {
      final id = _neutralNameToIndex[kp.name];
      if (id == null) {
        continue;
      }
      final point = <String, dynamic>{
        't': relativeT,
        'id': id,
        'x': _roundDouble(kp.x, 5),
        'y': _roundDouble(kp.y, 5),
        'conf': _roundDouble(kp.score, 4),
      };
      if (kp.z != null) {
        point['z'] = _roundDouble(kp.z!, 5);
      }
      points.add(point);
    }
  }

  final payload = <String, dynamic>{
    'version': policy['version'] ?? 'C1',
    'videoId':
        neutralSeries.video.basename.isNotEmpty ? neutralSeries.video.basename : baseName,
    'engine': '${neutralSeries.engine.name}_${neutralSeries.engine.model}',
    'device': {
      'platform': Platform.operatingSystem,
      'os': Platform.operatingSystemVersion,
    },
    'slice': {'startMs': startMs, 'endMs': endMs},
    'privacy': privacy,
    'keypoints': {
      'fps': _roundDouble(neutralSeries.effectiveFps, 2),
      'points': points,
    },
    'optional': {
      if (exportCloudFragment) 'video': 'pending',
    },
  };

  return (
    payload: payload,
    framesIncluded: framesIncluded,
    lowConfidenceFrames: lowConfidenceFrames,
    sliceStart: startMs,
    sliceEnd: endMs,
  );
}

Map<String, dynamic> _buildPayloadAudit({
  required ({
    Map<String, dynamic> payload,
    int framesIncluded,
    int lowConfidenceFrames,
    int sliceStart,
    int sliceEnd,
  }) artifacts,
  required bool exportCloudFragment,
}) {
  final payload = artifacts.payload;
  final approxBytes = utf8.encode(_prettyJsonEncoder.convert(payload)).length;
  final points =
      (payload['keypoints'] as Map<String, dynamic>)['points'] as List<dynamic>;
  return {
    'framesIncluded': artifacts.framesIncluded,
    'lowConfidenceFrames': artifacts.lowConfidenceFrames,
    'slice': {'startMs': artifacts.sliceStart, 'endMs': artifacts.sliceEnd},
    'pointCount': points.length,
    'approxPayloadBytes': approxBytes,
    'privacy': payload['privacy'],
    'videoFragment': {
      'requested': exportCloudFragment,
      'generated': false,
      if (exportCloudFragment) 'reason': 'not_implemented',
    },
    'timestamp': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic>? _matchCloudToLocal(
  List<Map<String, dynamic>> localReps,
  Map<String, dynamic> cloudRep,
  Set<int> used,
  int toleranceMs,
) {
  final idx = (cloudRep['idx'] as num?)?.toInt();
  if (idx != null) {
    for (final rep in localReps) {
      final repIdx = (rep['index'] as num?)?.toInt();
      if (repIdx == idx) {
        used.add(idx);
        return rep;
      }
    }
  }

  final cloudCenter = _repCenter(cloudRep);
  Map<String, dynamic>? best;
  var bestDiff = toleranceMs + 1;
  for (final rep in localReps) {
    final repIdx = (rep['index'] as num?)?.toInt();
    if (repIdx != null && used.contains(repIdx)) {
      continue;
    }
    final diff = (_repCenter(rep) - cloudCenter).abs();
    if (diff <= toleranceMs && diff < bestDiff) {
      best = rep;
      bestDiff = diff;
    }
  }
  if (best != null) {
    final repIdx = (best['index'] as num?)?.toInt();
    if (repIdx != null) {
      used.add(repIdx);
    }
  }
  return best;
}

int _repCenter(Map<String, dynamic> rep) {
  final valley = (rep['valleyMs'] as num?)?.toInt();
  if (valley != null) {
    return valley;
  }
  final start = (rep['startMs'] as num?)?.toInt() ?? 0;
  final end = (rep['endMs'] as num?)?.toInt() ?? start;
  return start + ((end - start) ~/ 2);
}

Future<_CloudMergeOutcome?> _mergeCloudMock({
  required String cloudMockPath,
  required Map<String, dynamic> resultJson,
  required Directory logsDir,
  required _LogFn log,
}) async {
  final mockStr = await _readFile(cloudMockPath, 'cloud mock');
  final decoded = jsonDecode(mockStr);
  if (decoded is! Map<String, dynamic>) {
    log('WARN', 'Cloud mock "$cloudMockPath" is not an object. Skipping merge.');
    return null;
  }

  final cloudCounts = (decoded['counts'] as num?)?.toInt();
  final cloudReps = (decoded['reps'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
  final notes = decoded['notes'];

  final toleranceMs = 200;
  final localReps = (resultJson['reps'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final used = <int>{};
  final matches = <Map<String, dynamic>>[];
  final unmatchedCloud = <Map<String, dynamic>>[];
  var boundariesAdopted = 0;
  var matchedCount = 0;
  final evidenceAdditions = <Map<String, dynamic>>[];

  for (final cloudRep in cloudReps) {
    final matched = _matchCloudToLocal(localReps, cloudRep, used, toleranceMs);
    if (matched == null) {
      unmatchedCloud.add(cloudRep);
      continue;
    }
    matchedCount++;
    final localStart = (matched['startMs'] as num?)?.toInt();
    final localEnd = (matched['endMs'] as num?)?.toInt();
    final cloudStart = (cloudRep['startMs'] as num?)?.toInt();
    final cloudEnd = (cloudRep['endMs'] as num?)?.toInt();
    final entry = <String, dynamic>{
      'index': (matched['index'] as num?)?.toInt() ?? (cloudRep['idx'] as num?)?.toInt(),
      'local': {'startMs': localStart, 'endMs': localEnd},
      'cloud': {'startMs': cloudStart, 'endMs': cloudEnd},
    };
    if (localStart != null && cloudStart != null) {
      entry['deltaStart'] = cloudStart - localStart;
    }
    if (localEnd != null && cloudEnd != null) {
      entry['deltaEnd'] = cloudEnd - localEnd;
    }

    final adoptStart = localStart != null &&
        cloudStart != null &&
        (cloudStart - localStart).abs() <= toleranceMs;
    final adoptEnd = localEnd != null &&
        cloudEnd != null &&
        (cloudEnd - localEnd).abs() <= toleranceMs;
    if (adoptStart) {
      matched['startMs'] = cloudStart;
    }
    if (adoptEnd) {
      matched['endMs'] = cloudEnd;
    }
    if (adoptStart || adoptEnd) {
      boundariesAdopted++;
    }

    final quality = cloudRep['quality'];
    if (quality is Map<String, dynamic> && quality.isNotEmpty) {
      final cues = quality.entries
          .map((e) => 'cloud:${e.key}:${e.value}')
          .toList(growable: false);
      if (cues.isNotEmpty) {
        evidenceAdditions.add({
          'type': 'segment',
          'timestampMs': _repCenter(matched),
          'repIndex': (matched['index'] as num?)?.toInt(),
          'frameIndex': (matched['index'] as num?)?.toInt(),
          'cues': cues,
          'snapshotPath': '',
        });
      }
    }

    matches.add(entry);
  }

  final unmatchedLocal = localReps
      .where((rep) {
        final idx = (rep['index'] as num?)?.toInt();
        return idx != null && !used.contains(idx);
      })
      .map((rep) => {'index': rep['index'], 'valleyMs': rep['valleyMs']})
      .toList(growable: false);

  final countLocal = localReps.length;
  var finalCount = countLocal;
  var mergeStrategy = 'localOnly';
  String? reconcileNote;
  var cloudEnhanced = matches.isNotEmpty;

  if (cloudCounts != null) {
    if ((cloudCounts - countLocal).abs() <= 1) {
      finalCount = cloudCounts;
      mergeStrategy = 'countWithinOne';
    } else {
      mergeStrategy = 'countConflictFallbackLocal';
      reconcileNote =
          'Cloud count differs by ${cloudCounts - countLocal}; keeping local.';
    }
  }

  if (finalCount != countLocal) {
    resultJson['repCount'] = finalCount;
    if (reconcileNote == null && cloudCounts != null) {
      reconcileNote =
          'Cloud count adopted (${cloudCounts}) while local detected $countLocal.';
    }
    cloudEnhanced = true;
  } else {
    resultJson['repCount'] = countLocal;
  }

  cloudEnhanced = cloudEnhanced || boundariesAdopted > 0 || evidenceAdditions.isNotEmpty;

  final sourceOfTruth = <String, String>{
    'counts':
        (cloudCounts != null && finalCount == cloudCounts) ? 'cloud' : 'local',
    'phaseBoundaries': matchedCount == 0
        ? 'local'
        : (boundariesAdopted == matchedCount
            ? 'cloud'
            : (boundariesAdopted > 0 ? 'mixed' : 'local')),
    'score': 'local',
  };

  final diffLog = <String, dynamic>{
    'toleranceMs': toleranceMs,
    'counts': {
      'local': countLocal,
      if (cloudCounts != null) 'cloud': cloudCounts,
      'final': finalCount,
    },
    'matched': matches,
    if (unmatchedCloud.isNotEmpty) 'unmatchedCloud': unmatchedCloud,
    if (unmatchedLocal.isNotEmpty) 'unmatchedLocal': unmatchedLocal,
    if (notes != null) 'notes': notes,
  };

  return _CloudMergeOutcome(
    cloudEnhanced: cloudEnhanced,
    countLocal: countLocal,
    countCloud: cloudCounts,
    countFinal: finalCount,
    mergeStrategy: mergeStrategy,
    reconcileNote: reconcileNote,
    sourceOfTruth: sourceOfTruth,
    diffLog: diffLog,
    evidenceAdditions: evidenceAdditions,
  );
}

Future<_HybridOutcome> _processHybrid({
  required bool enabled,
  required String policyPath,
  required String? cloudMockPath,
  required bool exportCloudFragment,
  required Directory logsDir,
  required Map<String, dynamic> resultJson,
  required Map<String, dynamic>? perfData,
  required NeutralKeypointSeries? neutralSeries,
  required String baseName,
  required _LogFn log,
}) async {
  if (!enabled) {
    return const _HybridOutcome(
      enabled: false,
      triggered: false,
      reasons: <String>[],
      hadCloudMock: false,
      cloudEnhanced: false,
    );
  }

  final metrics = _buildHybridMetrics(resultJson, perfData, neutralSeries);
  final hadCloudMock = cloudMockPath != null;

  var triggered = false;
  var reasons = <String>[];
  Map<String, dynamic>? slice;
  String? policyVersion;
  Map<String, double> thresholds = const {};

  final policyStr = await _readFile(policyPath, 'hybrid policy');
  final decoded = jsonDecode(policyStr);
  if (decoded is! Map<String, dynamic>) {
    throw _CliException(
      'Hybrid policy must be a JSON object.',
      _exitParamError,
    );
  }
  policyVersion = decoded['version'] as String?;
  thresholds = _extractPolicyThresholds(decoded, resultJson);
  final evaluation = _evaluateHybridRules(decoded, metrics, thresholds);
  triggered = evaluation.triggered;
  reasons = evaluation.reasons;
  slice = _computeHybridSlice(resultJson, decoded);

  final triggerPayload = <String, dynamic>{
    if (policyVersion != null) 'version': policyVersion,
    'triggered': triggered,
    'metrics': metrics,
    'reasons': reasons,
    if (slice != null) 'slice': slice,
    if (thresholds.isNotEmpty) 'thresholds': thresholds,
  };
  final triggerFile = File(path.join(logsDir.path, 'hybrid_trigger.json'));
  await triggerFile.writeAsString(_prettyJsonEncoder.convert(triggerPayload));

  if (triggered) {
    if (neutralSeries != null) {
      final payloadArtifacts = _buildCloudPayload(
        policy: decoded,
        neutralSeries: neutralSeries,
        slice: slice,
        baseName: baseName,
        exportCloudFragment: exportCloudFragment,
      );
      final payloadFile = File(path.join(logsDir.path, 'cloud_payload.json'));
      await payloadFile
          .writeAsString(_prettyJsonEncoder.convert(payloadArtifacts.payload));

      final audit = _buildPayloadAudit(
        artifacts: payloadArtifacts,
        exportCloudFragment: exportCloudFragment,
      );
      final auditFile = File(path.join(logsDir.path, 'payload_audit.json'));
      await auditFile.writeAsString(_prettyJsonEncoder.convert(audit));
    } else {
      log('WARN', 'Hybrid triggered but neutral keypoints unavailable; skipping payload export.');
    }
  }

  _CloudMergeOutcome? cloudOutcome;
  if (cloudMockPath != null) {
    cloudOutcome = await _mergeCloudMock(
      cloudMockPath: cloudMockPath,
      resultJson: resultJson,
      logsDir: logsDir,
      log: log,
    );
    if (cloudOutcome != null) {
      final diffFile = File(path.join(logsDir.path, 'hybrid_diff.json'));
      await diffFile.writeAsString(_prettyJsonEncoder.convert(cloudOutcome.diffLog));
      final evidenceList =
          (resultJson['evidence'] as List<dynamic>).cast<Map<String, dynamic>>();
      evidenceList.addAll(cloudOutcome.evidenceAdditions);
    }
  }

  final hybridSummary = <String, dynamic>{
    'triggered': triggered,
    'metrics': metrics,
    'reasons': reasons,
    if (slice != null) 'slice': slice,
    if (policyVersion != null) 'policyVersion': policyVersion,
    'cloudEnhanced': cloudOutcome?.cloudEnhanced ?? false,
    if (cloudOutcome != null) 'mergeStrategy': cloudOutcome.mergeStrategy,
    if (cloudOutcome != null)
      'delta': {
        'countLocal': cloudOutcome.countLocal,
        'countCloud': cloudOutcome.countCloud,
        'countFinal': cloudOutcome.countFinal,
      },
    if (cloudOutcome != null) 'sourceOfTruth': cloudOutcome.sourceOfTruth,
    if (cloudOutcome?.reconcileNote != null)
      'reconcileNote': cloudOutcome!.reconcileNote,
  };
  resultJson['hybrid'] = hybridSummary;

  return _HybridOutcome(
    enabled: enabled,
    triggered: triggered,
    reasons: reasons,
    hadCloudMock: hadCloudMock,
    cloudEnhanced: cloudOutcome?.cloudEnhanced ?? false,
    countLocal: cloudOutcome?.countLocal,
    countCloud: cloudOutcome?.countCloud,
    countFinal: cloudOutcome?.countFinal,
    mergeStrategy: cloudOutcome?.mergeStrategy,
    reconcileNote: cloudOutcome?.reconcileNote,
    policyVersion: policyVersion,
  );
}

Future<_EvidenceOutcome> _processEvidence({
  required bool enabled,
  required String configPath,
  required Directory outDir,
  required Directory logsDir,
  required Map<String, dynamic> resultJson,
  required bool overlayRequested,
  required _LogFn log,
}) async {
  if (!enabled) {
    return const _EvidenceOutcome(
      enabled: false,
      topK: 0,
      generatedCount: 0,
      keptCount: 0,
      droppedCount: 0,
      overlayGenerated: false,
    );
  }

  final configStr = await _readFile(configPath, 'evidence config');
  final decoded = jsonDecode(configStr);
  if (decoded is! Map<String, dynamic>) {
    throw _CliException(
      'Evidence config must be a JSON object.',
      _exitParamError,
    );
  }

  final topK = (decoded['topK'] as num?)?.toInt() ?? 5;
  final windowMs = (decoded['windowMs'] as num?)?.toInt() ?? 1000;
  final thresholds = Map<String, dynamic>.from(
      decoded['thresholds'] as Map<String, dynamic>? ?? const {});
  final exportCfg = decoded['export'] as Map<String, dynamic>?;
  final overlayEnabled = overlayRequested || (exportCfg?['overlay'] == true);
  if (overlayEnabled) {
    log('INFO',
        'Evidence overlay export requested but not implemented. Snapshot paths will remain empty.');
  }

  final reps = (resultJson['reps'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final repByIndex = {
    for (final rep in reps)
      (rep['index'] as num?)?.toInt(): rep,
  };
  final evidenceList =
      (resultJson['evidence'] as List<dynamic>).cast<Map<String, dynamic>>();
  final baselineEvidence = evidenceList
      .map((item) => Map<String, dynamic>.from(item))
      .toList(growable: false);

  final issuesByFrame = <int, List<String>>{};
  for (final item in baselineEvidence) {
    if (item['type'] == 'issue') {
      final frameMs = (item['frameMs'] as num?)?.toInt();
      final code = item['code'] as String?;
      if (frameMs != null && code != null) {
        issuesByFrame.putIfAbsent(frameMs, () => []).add(code);
      }
    }
  }

  final fps = _resolveResultFps(resultJson);
  final filteredLegacy =
      _removeInvalidEvidenceEntries(evidenceList, strict: false);
  if (filteredLegacy > 0) {
    log('INFO', 'evidence: filtered $filteredLegacy invalid legacy items');
  }

  var normalizedLegacyDrops = 0;
  final normalizedExisting = <Map<String, dynamic>>[];
  for (final item in evidenceList) {
    final repIndex = (item['repIndex'] as num?)?.toInt();
    final normalized = _ensureSegmentEvidence(
      item,
      rep: repByIndex[repIndex],
      thresholds: thresholds,
      fallbackFps: fps,
      windowMs: windowMs,
    );
    if (normalized != null) {
      normalizedExisting.add(normalized);
    } else {
      normalizedLegacyDrops++;
    }
  }
  evidenceList
    ..clear()
    ..addAll(normalizedExisting);
  if (normalizedLegacyDrops > 0) {
    log('WARN',
        'evidence: dropped $normalizedLegacyDrops legacy items lacking required fields');
  }

  final repCandidates = reps
      .map((rep) {
        final valley = (rep['valleyMs'] as num?)?.toInt() ?? _repCenter(rep);
        final depth = (rep['kneeValleyAngle'] as num?)?.toDouble() ?? 0.0;
        final issues = issuesByFrame[valley] ?? const [];
        return (
          rep: rep,
          timestamp: valley,
          severity: depth,
          cues: issues.map((e) => 'issue:$e').toList(),
        );
      })
      .toList();
  repCandidates.sort((a, b) => b.severity.compareTo(a.severity));

  final limit = math.min(repCandidates.length, topK);
  final generated = <Map<String, dynamic>>[];
  for (var i = 0; i < limit; i++) {
    final candidate = repCandidates[i];
    final rep = candidate.rep;
    final timestamp = candidate.timestamp;
    final cues = List<String>.from(candidate.cues);
    final entry = <String, dynamic>{
      'type': 'segment',
      'timestampMs': timestamp,
      'frameIndex': (rep['index'] as num?)?.toInt(),
      'repIndex': (rep['index'] as num?)?.toInt(),
      'cues': cues,
      'thresholds': thresholds,
      'window': {
        'startMs': math.max(0, timestamp - windowMs ~/ 2),
        'endMs': timestamp + windowMs ~/ 2,
      },
      'snapshotPath': '',
    };
    final normalized = _ensureSegmentEvidence(
      entry,
      rep: rep,
      thresholds: thresholds,
      fallbackFps: fps,
      windowMs: windowMs,
    );
    if (normalized != null) {
      final depthThreshold =
          (thresholds['depth_minHipAngle'] as num?)?.toDouble();
      final depth = (rep['kneeValleyAngle'] as num?)?.toDouble();
      if (depthThreshold != null && depth != null) {
        normalized['scoreImpact'] = _roundDouble(depthThreshold - depth, 2);
      }
      generated.add(normalized);
    }
  }

  evidenceList.addAll(generated);
  final postMergeRemoved = _removeInvalidEvidenceEntries(evidenceList);
  if (postMergeRemoved > 0) {
    log('WARN',
        'evidence: dropped $postMergeRemoved entries failing final validation');
  }

  final keptGeneratedEntries =
      generated.where(evidenceList.contains).toList(growable: false);
  final keptGenerated = keptGeneratedEntries.length;
  final generatedAttempted = limit;
  final droppedGenerated = generatedAttempted - keptGenerated;
  if (droppedGenerated > 0) {
    log('WARN',
        'evidence: dropped $droppedGenerated generated items missing required data');
  }

  resultJson['evidence'] = evidenceList;

  final evidenceFile = File(path.join(outDir.path, 'evidence.json'));
  await evidenceFile
      .writeAsString(_prettyJsonEncoder.convert(keptGeneratedEntries));

  final perfFile = File(path.join(logsDir.path, 'perf.json.evidence'));
  await perfFile.writeAsString(_prettyJsonEncoder.convert({
    'generatedCount': generatedAttempted,
    'keptCount': keptGenerated,
    'droppedCount': droppedGenerated,
    'filteredLegacy': filteredLegacy + normalizedLegacyDrops,
    'topK': topK,
    'windowMs': windowMs,
    'overlayRequested': overlayEnabled,
    'overlayGenerated': false,
    'timestamp': DateTime.now().toIso8601String(),
  }));

  return _EvidenceOutcome(
    enabled: true,
    topK: topK,
    generatedCount: generatedAttempted,
    keptCount: keptGenerated,
    droppedCount: droppedGenerated,
    overlayGenerated: false,
  );
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