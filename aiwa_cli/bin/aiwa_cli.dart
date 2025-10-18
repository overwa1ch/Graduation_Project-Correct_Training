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
const _exitParamError = 1;
const _exitRuntimeError = 2;
const _exitValidationError = 3;

const _cliVersion = 'vB1.1-C-augment';
const _schemaVersion = 'vB1.1';

const _defaultOutDir = 'build/offline_out';
const _defaultEngine = 'mlkit';
const _defaultSamplingStride = 2;
const _defaultInputResolution = '720p';
const _defaultFps = 30.0;

const JsonEncoder _prettyJsonEncoder = JsonEncoder.withIndent('  ');

const Map<String, int> _logLevelPriority = {
  'trace': 10,
  'debug': 20,
  'info': 30,
  'warn': 40,
  'error': 50,
};

const Set<String> _allowedHybridOps = {'<', '<=', '>', '>=', '==', '!='};

bool? _ffmpegAvailableCache;

typedef _LogFn = void Function(String level, String message);

final Map<String, int> _neutralNameToIndex = {
  for (var i = 0; i < kNeutralKeypointNames.length; i++)
    kNeutralKeypointNames[i]: i,
};

class _EvidenceCliSpec {
  final bool enabled;
  final List<String> tokens;

  const _EvidenceCliSpec({
    required this.enabled,
    required this.tokens,
  });
}

class _PreparseResult {
  final List<String> normalizedArgs;
  final _EvidenceCliSpec evidence;

  const _PreparseResult({
    required this.normalizedArgs,
    required this.evidence,
  });
}

_PreparseResult _preparseArgs(List<String> rawArgs) {
  final normalized = <String>[];
  final evidenceTokens = <String>[];
  var evidenceFlag = false;
  var evidenceAdded = false;

  for (var i = 0; i < rawArgs.length; i++) {
    final token = rawArgs[i];
    if (token == '--evidence') {
      evidenceFlag = true;
      if (!evidenceAdded) {
        normalized.add('--evidence');
        evidenceAdded = true;
      }
      while (i + 1 < rawArgs.length && !rawArgs[i + 1].startsWith('-')) {
        evidenceTokens.add(rawArgs[++i]);
      }
    } else if (token.startsWith('--evidence=')) {
      evidenceFlag = true;
      final value = token.substring('--evidence='.length);
      if (!evidenceAdded) {
        normalized.add('--evidence');
        evidenceAdded = true;
      }
      if (value.isNotEmpty) {
        evidenceTokens.add(value);
      }
    } else {
      normalized.add(token);
    }
  }

  return _PreparseResult(
    normalizedArgs: normalized,
    evidence: _EvidenceCliSpec(
      enabled: evidenceFlag,
      tokens: evidenceTokens,
    ),
  );
}

Map<String, dynamic> _resolveEvidenceOptions(_EvidenceCliSpec spec) {
  var topK = 6;
  var windowMs = 1200;
  var exportOverlay = false;
  final extras = <String, String>{};

  for (final token in spec.tokens) {
    final eqIndex = token.indexOf('=');
    if (eqIndex <= 0 || eqIndex == token.length - 1) {
      throw _CliException(
        'Invalid --evidence option "$token". Use key=value form.',
        _exitParamError,
      );
    }
    final key = token.substring(0, eqIndex).trim();
    final value = token.substring(eqIndex + 1).trim();
    switch (key) {
      case 'topK':
        final parsed = int.tryParse(value);
        if (parsed == null || parsed <= 0) {
          throw _CliException(
            '--evidence topK must be a positive integer (got "$value").',
            _exitParamError,
          );
        }
        topK = parsed;
        break;
      case 'windowMs':
        final parsed = int.tryParse(value);
        if (parsed == null || parsed <= 0) {
          throw _CliException(
            '--evidence windowMs must be a positive integer (got "$value").',
            _exitParamError,
          );
        }
        windowMs = parsed;
        break;
      case 'exportOverlay':
        final lowered = value.toLowerCase();
        if (lowered == 'true' || lowered == '1') {
          exportOverlay = true;
        } else if (lowered == 'false' || lowered == '0') {
          exportOverlay = false;
        } else {
          throw _CliException(
            '--evidence exportOverlay expects true|false (got "$value").',
            _exitParamError,
          );
        }
        break;
      default:
        extras[key] = value;
        break;
    }
  }

  return {
    'topK': topK,
    'windowMs': windowMs,
    'exportOverlay': exportOverlay,
    if (extras.isNotEmpty) 'extras': extras,
  };
}

ArgParser _buildParser() {
  return ArgParser()
    ..addFlag('help',
        abbr: 'h', negatable: false, help: '显示帮助信息并退出。')
    ..addFlag('version',
        negatable: false, help: '显示 CLI 与 schema 版本并退出。')
    ..addOption('keypoints',
        abbr: 'k', valueHelp: 'path', help: '关键点 JSON 路径（必填，文件模式）。')
    ..addOption('video',
        valueHelp: 'path',
        help: '视频路径（仅做占位提醒，Flutter 版本才支持引擎模式）。')
    ..addOption('rule',
        abbr: 'r', valueHelp: 'path', help: '规则 JSON 路径（必填）。')
    ..addOption('out-dir',
        abbr: 'o',
        valueHelp: 'dir',
        defaultsTo: _defaultOutDir,
        help: '输出目录（默认：$_defaultOutDir）。')
    ..addFlag('dry-run',
        negatable: false,
        help: '仅解析/校验配置，不执行推理与导出。')
    ..addFlag('strict',
        negatable: false,
        help: '严格模式：校验失败即返回非零。')
    ..addFlag('fail-on-warn',
        negatable: false,
        help: '严格模式下遇到 WARN 也视为失败。')
    ..addOption('log-level',
        defaultsTo: 'info',
        allowed: _logLevelPriority.keys,
        help: '日志级别（trace|debug|info|warn|error）。')
    ..addOption('output-format',
        defaultsTo: 'human',
        allowed: ['human', 'json', 'junit', 'all'],
        help: '校验汇总输出格式（human|json|junit|all）。')
    ..addFlag('hybrid',
        negatable: false, help: '启用混合触发与云端合并逻辑。')
    ..addOption('hybrid-policy',
        valueHelp: 'path',
        defaultsTo: 'configs/hybrid_policy.json',
        help: '混合触发策略 JSON 路径。')
    ..addOption('cloud-mock',
        valueHelp: 'path',
        help: '云端增强结果的本地模拟输入（JSON）。')
    ..addFlag('evidence',
        negatable: false,
        help:
            '启用证据化输出，可跟随多个 key=value 参数（topK/windowMs/exportOverlay）。')
    ..addOption('engine',
        defaultsTo: _defaultEngine,
        allowed: ['mlkit', 'movenet'],
        help: '记录使用的引擎标签，便于日志归档。')
    ..addOption('strictness',
        defaultsTo: 'relaxed',
        allowed: ['relaxed', 'strict'],
        hide: true)
    ..addOption('out',
        defaultsTo: _defaultOutDir,
        hide: true);
}

String _usage(ArgParser parser) => '''
AIWA CLI — Offline Squat Pipeline (schema=$_schemaVersion / cli=$_cliVersion)

Usage:
  dart run bin/aiwa_cli.dart --keypoints <kp.json> --rule <rule.json> [options]

Options:
${parser.usage}

示例:
  # 本地关键点/视频 → 端侧分析 → 触发 Hybrid → 证据化（不导出 overlay）
  dart run bin/aiwa_cli.dart --engine mlkit --hybrid \
    --hybrid-policy ./configs/hybrid_policy.json \
    --evidence topK=8 windowMs=1500

  # 使用 cloud-mock 演示端侧/云端合并与证据定位，并导出 overlay.mp4
  dart run bin/aiwa_cli.dart --engine mlkit \
    --cloud-mock ./mocks/cloud_result.json \
    --evidence topK=10 exportOverlay=true

退出码:
  0: 成功（全部校验通过或严格模式下无失败）
  1: 参数/配置错误（文件缺失、JSON 解析失败、schema 不合规）
  2: 运行时错误（推理、合并或导出异常）
  3: 校验失败（仅在 --strict 或 CI 模式下）
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
  final pre = _preparseArgs(args);
  final parser = _buildParser();
  late final ArgResults opts;
  try {
    opts = parser.parse(pre.normalizedArgs);
  } on FormatException catch (e) {
    stderr.writeln('[ERROR] ${e.message}');
    stdout.writeln(_usage(parser));
    exit(_exitParamError);
  }

  if (opts['help'] == true) {
    stdout.write(_usage(parser));
    exit(_exitOk);
  }

  if (opts['version'] == true) {
    stdout.writeln('AIWA CLI $_cliVersion (schema $_schemaVersion)');
    exit(_exitOk);
  }

  try {
    _validateOptions(opts, pre.evidence);
    final rulePath = opts['rule'] as String;
    final ruleStr = await _readFile(rulePath, 'rule definition');
    final ruleSet = parseRuleSet(ruleStr);

    final evidenceEnabled = (opts['evidence'] == true) || pre.evidence.enabled;
    final evidenceOptions = evidenceEnabled
        ? _resolveEvidenceOptions(_EvidenceCliSpec(
            enabled: true,
            tokens: pre.evidence.tokens,
          ))
        : const <String, dynamic>{};

    final strictnessOpt = opts['strictness'] as String?;
    final strictness = (opts['strict'] == true || strictnessOpt == 'strict')
        ? Strictness.strict
        : Strictness.relaxed;

    if (opts['video'] != null) {
      await _runEngineMode(opts, ruleSet, strictness);
    } else {
      await _runFileMode(
        opts,
        ruleSet,
        strictness,
        evidenceEnabled: evidenceEnabled,
        evidenceOptions: evidenceOptions,
      );
    }
    exit(_exitOk);
  } on NeutralKeypointParseError catch (e) {   // 先抓具体解析错误
    stderr.writeln('[ERROR] ${e.message}');
    exit(_exitParamError);
  } on _CliException catch (e) {               // 再抓 CLI 的统一错误
    stderr.writeln('[ERROR] ${e.message}');
    if (e.showUsage) {
      stdout.write(_usage(parser));
    }
    exit(e.exitCode);
  } catch (e, stack) {                         // 最后兜底
    stderr.writeln('[FATAL] $e');
    stderr.writeln(stack);
    exit(_exitRuntimeError);
  }
}

void _validateOptions(ArgResults opts, _EvidenceCliSpec evidenceSpec) {
  final keypointsPath = (opts['keypoints'] as String?)?.trim();
  final videoProvided = (opts['video'] as String?)?.isNotEmpty ?? false;
  if (videoProvided) {
    throw _CliException(
      'Engine mode (--video) is only available in the Flutter build. '
      '本 CLI 仅支持 --keypoints 文件模式。',
      _exitParamError,
      showUsage: true,
    );
  }
  if (keypointsPath == null || keypointsPath.isEmpty) {
    throw _CliException(
      '--keypoints is required and must point to a JSON file.',
      _exitParamError,
      showUsage: true,
    );
  }
  if (!File(keypointsPath).existsSync()) {
    throw _CliException(
      'Keypoints file "$keypointsPath" does not exist.',
      _exitParamError,
    );
  }

  final rulePath = (opts['rule'] as String?)?.trim();
  if (rulePath == null || rulePath.isEmpty) {
    throw _CliException(
      '--rule is required and must point to a rule JSON file.',
      _exitParamError,
      showUsage: true,
    );
  }
  if (!File(rulePath).existsSync()) {
    throw _CliException(
      'Rule file "$rulePath" does not exist.',
      _exitParamError,
    );
  }

  final outDir = (opts['out-dir'] as String?)?.trim().isNotEmpty == true
      ? (opts['out-dir'] as String).trim()
      : ((opts['out'] as String?) ?? _defaultOutDir);
  if (outDir.isEmpty) {
    throw _CliException(
      '--out-dir must not be empty.',
      _exitParamError,
    );
  }

  final hybridEnabled = opts['hybrid'] == true;
  final hybridPolicyPath = (opts['hybrid-policy'] as String?)?.trim() ??
      'configs/hybrid_policy.json';
  if (hybridEnabled) {
    if (hybridPolicyPath.isEmpty) {
      throw _CliException(
        '--hybrid-policy must be provided when --hybrid is enabled.',
        _exitParamError,
      );
    }
    if (!File(hybridPolicyPath).existsSync()) {
      throw _CliException(
        'Hybrid policy "$hybridPolicyPath" not found.',
        _exitParamError,
      );
    }
  }

  final cloudMockPath = (opts['cloud-mock'] as String?)?.trim();
  if (cloudMockPath != null && cloudMockPath.isNotEmpty) {
    if (!File(cloudMockPath).existsSync()) {
      throw _CliException(
        'Cloud mock "$cloudMockPath" not found.',
        _exitParamError,
      );
    }
  }

  final logLevel = (opts['log-level'] as String?) ?? 'info';
  if (!_logLevelPriority.containsKey(logLevel)) {
    throw _CliException(
      'Unsupported --log-level "$logLevel". Allowed: ${_logLevelPriority.keys.join(', ')}.',
      _exitParamError,
    );
  }

  final evidenceEnabled = (opts['evidence'] == true) || evidenceSpec.enabled;
  if (!evidenceEnabled && evidenceSpec.tokens.isNotEmpty) {
    throw _CliException(
      '--evidence parameters provided without enabling the flag.',
      _exitParamError,
    );
  }
}

Future<void> _runFileMode(
  ArgResults opts,
  RuleSet ruleSet,
  Strictness strictness, {
  required bool evidenceEnabled,
  required Map<String, dynamic> evidenceOptions,
}) async {
  final keypointsPath = opts['keypoints'] as String;
  final outRootPath =
      (opts['out-dir'] as String?) ?? (opts['out'] as String?) ?? _defaultOutDir;
  final hybridEnabled = opts['hybrid'] == true;
  final hybridPolicyPath =
      (opts['hybrid-policy'] as String?) ?? 'configs/hybrid_policy.json';
  final cloudMockPath = opts['cloud-mock'] as String?;
  final dryRun = opts['dry-run'] == true;
  final failOnWarn = opts['fail-on-warn'] == true;
  final outputFormat = (opts['output-format'] as String?) ?? 'human';
  final logLevelName = (opts['log-level'] as String?) ?? 'info';
  final logThreshold =
      _logLevelPriority[logLevelName] ?? _logLevelPriority['info']!;

  final logLines = <String>[];
  void log(String level, String message) {
    final ts = DateTime.now().toIso8601String();
    final upper = level.toUpperCase();
    final normalized = level.toLowerCase();
    final severity = _logLevelPriority[normalized] ?? _logLevelPriority['info']!;
    final line = '[$ts][$upper] $message';
    logLines.add(line);
    if (severity >= logThreshold || normalized == 'error') {
      if (normalized == 'error') {
        stderr.writeln(line);
      } else {
        stdout.writeln(line);
      }
    }
  }

  log('info',
      'File mode start → keypoints=$keypointsPath outDir=$outRootPath dryRun=$dryRun');

  final kpStr = await _readFile(keypointsPath, 'keypoints JSON');
  final dynamic kpRoot = jsonDecode(kpStr);
  if (kpRoot is! Map<String, dynamic>) {
    throw _CliException(
      'Keypoints JSON must be an object.',
      _exitParamError,
    );
  }

  NeutralKeypointSeries? neutralSeries;
  late final PoseSeries poseSeries;
  if ((kpRoot['version'] as Object?) == _schemaVersion) {
    neutralSeries = parseNeutralKeypointSeriesFromMap(kpRoot);
    poseSeries = poseSeriesFromNeutral(neutralSeries);
  } else {
    final legacySeries = parseKeypointSeriesFromMap(kpRoot);
    poseSeries = poseSeriesFromLegacy(legacySeries);
  }

  if (dryRun) {
    if (hybridEnabled) {
      await _loadHybridPolicy(hybridPolicyPath, log);
    }
    if (cloudMockPath != null) {
      await _readCloudMock(cloudMockPath, log, validateOnly: true);
    }
    if (evidenceEnabled) {
      final topK = evidenceOptions['topK'];
      final windowMs = evidenceOptions['windowMs'];
      final exportOverlay = evidenceOptions['exportOverlay'];
      log('info',
          'Evidence dry-run settings → topK=$topK windowMs=$windowMs exportOverlay=$exportOverlay');
    }
    log('info', 'Dry-run完成：配置解析与校验通过，未执行推理。');
    return;
  }

  final pipeline = OfflinePipeline(ruleSet, strictness);
  late final ({String anglesCsv, Map<String, dynamic> resultJson}) out;
  try {
    out = await pipeline.run(poseSeries);
  } catch (e) {
    throw _CliException('Offline pipeline failed: $e', _exitRuntimeError);
  }

  final outRoot = Directory(outRootPath);
  final baseName = path.basenameWithoutExtension(keypointsPath);
  final outDir = Directory(path.join(outRoot.path, baseName))
    ..createSync(recursive: true);
  final logsDir = Directory(path.join(outDir.path, 'logs'))
    ..createSync(recursive: true);

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
    throw _CliException('Failed to write angles.csv: $e', _exitRuntimeError);
  }

  final hybridOutcome = await _processHybrid(
    enabled: hybridEnabled,
    policyPath: hybridPolicyPath,
    cloudMockPath: cloudMockPath,
    exportCloudFragment: false,
    logsDir: logsDir,
    resultJson: resultJson,
    perfData: null,
    neutralSeries: neutralSeries,
    baseName: baseName,
    log: log,
  );

  final evidenceOutcome = await _processEvidence(
    enabled: evidenceEnabled,
    options: evidenceOptions,
    outDir: outDir,
    logsDir: logsDir,
    resultJson: resultJson,
    ruleSet: ruleSet,
    strictness: strictness,
    log: log,
  );

  final validation = _ValidationContext(
    outDir: outDir,
    logsDir: logsDir,
    log: log,
    outputFormat: outputFormat,
  );

  _validateHybridArtifacts(
    logsDir: logsDir,
    outcome: hybridOutcome,
    resultJson: resultJson,
    validation: validation,
  );
  _validateEvidenceArtifacts(
    outDir: outDir,
    logsDir: logsDir,
    resultJson: resultJson,
    outcome: evidenceOutcome,
    validation: validation,
  );

  await validation.writeReports();

  if (validation.shouldFail(strict: opts['strict'] == true ||
      (opts['strictness'] as String?) == 'strict', failOnWarn: failOnWarn)) {
    throw _CliException(
      'Validation failed → errors=${validation.errorCount} warnings=${validation.warningCount}.',
      _exitValidationError,
    );
  }

  final resultFile = File(path.join(outDir.path, 'result.json'));
  try {
    await resultFile.writeAsString(jsonPretty(resultJson));
  } on IOException catch (e) {
    throw _CliException('Failed to write result.json: $e', _exitRuntimeError);
  }

  final runLogFile = File(path.join(logsDir.path, 'run.log'));
  await runLogFile.writeAsString(logLines.join('\n'));

  log('done', 'Outputs written:');
  log('done', '  - ${anglesFile.path}');
  log('done', '  - ${resultFile.path}');
  log('done', '  - ${runLogFile.path}');

  final summary = _buildHybridSummary(hybridOutcome, evidenceOutcome);
  if (summary != null) {
    log('info', summary);
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
    _exitParamError,
  );
}

class _HybridRuleSpec {
  final String name;
  final String metric;
  final String op;
  final double threshold;
  final double weight;

  const _HybridRuleSpec({
    required this.name,
    required this.metric,
    required this.op,
    required this.threshold,
    required this.weight,
  });
}

class _HybridTriggerSpec {
  final String mode;
  final double weightedSumThreshold;

  const _HybridTriggerSpec({
    required this.mode,
    required this.weightedSumThreshold,
  });
}

class _HybridPolicy {
  final String? version;
  final String engine;
  final String uploadPolicy;
  final List<_HybridRuleSpec> rules;
  final _HybridTriggerSpec trigger;
  final Map<String, dynamic> raw;

  const _HybridPolicy({
    required this.version,
    required this.engine,
    required this.uploadPolicy,
    required this.rules,
    required this.trigger,
    required this.raw,
  });
}

class _HybridEvaluationResult {
  final bool triggered;
  final List<String> reasons;
  final String? primaryReason;
  final double matchedWeight;
  final List<Map<String, dynamic>> diagnostics;

  const _HybridEvaluationResult({
    required this.triggered,
    required this.reasons,
    required this.primaryReason,
    required this.matchedWeight,
    required this.diagnostics,
  });
}

class _HybridOutcome {
  final bool enabled;
  final bool triggered;
  final String uploadPolicy;
  final String? reason;
  final List<String> reasons;
  final bool hadCloudMock;
  final bool cloudEnhanced;
  final int? countLocal;
  final int? countCloud;
  final int? countFinal;
  final String? mergeStrategy;
  final String? reconcileNote;
  final String? policyVersion;
  final Map<String, double> metrics;
  final Map<String, dynamic>? triggerSummary;
  final Map<String, dynamic>? slice;

  const _HybridOutcome({
    required this.enabled,
    required this.triggered,
    required this.uploadPolicy,
    required this.reason,
    required this.reasons,
    required this.hadCloudMock,
    required this.cloudEnhanced,
    required this.metrics,
    this.countLocal,
    this.countCloud,
    this.countFinal,
    this.mergeStrategy,
    this.reconcileNote,
    this.policyVersion,
    this.triggerSummary,
    this.slice,
  });
}

class _EvidenceOutcome {
  final bool enabled;
  final int topK;
  final int windowMs;
  final int generatedCount;
  final bool exportOverlayRequested;
  final bool overlayGenerated;
  final bool overlayDowngraded;
  final List<Map<String, dynamic>> generatedItems;

  const _EvidenceOutcome({
    required this.enabled,
    required this.topK,
    required this.windowMs,
    required this.generatedCount,
    required this.exportOverlayRequested,
    required this.overlayGenerated,
    required this.overlayDowngraded,
    required this.generatedItems,
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

class _ValidationItem {
  final String level;
  final String rule;
  final String detail;
  final String? hint;

  const _ValidationItem({
    required this.level,
    required this.rule,
    required this.detail,
    this.hint,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'rule': rule,
        'detail': detail,
        if (hint != null) 'hint': hint,
      };
}

class _ValidationContext {
  final Directory outDir;
  final Directory logsDir;
  final _LogFn log;
  final String outputFormat;
  final List<_ValidationItem> _items = [];

  _ValidationContext({
    required this.outDir,
    required this.logsDir,
    required this.log,
    required this.outputFormat,
  });

  int get errorCount =>
      _items.where((item) => item.level == 'ERROR').length;
  int get warningCount =>
      _items.where((item) => item.level == 'WARN').length;

  void error(String rule, String detail, {String? hint}) {
    _items.add(_ValidationItem(level: 'ERROR', rule: rule, detail: detail, hint: hint));
    log('ERROR', '$rule → $detail');
  }

  void warn(String rule, String detail, {String? hint}) {
    _items.add(_ValidationItem(level: 'WARN', rule: rule, detail: detail, hint: hint));
    log('WARN', '$rule → $detail');
  }

  Map<String, dynamic> _summaryJson() => {
        'summary': {'errors': errorCount, 'warnings': warningCount},
        'items': _items.map((e) => e.toJson()).toList(),
      };

  Future<void> writeReports() async {
    final reportFile =
        File(path.join(logsDir.path, 'validation_report.json'));
    await reportFile
        .writeAsString(_prettyJsonEncoder.convert(_summaryJson()));

    final junitFile =
        File(path.join(logsDir.path, 'validation_junit.xml'));
    final junitBuffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<testsuite name="aiwa_cli_validation" tests="${_items.length}" failures="$errorCount" warnings="$warningCount">');
    for (final item in _items) {
      junitBuffer.writeln('  <testcase name="${item.rule}">');
      if (item.level == 'ERROR') {
        junitBuffer.writeln('    <failure message="${_escapeXml(item.detail)}"/>');
      } else if (item.level == 'WARN') {
        junitBuffer.writeln('    <system-out>${_escapeXml(item.detail)}</system-out>');
      }
      junitBuffer.writeln('  </testcase>');
    }
    junitBuffer.writeln('</testsuite>');
    await junitFile.writeAsString(junitBuffer.toString());

    log('INFO', 'Validation summary → errors=$errorCount warnings=$warningCount');

    if (outputFormat == 'json' || outputFormat == 'all') {
      stdout.writeln(_prettyJsonEncoder.convert(_summaryJson()));
    }
    if (outputFormat == 'junit' || outputFormat == 'all') {
      stdout.writeln(junitBuffer.toString());
    }
  }

  bool shouldFail({required bool strict, required bool failOnWarn}) {
    if (!strict) {
      return false;
    }
    if (errorCount > 0) {
      return true;
    }
    if (failOnWarn && warningCount > 0) {
      return true;
    }
    return false;
  }
}

String _escapeXml(String input) => input
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

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
    if (hybrid.reason != null) {
      parts.add('reason=${hybrid.reason}');
    }
    parts.add('policy=${hybrid.uploadPolicy}');
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
    parts.add('evidence=topK${evidence.topK} generated=${evidence.generatedCount}');
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
  required Map<String, dynamic> resultJson,
  required _ValidationContext validation,
}) {
  final hybrid = resultJson['hybrid'] as Map<String, dynamic>?;
  if (hybrid == null) {
    if (outcome.enabled || outcome.hadCloudMock) {
      validation.error('hybrid.missing', 'result.json 缺少 hybrid 节点');
    }
    return;
  }
  if (resultJson['version'] == null) {
    validation.error('result.version', 'result.json 缺少 version 字段');
  }
  if (outcome.triggered) {
    if (hybrid['reason'] == null || (hybrid['reason'] as String).isEmpty) {
      validation.error('hybrid.reason', '混合触发但缺少 reason 字段');
    }
    if (hybrid['uploadPolicy'] == null) {
      validation.error('hybrid.upload_policy', '混合触发但缺少 uploadPolicy');
    }
    final triggerFile = File(path.join(logsDir.path, 'hybrid_trigger.json'));
    if (!triggerFile.existsSync()) {
      validation.warn('hybrid.trigger_log', '缺少 logs/hybrid_trigger.json');
    }
  }
  if (outcome.hadCloudMock) {
    final diffFile = File(path.join(logsDir.path, 'hybrid_diff.json'));
    if (!diffFile.existsSync()) {
      validation.warn('hybrid.diff_log', '提供 cloud-mock 但缺少 logs/hybrid_diff.json');
    }
  }

  final metrics = hybrid['metrics'] as Map<String, dynamic>? ?? {};
  final coverage = (metrics['coverage'] as num?)?.toDouble();
  if (coverage != null && (coverage < 0 || coverage > 1)) {
    validation.error('metrics.coverage_range', 'coverage=$coverage 超出 [0,1]');
  }
  final lowConf = (metrics['lowConfPct'] as num?)?.toDouble();
  if (lowConf != null && (lowConf < 0 || lowConf > 1)) {
    validation.error('metrics.low_conf_range', 'lowConfPct=$lowConf 超出 [0,1]');
  }
  if (!outcome.triggered && coverage != null && coverage < 0.6) {
    validation.warn('hybrid.low_coverage_untriggered',
        'coverage=$coverage 低于 0.6 但未触发混合策略');
  }

  if (hybrid['cloudEnhanced'] == true) {
    final delta = hybrid['delta'] as Map<String, dynamic>?;
    final local = (delta?['countLocal'] as num?)?.toInt();
    final finalCount = (delta?['countFinal'] as num?)?.toInt();
    final cloud = (delta?['countCloud'] as num?)?.toInt();
    if (local != null && finalCount != null && cloud != null) {
      if ((cloud - local).abs() > 2 &&
          (hybrid['reconcileNote'] as String?)?.isEmpty != false) {
        validation.warn('hybrid.missing_reconcile_note',
            'cloud=$cloud, local=$local, diff=${cloud - local} 未提供 reconcileNote');
      }
    }
  }
}

void _validateEvidenceArtifacts({
  required Directory outDir,
  required Directory logsDir,
  required Map<String, dynamic> resultJson,
  required _EvidenceOutcome outcome,
  required _ValidationContext validation,
}) {
  if (!outcome.enabled) {
    return;
  }
  final evidenceList =
      (resultJson['evidence'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
  if (evidenceList.isEmpty) {
    validation.error('evidence.empty', '已启用证据化但 evidence[] 为空');
  }
  for (var i = 0; i < evidenceList.length; i++) {
    final item = evidenceList[i];
    if (item['timestampMs'] is! num) {
      validation.error('evidence.timestamp', 'evidence[$i] 缺少 timestampMs');
    }
    final type = item['type'];
    if (type is! String || type.isEmpty) {
      validation.error('evidence.type', 'evidence[$i] 缺少 type');
    }
    final angles = item['angles'];
    if (angles is Map<String, dynamic>) {
      for (final entry in angles.entries) {
        final value = entry.value;
        if (value is num && (value.isNaN || value.isInfinite)) {
          validation.error('evidence.angle_nan',
              'evidence[$i].angles.${entry.key} 存在非法数值');
        }
      }
    }
  }

  final evidenceFile = File(path.join(outDir.path, 'evidence.json'));
  if (!evidenceFile.existsSync()) {
    validation.warn('evidence.file_missing', '缺少 evidence.json');
  }
  final perfFile = File(path.join(logsDir.path, 'perf.json'));
  if (!perfFile.existsSync()) {
    validation.warn('evidence.perf_missing', '缺少 logs/perf.json');
  }

  final overlayFile = File(path.join(outDir.path, 'overlay.mp4'));
  if (outcome.overlayGenerated) {
    if (!overlayFile.existsSync()) {
      validation.error('overlay.missing', '期望导出 overlay.mp4 但文件不存在');
    } else {
      _validateOverlayTimestamps(
        overlayFile: overlayFile,
        evidenceList: evidenceList,
        validation: validation,
        resultJson: resultJson,
      );
    }
  }
}

Map<String, double> _buildHybridMetrics(
  Map<String, dynamic> resultJson,
  Map<String, dynamic>? perfData,
  NeutralKeypointSeries? neutralSeries,
) {
  final quality = resultJson['quality'] as Map<String, dynamic>?;
  final coverage = (perfData?['usableFrameRatio'] as num?)?.toDouble() ??
      (quality?['coverage'] as num?)?.toDouble() ??
      0.0;
  final lowConf = (perfData?['lowConfidenceRatio'] as num?)?.toDouble() ??
      (quality?['lowConfidence'] as num?)?.toDouble() ??
      0.0;
  final meta = resultJson['meta'] as Map<String, dynamic>?;
  final fps = neutralSeries?.sampling.effectiveFps ??
      (meta?['fps'] as num?)?.toDouble() ??
      0.0;

  return {
    'coverage': _roundDouble(coverage, 4),
    'lowConfPct': _roundDouble(lowConf, 4),
    'fps': _roundDouble(fps, 2),
    'jitterPx': _roundDouble((perfData?['jitterPx'] as num?)?.toDouble() ?? 0.0, 2),
  };
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
  final privacy =
      (policy['uploadPolicy'] as String?) ?? (policy['privacy'] as String?) ?? 'keypoints_only';
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
  required Map<String, dynamic> cloudData,
  required Map<String, dynamic> resultJson,
  required Directory logsDir,
  required _LogFn log,
}) async {
  final cloudCounts = cloudData['counts'] as int?;
  final cloudSegments =
      (cloudData['segments'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
  if (cloudSegments.isEmpty) {
    log('WARN', 'Cloud mock缺少 segments 列表，跳过云端合并。');
    return null;
  }
  final quality = cloudData['quality'] as Map<String, dynamic>? ?? const {};
  final notes = cloudData['notes'];

  final toleranceMs = 200;
  final localReps = (resultJson['reps'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final used = <int>{};
  final matches = <Map<String, dynamic>>[];
  final unmatchedCloud = <Map<String, dynamic>>[];
  var boundariesAdopted = 0;
  var matchedCount = 0;
  final evidenceAdditions = <Map<String, dynamic>>[];

  for (final segment in cloudSegments) {
    final cloudRep = {
      'startMs': segment['startMs'],
      'endMs': segment['endMs'],
      'idx': segment['repIndex'] ?? segment['index'],
    };
    final matched = _matchCloudToLocal(localReps, cloudRep, used, toleranceMs);
    if (matched == null) {
      unmatchedCloud.add(segment);
      continue;
    }
    matchedCount++;
    final localStart = (matched['startMs'] as num?)?.toInt();
    final localEnd = (matched['endMs'] as num?)?.toInt();
    final cloudStart = (segment['startMs'] as num?)?.toInt();
    final cloudEnd = (segment['endMs'] as num?)?.toInt();
    final entry = <String, dynamic>{
      'index': (matched['index'] as num?)?.toInt() ??
          (segment['repIndex'] as num?)?.toInt(),
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
      });
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

Future<_HybridPolicy> _loadHybridPolicy(String path, _LogFn log) async {
  final policyStr = await _readFile(path, 'hybrid policy');
  final decoded = jsonDecode(policyStr);
  if (decoded is! Map<String, dynamic>) {
    throw _CliException(
      'Hybrid policy must be a JSON object.',
      _exitParamError,
    );
  }

  final version = decoded['version'] as String?;
  final engine = (decoded['engine'] as String? ?? 'any').toLowerCase();
  if (!['any', 'mlkit', 'movenet'].contains(engine)) {
    throw _CliException(
      'Unsupported hybrid policy engine "$engine".',
      _exitParamError,
    );
  }

  final uploadPolicy =
      (decoded['uploadPolicy'] as String? ?? 'keypoints_only');
  if (!{'keypoints_only', 'keypoints_plus_video'}.contains(uploadPolicy)) {
    throw _CliException(
      'Unsupported uploadPolicy "$uploadPolicy" in hybrid policy.',
      _exitParamError,
    );
  }

  final rulesRaw = (decoded['rules'] as List<dynamic>? ?? []);
  final rules = <_HybridRuleSpec>[];
  for (final entry in rulesRaw) {
    if (entry is! Map<String, dynamic>) {
      continue;
    }
    final name = entry['name'] as String?;
    final metric = entry['metric'] as String?;
    final op = entry['op'] as String?;
    final threshold = (entry['threshold'] as num?)?.toDouble();
    final weight = (entry['weight'] as num?)?.toDouble() ?? 1.0;
    if (name == null || metric == null || op == null || threshold == null) {
      throw _CliException(
        'Hybrid rule entries must include name/metric/op/threshold.',
        _exitParamError,
      );
    }
    if (!_allowedHybridOps.contains(op)) {
      throw _CliException(
        'Hybrid rule "$name" uses unsupported op "$op".',
        _exitParamError,
      );
    }
    rules.add(_HybridRuleSpec(
      name: name,
      metric: metric,
      op: op,
      threshold: threshold,
      weight: weight,
    ));
  }
  if (rules.isEmpty) {
    log('WARN', 'Hybrid policy contains no trigger rules; hybrid will never fire.');
  }

  final triggerMap = decoded['trigger'] as Map<String, dynamic>? ?? const {};
  final triggerMode = (triggerMap['mode'] as String? ?? 'any');
  if (!{'any', 'all', 'weighted_sum'}.contains(triggerMode)) {
    throw _CliException(
      'Unsupported trigger.mode "$triggerMode" in hybrid policy.',
      _exitParamError,
    );
  }
  final weightedThreshold =
      (triggerMap['weighted_sum_threshold'] as num?)?.toDouble() ?? 1.0;

  return _HybridPolicy(
    version: version,
    engine: engine,
    uploadPolicy: uploadPolicy,
    rules: rules,
    trigger: _HybridTriggerSpec(
      mode: triggerMode,
      weightedSumThreshold: weightedThreshold,
    ),
    raw: decoded,
  );
}

_HybridEvaluationResult _evaluateHybridPolicy(
  _HybridPolicy policy,
  Map<String, double> metrics,
) {
  final diagnostics = <Map<String, dynamic>>[];
  final reasons = <String>[];
  var matchedWeight = 0.0;

  for (final rule in policy.rules) {
    final metricValue = metrics[rule.metric];
    final matched = metricValue != null &&
        _compareHybridMetric(metricValue, rule.threshold, rule.op);
    diagnostics.add({
      'name': rule.name,
      'metric': rule.metric,
      'value': metricValue,
      'op': rule.op,
      'threshold': rule.threshold,
      'weight': rule.weight,
      'matched': matched,
    });
    if (matched) {
      matchedWeight += rule.weight;
      reasons.add(rule.name);
    }
  }

  bool triggered;
  switch (policy.trigger.mode) {
    case 'all':
      triggered = policy.rules.isNotEmpty &&
          reasons.length == policy.rules.length;
      break;
    case 'weighted_sum':
      triggered = matchedWeight >= policy.trigger.weightedSumThreshold;
      break;
    case 'any':
    default:
      triggered = reasons.isNotEmpty;
      break;
  }

  return _HybridEvaluationResult(
    triggered: triggered,
    reasons: reasons,
    primaryReason: reasons.isEmpty ? null : reasons.first,
    matchedWeight: matchedWeight,
    diagnostics: diagnostics,
  );
}

Future<Map<String, dynamic>> _readCloudMock(
  String pathStr,
  _LogFn log,
) async {
  final mockStr = await _readFile(pathStr, 'cloud mock');
  final decoded = jsonDecode(mockStr);
  if (decoded is! Map<String, dynamic>) {
    throw _CliException(
      'Cloud mock must be a JSON object.',
      _exitParamError,
    );
  }
  final segments = (decoded['segments'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map((segment) => Map<String, dynamic>.from(segment))
      .toList();
  if (segments.isEmpty) {
    final legacy = (decoded['reps'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((segment) => Map<String, dynamic>.from(segment))
        .toList();
    if (legacy.isNotEmpty) {
      log('WARN', 'cloud mock uses legacy "reps" field; treating as segments.');
      segments.addAll(legacy);
    }
  }

  return {
    'raw': decoded,
    'source': decoded['source'] as String? ?? 'mock',
    'counts': (decoded['counts'] as num?)?.toInt(),
    'segments': segments,
    'quality': decoded['quality'] as Map<String, dynamic>? ?? const {},
    'notes': decoded['notes'] as String?,
  };
}

double? _estimateResultDurationSeconds(Map<String, dynamic> resultJson) {
  final meta = resultJson['meta'] as Map<String, dynamic>?;
  final durationMs = (meta?['durationMs'] as num?)?.toDouble();
  if (durationMs != null) {
    return durationMs / 1000.0;
  }
  final reps = (resultJson['reps'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>();
  if (reps.isEmpty) {
    return null;
  }
  var minStart = double.infinity;
  var maxEnd = 0.0;
  for (final rep in reps) {
    final start = (rep['startMs'] as num?)?.toDouble();
    final end = (rep['endMs'] as num?)?.toDouble();
    final valley = (rep['valleyMs'] as num?)?.toDouble();
    if (start != null) {
      minStart = math.min(minStart, start);
      maxEnd = math.max(maxEnd, start);
    }
    if (end != null) {
      minStart = math.min(minStart, end);
      maxEnd = math.max(maxEnd, end);
    }
    if (valley != null) {
      minStart = math.min(minStart, valley);
      maxEnd = math.max(maxEnd, valley);
    }
  }
  if (minStart == double.infinity) {
    return null;
  }
  return (maxEnd - minStart).abs() / 1000.0;
}

Future<void> _validateOverlayTimestamps({
  required File overlayFile,
  required List<Map<String, dynamic>> evidenceList,
  required _ValidationContext validation,
  required Map<String, dynamic> resultJson,
}) async {
  try {
    final probe = await _probeVideo(overlayFile.path);
    final durationSec = probe.durationMs / 1000.0;
    final expectedSec = _estimateResultDurationSeconds(resultJson);
    if (expectedSec != null) {
      final diff = (durationSec - expectedSec).abs();
      if (diff > 1.0) {
        validation.error(
          'overlay.duration_mismatch',
          'overlay.mp4=${durationSec.toStringAsFixed(2)}s vs result=${expectedSec.toStringAsFixed(2)}s; diff=${diff.toStringAsFixed(2)}s > 1.0s',
          hint: '请重新导出 overlay.mp4 或校准 result.json 时间区间',
        );
      }
    }
    for (final item in evidenceList) {
      final ref = item['snapshotRef'] as String?;
      if (ref == null) {
        continue;
      }
      final hashIndex = ref.indexOf('#t=');
      if (hashIndex == -1) {
        continue;
      }
      final tStr = ref.substring(hashIndex + 3);
      final timestamp = double.tryParse(tStr);
      if (timestamp != null && (timestamp < -0.01 || timestamp > durationSec + 0.01)) {
        validation.error(
          'overlay.snapshot_out_of_range',
          'snapshotRef=$ref 超出 overlay.mp4 时长 ${durationSec.toStringAsFixed(2)}s',
        );
      }
    }
  } on _CliException {
    rethrow;
  } catch (e) {
    validation.warn('overlay.probe_failed', '无法解析 overlay.mp4: $e');
  }
}

Future<bool> _isFfmpegAvailable() async {
  if (_ffmpegAvailableCache != null) {
    return _ffmpegAvailableCache!;
  }
  try {
    final result = await Process.run('ffmpeg', ['-version']);
    _ffmpegAvailableCache = result.exitCode == 0;
  } on ProcessException {
    _ffmpegAvailableCache = false;
  }
  return _ffmpegAvailableCache!;
}

Map<String, double> _buildEvidenceThresholds(
  RuleSet ruleSet,
  Strictness strictness,
) {
  final thresholds = <String, double>{};
  final strictKey = strictness == Strictness.strict ? 'strict' : 'relaxed';
  final metrics = ruleSet.metrics;

  final depth = metrics['depth'] as Map<String, dynamic>?;
  final depthMap = depth?['kneeAngleMin'] as Map<String, dynamic>?;
  final depthValue = (depthMap?[strictKey] as num?)?.toDouble();
  if (depthValue != null) {
    thresholds['depth_minHipAngle'] = depthValue;
  }

  final valgus = metrics['valgus'] as Map<String, dynamic>?;
  final kneeOut = valgus?['kneeOutAngleMin'] as Map<String, dynamic>?;
  final valgusValue = (kneeOut?[strictKey] as num?)?.toDouble();
  if (valgusValue != null) {
    thresholds['leftKnee_maxValgus'] = valgusValue;
    thresholds['rightKnee_maxValgus'] = valgusValue;
  }

  final trunk = metrics['trunk'] as Map<String, dynamic>?;
  final forwardLean = trunk?['maxForwardLean'] as Map<String, dynamic>?;
  final trunkValue = (forwardLean?[strictKey] as num?)?.toDouble();
  if (trunkValue != null) {
    thresholds['trunk_maxForwardLean'] = trunkValue;
  }

  return thresholds;
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
  final metrics = _buildHybridMetrics(resultJson, perfData, neutralSeries);
  final hadCloudMock = cloudMockPath != null;

  _HybridPolicy? policy;
  _HybridEvaluationResult? evaluation;
  Map<String, dynamic>? slice;
  Map<String, dynamic>? triggerPayload;

  if (enabled) {
    policy = await _loadHybridPolicy(policyPath, log);
    evaluation = _evaluateHybridPolicy(policy, metrics);
    slice = _computeHybridSlice(resultJson, policy.raw);
    triggerPayload = {
      if (policy.version != null) 'version': policy.version,
      'triggered': evaluation.triggered,
      'metrics': metrics,
      'mode': policy.trigger.mode,
      'matchedWeight': evaluation.matchedWeight,
      'threshold': policy.trigger.weightedSumThreshold,
      'diagnostics': evaluation.diagnostics,
      if (slice != null) 'slice': slice,
    };
    final triggerFile = File(path.join(logsDir.path, 'hybrid_trigger.json'));
    await triggerFile.writeAsString(_prettyJsonEncoder.convert(triggerPayload));

    if (evaluation.triggered) {
      if (neutralSeries != null) {
        final payloadArtifacts = _buildCloudPayload(
          policy: policy.raw,
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
  }

  Map<String, dynamic>? cloudData;
  if (hadCloudMock && cloudMockPath != null) {
    cloudData = await _readCloudMock(cloudMockPath, log);
  }

  _CloudMergeOutcome? cloudOutcome;
  if (cloudData != null) {
    cloudOutcome = await _mergeCloudMock(
      cloudData: cloudData,
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

  final uploadPolicy = policy?.uploadPolicy ?? 'keypoints_only';
  final hybridSummary = <String, dynamic>{
    'triggered': evaluation?.triggered ?? false,
    'uploadPolicy': uploadPolicy,
    'metrics': metrics,
    'cloudEnhanced': cloudOutcome?.cloudEnhanced ?? false,
    if (evaluation?.primaryReason != null) 'reason': evaluation!.primaryReason,
    if (evaluation != null && evaluation.reasons.isNotEmpty)
      'reasons': evaluation.reasons,
    if (policy?.version != null) 'policyVersion': policy!.version,
    if (triggerPayload != null) 'trigger': triggerPayload,
    if (slice != null) 'slice': slice,
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
    if (cloudData != null) 'cloudMockSource': cloudData['source'],
  };
  resultJson['hybrid'] = hybridSummary;

  return _HybridOutcome(
    enabled: enabled,
    triggered: evaluation?.triggered ?? false,
    uploadPolicy: uploadPolicy,
    reason: evaluation?.primaryReason,
    reasons: evaluation?.reasons ?? const [],
    hadCloudMock: hadCloudMock,
    cloudEnhanced: cloudOutcome?.cloudEnhanced ?? false,
    metrics: metrics,
    countLocal: cloudOutcome?.countLocal,
    countCloud: cloudOutcome?.countCloud,
    countFinal: cloudOutcome?.countFinal,
    mergeStrategy: cloudOutcome?.mergeStrategy,
    reconcileNote: cloudOutcome?.reconcileNote,
    policyVersion: policy?.version,
    triggerSummary: triggerPayload,
    slice: slice,
  );
}

Future<_EvidenceOutcome> _processEvidence({
  required bool enabled,
  required Map<String, dynamic> options,
  required Directory outDir,
  required Directory logsDir,
  required Map<String, dynamic> resultJson,
  required RuleSet ruleSet,
  required Strictness strictness,
  required _LogFn log,
}) async {
  if (!enabled) {
    return const _EvidenceOutcome(
      enabled: false,
      topK: 0,
      windowMs: 0,
      generatedCount: 0,
      exportOverlayRequested: false,
      overlayGenerated: false,
      overlayDowngraded: false,
      generatedItems: const [],
    );
  }

  final topK = (options['topK'] as int?) ?? 6;
  final windowMs = (options['windowMs'] as int?) ?? 1200;
  final exportOverlayRequested = options['exportOverlay'] == true;
  final extras = options['extras'] as Map<String, String>?;
  if (extras != null && extras.isNotEmpty) {
    log('WARN',
        '忽略未知的 --evidence 参数: ${extras.keys.join(', ')}');
  }
  final overlaySupported = exportOverlayRequested && await _isFfmpegAvailable();
  final overlayDowngraded = exportOverlayRequested && !overlaySupported;
  if (overlayDowngraded) {
    log('WARN', 'exportOverlay=true 但未检测到 ffmpeg，自动降级为 false');
  }

  final thresholds = _buildEvidenceThresholds(ruleSet, strictness);
  final reps = (resultJson['reps'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final evidenceList =
      (resultJson['evidence'] as List<dynamic>).cast<Map<String, dynamic>>();

  final issuesByFrame = <int, List<String>>{};
  for (final item in evidenceList) {
    if (item['type'] == 'issue') {
      final frameMs = (item['frameMs'] as num?)?.toInt();
      final code = item['code'] as String?;
      if (frameMs != null && code != null) {
        issuesByFrame.putIfAbsent(frameMs, () => []).add(code);
      }
    }
  }

  final selectWatch = Stopwatch()..start();
  final repCandidates = reps
      .map((rep) {
        final valley = (rep['valleyMs'] as num?)?.toInt() ?? _repCenter(rep);
        final severity = (rep['kneeValleyAngle'] as num?)?.toDouble() ?? 0.0;
        final cues = List<String>.from(issuesByFrame[valley] ?? const []);
        return (
          rep: rep,
          timestamp: valley,
          severity: severity,
          cues: cues,
        );
      })
      .toList()
    ..sort((a, b) => b.severity.compareTo(a.severity));
  selectWatch.stop();

  final generated = <Map<String, dynamic>>[];
  for (var i = 0; i < repCandidates.length && i < topK; i++) {
    final candidate = repCandidates[i];
    final rep = candidate.rep;
    final timestamp = candidate.timestamp;
    final cues = List<String>.from(candidate.cues);
    final repIndex = (rep['index'] as num?)?.toInt();
    if (cues.isEmpty) {
      cues.add('rep:${repIndex ?? i}');
    }

    final angles = <String, double>{};
    final valleyAngle = (rep['kneeValleyAngle'] as num?)?.toDouble();
    if (valleyAngle != null) {
      angles['leftKnee'] = _roundDouble(valleyAngle, 1);
    }
    final forwardLean = (rep['maxForwardLean'] as num?)?.toDouble();
    if (forwardLean != null) {
      angles['hipFlexion'] = _roundDouble(forwardLean, 1);
    }

    final entry = <String, dynamic>{
      'type': 'segment',
      'timestampMs': timestamp,
      'frameIndex': repIndex,
      'repIndex': repIndex,
      'phase': 'bottom',
      'cues': cues,
      'angles': angles,
      'thresholds': thresholds,
    };
    if (overlaySupported) {
      entry['snapshotRef'] =
          'overlay.mp4#t=${(timestamp / 1000.0).toStringAsFixed(2)}';
    }
    generated.add(entry);
  }

  evidenceList.addAll(generated);

  final evidenceFile = File(path.join(outDir.path, 'evidence.json'));
  await evidenceFile.writeAsString(_prettyJsonEncoder.convert(generated));

  final perfFile = File(path.join(logsDir.path, 'perf.json'));
  await perfFile.writeAsString(_prettyJsonEncoder.convert({
    'generatedCount': generated.length,
    'topK': topK,
    'windowMs': windowMs,
    'overlayRequested': exportOverlayRequested,
    'overlayGenerated': false,
    'overlayDowngraded': overlayDowngraded,
    'evidence_select_ms': selectWatch.elapsedMilliseconds,
    'overlay_render_ms': 0,
    'timestamp': DateTime.now().toIso8601String(),
  }));

  return _EvidenceOutcome(
    enabled: true,
    topK: topK,
    windowMs: windowMs,
    generatedCount: generated.length,
    exportOverlayRequested: exportOverlayRequested,
    overlayGenerated: false,
    overlayDowngraded: overlayDowngraded,
    generatedItems: generated,
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
        _exitRuntimeError,
      );
    }

    final decoded = jsonDecode(result.stdout as String) as Map<String, dynamic>;
    final streams = decoded['streams'] as List<dynamic>?;
    if (streams == null || streams.isEmpty) {
      throw _CliException(
        'ffprobe could not find a video stream in "$videoPath".',
        _exitRuntimeError,
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
      _exitRuntimeError,
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
    throw _CliException('ffmpeg not available: $e', _exitRuntimeError);
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
      _exitRuntimeError,
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