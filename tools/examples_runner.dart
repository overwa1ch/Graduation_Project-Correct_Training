import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = RunnerOptions.parse(args);
  final runner = ExamplesRunner(options);
  final results = await runner.run();
  final failed = results.where((r) => !r.passed).toList();
  if (failed.isNotEmpty) {
    exit(1);
  }
}

class RunnerOptions {
  RunnerOptions({
    required this.manifestPath,
    required this.rulePath,
    required this.cliWorkingDir,
    required this.cliEntry,
    required this.outputRoot,
    required this.dartExecutable,
    required this.evidenceConfigPath,
    required this.cueMapPath,
    required this.verbose,
    required this.onlySampleIds,
    required this.engine,
  });

  final String manifestPath;
  final String rulePath;
  final String cliWorkingDir;
  final String cliEntry;
  final String outputRoot;
  final String dartExecutable;
  final String evidenceConfigPath;
  final String cueMapPath;
  final bool verbose;
  final List<String> onlySampleIds;
  final String engine;

  static void _printUsage() {
    stdout.writeln('''examples_runner.dart — run AIWA CLI against Milestone C samples

Usage: dart tools/examples_runner.dart [options]

Options:
  --manifest <path>    Path to examples manifest JSON.
  --rule <path>        Path to squat rule JSON file.
  --out <path>         Output root directory for generated artifacts.
  --cli-dir <path>     Working directory containing aiwa_cli pubspec.
  --cli-entry <path>   CLI entrypoint relative to --cli-dir.
  --dart <path>        Dart executable to use (default: dart).
  --engine <name>      Engine to use for video samples (default: mlkit).
  --only <ids>         Comma-separated sample IDs to run.
  --verbose            Stream CLI output while running.
  --evidence-config    Override evidence config path.
  --cue-map            Override cue map path.
  * Provide either neutral_keypoints.json or input.mp4 for each sample.
  -h, --help           Show this help message.
''');
  }

  factory RunnerOptions.parse(List<String> args) {
    var manifestPath = 'examples/examples_manifest.json';
    var rulePath = 'aiwa_core/test/fixtures/squat.v1.json';
    var outputRoot = 'build/examples_runner';
    var cliDir = 'aiwa_cli';
    var cliEntry = 'bin/aiwa_cli.dart';
    var dartExecutable = 'dart';
    var verbose = false;
    final only = <String>[];
    var evidenceConfigPath = 'configs/evidence_config.json';
    var cueMapPath = 'rules/cue_advice_map.json';
    var engine = 'mlkit';

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '--help' || arg == '-h') {
        _printUsage();
        exit(0);
      } else if (arg.startsWith('--manifest=')) {
        manifestPath = arg.substring('--manifest='.length);
      } else if (arg == '--manifest') {
        if (i + 1 >= args.length) {
          _error('--manifest requires a value.');
        }
        manifestPath = args[++i];
      } else if (arg.startsWith('--rule=')) {
        rulePath = arg.substring('--rule='.length);
      } else if (arg == '--rule') {
        if (i + 1 >= args.length) {
          _error('--rule requires a value.');
        }
        rulePath = args[++i];
      } else if (arg.startsWith('--out=')) {
        outputRoot = arg.substring('--out='.length);
      } else if (arg == '--out') {
        if (i + 1 >= args.length) {
          _error('--out requires a value.');
        }
        outputRoot = args[++i];
      } else if (arg.startsWith('--cli-dir=')) {
        cliDir = arg.substring('--cli-dir='.length);
      } else if (arg == '--cli-dir') {
        if (i + 1 >= args.length) {
          _error('--cli-dir requires a value.');
        }
        cliDir = args[++i];
      } else if (arg.startsWith('--cli-entry=')) {
        cliEntry = arg.substring('--cli-entry='.length);
      } else if (arg == '--cli-entry') {
        if (i + 1 >= args.length) {
          _error('--cli-entry requires a value.');
        }
        cliEntry = args[++i];
      } else if (arg.startsWith('--dart=')) {
        dartExecutable = arg.substring('--dart='.length);
      } else if (arg == '--dart') {
        if (i + 1 >= args.length) {
          _error('--dart requires a value.');
        }
        dartExecutable = args[++i];
      } else if (arg.startsWith('--engine=')) {
        engine = arg.substring('--engine='.length);
      } else if (arg == '--engine') {
        if (i + 1 >= args.length) {
          _error('--engine requires a value.');
        }
        engine = args[++i];
      } else if (arg == '--verbose') {
        verbose = true;
      } else if (arg.startsWith('--only=')) {
        only.addAll(arg.substring('--only='.length)
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim()));
      } else if (arg == '--only') {
        if (i + 1 >= args.length) {
          _error('--only requires a value.');
        }
        only.addAll(args[++i]
            .split(',')
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim()));
      } else if (arg.startsWith('--evidence-config=')) {
        evidenceConfigPath = arg.substring('--evidence-config='.length);
      } else if (arg == '--evidence-config') {
        if (i + 1 >= args.length) {
          _error('--evidence-config requires a value.');
        }
        evidenceConfigPath = args[++i];
      } else if (arg.startsWith('--cue-map=')) {
        cueMapPath = arg.substring('--cue-map='.length);
      } else if (arg == '--cue-map') {
        if (i + 1 >= args.length) {
          _error('--cue-map requires a value.');
        }
        cueMapPath = args[++i];
      } else {
        _error('Unknown option: $arg');
      }
    }

    return RunnerOptions(
      manifestPath: _absoluteFilePath(manifestPath),
      rulePath: _absoluteFilePath(rulePath),
      cliWorkingDir: _absoluteDirPath(cliDir),
      cliEntry: cliEntry,
      outputRoot: _absoluteDirPath(outputRoot),
      dartExecutable: dartExecutable,
      evidenceConfigPath: _absoluteFilePath(evidenceConfigPath),
      cueMapPath: _absoluteFilePath(cueMapPath),
      verbose: verbose,
      onlySampleIds: only,
      engine: engine,
    );
  }

  static Never _error(String message) {
    stderr.writeln('Error: $message');
    _printUsage();
    exit(64);
  }
}

class ExamplesRunner {
  ExamplesRunner(this.options);

  final RunnerOptions options;

  Future<List<SampleRunResult>> run() async {
    final manifestFile = File(options.manifestPath);
    if (!manifestFile.existsSync()) {
      throw StateError('Manifest not found at ${options.manifestPath}');
    }

    final manifestRaw = jsonDecode(await manifestFile.readAsString());
    if (manifestRaw is! List) {
      throw StateError('Manifest root must be a JSON array.');
    }

    final specs = manifestRaw
        .whereType<Map<String, dynamic>>()
        .map(SampleSpec.fromJson)
        .toList(growable: false);

    final selectedSpecs = options.onlySampleIds.isEmpty
        ? specs
        : specs
            .where((spec) => options.onlySampleIds.contains(spec.sampleId))
            .toList(growable: false);

    final missingRequested = options.onlySampleIds
        .where((id) => !selectedSpecs.any((spec) => spec.sampleId == id))
        .toList(growable: false);
    if (missingRequested.isNotEmpty) {
      stderr.writeln('Warning: requested sample(s) not found in manifest: '
          '${missingRequested.join(', ')}');
    }

    final results = <SampleRunResult>[];
    for (final spec in selectedSpecs) {
      results.add(await _runSample(spec));
    }

    final passedCount = results.where((r) => r.passed).length;
    final failed = results.where((r) => !r.passed).toList(growable: false);

    stdout.writeln(
        'Completed ${results.length} sample(s): $passedCount passed, ${failed.length} failed.');
    if (failed.isNotEmpty) {
      for (final result in failed) {
        stderr.writeln('--- ${result.sampleId} FAILED ---');
        for (final message in result.messages) {
          stderr.writeln('  • $message');
        }
        if (result.stderrLines.isNotEmpty) {
          stderr.writeln('  stderr:');
          for (final line in result.stderrLines) {
            stderr.writeln('    $line');
          }
        }
        if (result.stdoutLines.isNotEmpty) {
          stderr.writeln('  stdout:');
          for (final line in result.stdoutLines) {
            stderr.writeln('    $line');
          }
        }
      }
    }

    return results;
  }

  Future<SampleRunResult> _runSample(SampleSpec spec) async {
    stdout.writeln('[${spec.sampleId}] Running sample (${spec.category})...');
    final sampleDir = Directory(
      _resolvePath(Directory.current.path, 'examples/${spec.sampleId}'),
    );
    if (!sampleDir.existsSync()) {
      return SampleRunResult.failure(
        sampleId: spec.sampleId,
        reason: 'Sample directory not found: ${sampleDir.path}',
      );
    }

    String? keypointsPath;
    String? videoPath;
    String? hybridPolicyPath;
    String? cloudMockPath;
    Map<String, dynamic>? cloudResultData;

    for (final input in spec.inputs) {
      final resolved = _resolvePath(sampleDir.path, input);
      final file = File(resolved);
      if (!file.existsSync()) {
        return SampleRunResult.failure(
          sampleId: spec.sampleId,
          reason: 'Missing input "$input" at $resolved',
        );
      }
      if (input.endsWith('.json') && input.contains('keypoints')) {
        keypointsPath = file.path;
      } else if (input.endsWith('.mp4')) {
        videoPath = file.path;
      }
      if (input == 'hybrid_policy.json') {
        hybridPolicyPath = file.path;
      } else if (input == 'cloud_result.json') {
        cloudMockPath = file.path;
        try {
          final decoded = jsonDecode(file.readAsStringSync());
          if (decoded is Map<String, dynamic>) {
            cloudResultData = decoded;
          } else {
            return SampleRunResult.failure(
              sampleId: spec.sampleId,
              reason: 'cloud_result.json must decode to an object.',
            );
          }
        } catch (e) {
          return SampleRunResult.failure(
            sampleId: spec.sampleId,
            reason: 'Failed to parse cloud_result.json: $e',
          );
        }
      }
    }

    if (keypointsPath == null && videoPath == null) {
      return SampleRunResult.failure(
        sampleId: spec.sampleId,
        reason: 'Sample must include neutral_keypoints.json or input.mp4 in inputs.',
      );
    }

    final sampleOutRoot = Directory(_resolvePath(options.outputRoot, spec.sampleId));
    if (sampleOutRoot.existsSync()) {
      sampleOutRoot.deleteSync(recursive: true);
    }
    sampleOutRoot.createSync(recursive: true);

    final cliArgs = <String>[
      'run',
      options.cliEntry,
    ];

    if (keypointsPath != null) {
      cliArgs.addAll([
        '--keypoints',
        keypointsPath!,
        '--rule',
        options.rulePath,
      ]);
    } else {
      cliArgs.addAll([
        '--engine',
        options.engine,
        '--input',
        videoPath!,
        '--rule',
        options.rulePath,
      ]);
    }

    cliArgs.addAll([
      '--out',
      sampleOutRoot.path,
      '--strictness',
      'relaxed',
      '--evidence',
      '--evidence-config',
      options.evidenceConfigPath,
      '--cue-map',
      options.cueMapPath,
      '--assert',
      '--assert-level',
      'strict',
      '--assert-print',
    ]);

    if (hybridPolicyPath != null || cloudMockPath != null) {
      cliArgs.add('--hybrid');
      if (hybridPolicyPath != null) {
        cliArgs.addAll(['--hybrid-policy', hybridPolicyPath!]);
      }
      if (cloudMockPath != null) {
        cliArgs.addAll(['--cloud-mock', cloudMockPath!]);
      }
    }

    final process = await Process.start(
      options.dartExecutable,
      ['--disable-dart-dev', ...cliArgs],
      workingDirectory: options.cliWorkingDir,
    );

    final stdoutFuture = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) {
      if (options.verbose) {
        stdout.writeln(line);
      }
      return line;
    }).toList();

    final stderrFuture = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .map((line) {
      if (options.verbose) {
        stderr.writeln(line);
      }
      return line;
    }).toList();

    final exitCode = await process.exitCode;
    final cliStdout = await stdoutFuture;
    final cliStderr = await stderrFuture;

    if (exitCode != 0) {
      return SampleRunResult.failure(
        sampleId: spec.sampleId,
        reason: 'CLI exited with code $exitCode',
        stdoutLines: cliStdout,
        stderrLines: cliStderr,
      );
    }

    final resolvedInput = keypointsPath ?? videoPath;
    final inputBase = _basenameWithoutExtension(resolvedInput!);
    final outDir = Directory(_resolvePath(sampleOutRoot.path, inputBase));
    if (!outDir.existsSync()) {
      return SampleRunResult.failure(
        sampleId: spec.sampleId,
        reason: 'Output directory not found: ${outDir.path}',
        stdoutLines: cliStdout,
        stderrLines: cliStderr,
      );
    }

    final producedFiles = <String, File>{};
    final missingOutputs = <String>[];
    for (final expected in spec.expectedOutputs) {
      final file = _locateOutputFile(outDir, expected);
      if (file == null) {
        missingOutputs.add(expected);
      } else {
        producedFiles[expected] = file;
      }
    }

    if (missingOutputs.isNotEmpty) {
      return SampleRunResult.failure(
        sampleId: spec.sampleId,
        reason: 'Missing expected outputs: ${missingOutputs.join(', ')}',
        stdoutLines: cliStdout,
        stderrLines: cliStderr,
      );
    }

    final resultFile = producedFiles['result.json'];
    final perfFile = producedFiles['perf.json'];

    Map<String, dynamic> resultJson;
    try {
      resultJson = jsonDecode(await resultFile!.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      return SampleRunResult.failure(
        sampleId: spec.sampleId,
        reason: 'Failed to parse result.json: $e',
        stdoutLines: cliStdout,
        stderrLines: cliStderr,
      );
    }

    Map<String, dynamic>? perfJson;
    if (perfFile != null) {
      try {
        final decoded = jsonDecode(await perfFile.readAsString());
        if (decoded is Map<String, dynamic>) {
          perfJson = decoded;
        } else {
          return SampleRunResult.failure(
            sampleId: spec.sampleId,
            reason: 'perf.json must be an object.',
            stdoutLines: cliStdout,
            stderrLines: cliStderr,
          );
        }
      } catch (e) {
        return SampleRunResult.failure(
          sampleId: spec.sampleId,
          reason: 'Failed to parse perf.json: $e',
          stdoutLines: cliStdout,
          stderrLines: cliStderr,
        );
      }
    }

    final repCount = _resolveRepCount(resultJson);
    final ruleContext = RuleContext(
      sampleId: spec.sampleId,
      resultJson: resultJson,
      perfJson: perfJson,
      cloudResult: cloudResultData,
      repCount: repCount,
    );

    final ruleFailures = <String>[];
    for (final rule in spec.validationRules) {
      final evaluation = evaluateRule(rule, ruleContext);
      if (!evaluation.passed) {
        final detail = evaluation.details == null
            ? 'Rule "$rule" failed.'
            : 'Rule "$rule" failed: ${evaluation.details}';
        ruleFailures.add(detail);
      }
    }

    if (ruleFailures.isNotEmpty) {
      return SampleRunResult.failure(
        sampleId: spec.sampleId,
        reason: ruleFailures.join('; '),
        stdoutLines: cliStdout,
        stderrLines: cliStderr,
      );
    }

    stdout.writeln('[${spec.sampleId}] ✅ Passed (${spec.validationRules.length} rule(s)).');
    return SampleRunResult.success(
      sampleId: spec.sampleId,
      stdoutLines: cliStdout,
      stderrLines: cliStderr,
    );
  }
}

class SampleSpec {
  SampleSpec({
    required this.sampleId,
    required this.category,
    required this.inputs,
    required this.expectedOutputs,
    required this.validationRules,
  });

  final String sampleId;
  final String category;
  final List<String> inputs;
  final List<String> expectedOutputs;
  final List<String> validationRules;

  factory SampleSpec.fromJson(Map<String, dynamic> json) {
    final sampleId = json['sampleId'] as String?;
    if (sampleId == null || sampleId.isEmpty) {
      throw StateError('Manifest entry missing sampleId.');
    }

    List<String> _stringList(dynamic value) {
      if (value is List) {
        return value.whereType<String>().toList(growable: false);
      }
      return const <String>[];
    }

    return SampleSpec(
      sampleId: sampleId,
      category: json['category'] as String? ?? 'unknown',
      inputs: _stringList(json['inputs']),
      expectedOutputs: _stringList(json['expectedOutputs']),
      validationRules: _stringList(json['validationRules']),
    );
  }
}

class SampleRunResult {
  SampleRunResult._({
    required this.sampleId,
    required this.passed,
    required this.messages,
    required this.stdoutLines,
    required this.stderrLines,
  });

  factory SampleRunResult.success({
    required String sampleId,
    List<String>? stdoutLines,
    List<String>? stderrLines,
  }) {
    return SampleRunResult._(
      sampleId: sampleId,
      passed: true,
      messages: const [],
      stdoutLines: stdoutLines ?? const [],
      stderrLines: stderrLines ?? const [],
    );
  }

  factory SampleRunResult.failure({
    required String sampleId,
    required String reason,
    List<String>? stdoutLines,
    List<String>? stderrLines,
  }) {
    return SampleRunResult._(
      sampleId: sampleId,
      passed: false,
      messages: [reason],
      stdoutLines: stdoutLines ?? const [],
      stderrLines: stderrLines ?? const [],
    );
  }

  final String sampleId;
  final bool passed;
  final List<String> messages;
  final List<String> stdoutLines;
  final List<String> stderrLines;
}

class RuleContext {
  RuleContext({
    required this.sampleId,
    required this.resultJson,
    required this.perfJson,
    required this.cloudResult,
    required this.repCount,
  });

  final String sampleId;
  final Map<String, dynamic> resultJson;
  final Map<String, dynamic>? perfJson;
  final Map<String, dynamic>? cloudResult;
  final int repCount;

  Map<String, dynamic>? get hybrid => resultJson['hybrid'] as Map<String, dynamic>?;

  Map<String, dynamic>? get scores => resultJson['scores'] as Map<String, dynamic>?;

  Map<String, dynamic>? get quality => resultJson['quality'] as Map<String, dynamic>?;

  List<Map<String, dynamic>> get issues =>
      (resultJson['issues'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

  double? get perfRtf {
    final perf = perfJson?['perf'];
    if (perf is Map<String, dynamic>) {
      return _asDouble(perf['pipelineRtf']);
    }
    return _asDouble(perfJson?['rtf']);
  }

  double? get perfMemPeakMb {
    final perf = perfJson?['perf'];
    if (perf is Map<String, dynamic>) {
      return _asDouble(perf['memPeakMB']);
    }
    return _asDouble(perfJson?['memPeakMB']);
  }

  double? get perfInferenceFps {
    final perf = perfJson?['perf'];
    if (perf is Map<String, dynamic>) {
      return _asDouble(perf['inferenceFps']);
    }
    return _asDouble(perfJson?['inferenceFps']);
  }
}

class RuleEvaluation {
  const RuleEvaluation(this.passed, this.details);

  final bool passed;
  final String? details;
}

RuleEvaluation evaluateRule(String rule, RuleContext ctx) {
  final trimmed = rule.trim();
  if (trimmed.startsWith('issues.any(') && trimmed.endsWith(')')) {
    return _evaluateIssuesAny(trimmed, ctx);
  }
  if (trimmed.startsWith('abs(')) {
    return _evaluateAbsRule(trimmed, ctx);
  }

  final match = _comparisonRegex.firstMatch(trimmed);
  if (match == null) {
    return RuleEvaluation(false, 'Unsupported rule syntax.');
  }

  final leftExpr = match.group(1)!;
  final operator = match.group(2)!;
  final rightExpr = match.group(3)!;

  final leftValue = _resolveValue(leftExpr, ctx);
  final rightValue = _resolveValue(rightExpr, ctx);

  final passed = _compareValues(leftValue, rightValue, operator);
  if (passed) {
    return const RuleEvaluation(true, null);
  }
  return RuleEvaluation(
    false,
    'Observed ${_formatValue(leftValue)} $operator ${_formatValue(rightValue)}',
  );
}

RuleEvaluation _evaluateIssuesAny(String rule, RuleContext ctx) {
  final inner = rule.substring('issues.any('.length, rule.length - 1);
  final match = _comparisonRegex.firstMatch(inner.trim());
  if (match == null) {
    return RuleEvaluation(false, 'Invalid issues.any condition.');
  }
  final fieldExpr = match.group(1)!;
  final operator = match.group(2)!;
  final targetExpr = match.group(3)!;
  final targetValue = _resolveValue(targetExpr, ctx);

  if (operator != '==' && operator != '!=') {
    return RuleEvaluation(false, 'issues.any supports == or != only.');
  }

  final fieldPath = fieldExpr.split('.');
  bool matched = false;
  for (final issue in ctx.issues) {
    dynamic current = issue;
    dynamic value;
    for (final segment in fieldPath) {
      if (current is Map<String, dynamic>) {
        value = current[segment];
        current = value is Map<String, dynamic> ? value : null;
      } else {
        value = null;
        break;
      }
    }
    if (_compareValues(value, targetValue, operator)) {
      matched = true;
      break;
    }
  }

  if (matched) {
    return const RuleEvaluation(true, null);
  }

  final availableCodes = ctx.issues.map((e) => e['code']).whereType<String>().toSet().join(', ');
  final detail = availableCodes.isEmpty
      ? 'No issues found.'
      : 'Available issue codes: $availableCodes';
  return RuleEvaluation(false, detail);
}

RuleEvaluation _evaluateAbsRule(String rule, RuleContext ctx) {
  final closeIdx = rule.indexOf(')');
  if (closeIdx == -1) {
    return RuleEvaluation(false, 'Malformed abs() expression.');
  }
  final innerExpr = rule.substring(4, closeIdx);
  final remainder = rule.substring(closeIdx + 1).trim();
  final comparison = _comparisonRegex.firstMatch(remainder);
  if (comparison == null) {
    return RuleEvaluation(false, 'abs() must be followed by a comparison.');
  }
  final operator = comparison.group(2)!;
  final rightExpr = comparison.group(3)!;
  final numeric = _resolveNumericExpression(innerExpr, ctx);
  final rightValueRaw = _resolveValue(rightExpr, ctx);
  final rightValue = rightValueRaw is num ? rightValueRaw.toDouble() : _asDouble(rightValueRaw);
  if (numeric == null || rightValue == null) {
    return RuleEvaluation(false, 'abs() comparison requires numeric operands.');
  }
  final observed = numeric.abs();
  final passed = _compareNumeric(observed, rightValue, operator);
  if (passed) {
    return const RuleEvaluation(true, null);
  }
  return RuleEvaluation(
    false,
    '|${innerExpr.trim()}| = ${_formatValue(observed)} $operator ${_formatValue(rightValue)}',
  );
}

final RegExp _comparisonRegex =
    RegExp(r'^\s*([A-Za-z0-9_.]+)\s*(==|!=|<=|>=|<|>)\s*(.+)\s*$');

dynamic _resolveValue(String expr, RuleContext ctx) {
  final trimmed = expr.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if ((trimmed.startsWith("'") && trimmed.endsWith("'")) ||
      (trimmed.startsWith('"') && trimmed.endsWith('"'))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  if (trimmed == 'true') return true;
  if (trimmed == 'false') return false;
  if (trimmed == 'null') return null;

  final numeric = double.tryParse(trimmed);
  if (numeric != null) {
    return trimmed.contains('.') ? numeric : numeric.toInt();
  }

  if (trimmed == 'repCount') {
    return ctx.repCount;
  }

  if (trimmed.startsWith('perf.')) {
    return _resolvePerfValue(trimmed.substring(5), ctx);
  }

  if (trimmed.startsWith('cloud_result.')) {
    return _dig(ctx.cloudResult, trimmed.substring('cloud_result.'.length).split('.'));
  }

  return _dig(ctx.resultJson, trimmed.split('.'));
}

double? _resolveNumericExpression(String expr, RuleContext ctx) {
  final trimmed = expr.trim();
  final minusIndex = _findTopLevelMinus(trimmed);
  if (minusIndex != null) {
    final leftExpr = trimmed.substring(0, minusIndex);
    final rightExpr = trimmed.substring(minusIndex + 1);
    final leftVal = _resolveValue(leftExpr, ctx);
    final rightVal = _resolveValue(rightExpr, ctx);
    final leftNum = _asDouble(leftVal);
    final rightNum = _asDouble(rightVal);
    if (leftNum == null || rightNum == null) {
      return null;
    }
    return leftNum - rightNum;
  }
  final single = _resolveValue(trimmed, ctx);
  return _asDouble(single);
}

int? _findTopLevelMinus(String expr) {
  var depth = 0;
  for (var i = 0; i < expr.length; i++) {
    final ch = expr[i];
    if (ch == '(') {
      depth += 1;
    } else if (ch == ')') {
      if (depth > 0) {
        depth -= 1;
      }
    } else if (ch == '-' && depth == 0) {
      return i;
    }
  }
  return null;
}

dynamic _resolvePerfValue(String key, RuleContext ctx) {
  switch (key) {
    case 'rtf':
    case 'pipelineRtf':
      return ctx.perfRtf;
    case 'memPeakMB':
      return ctx.perfMemPeakMb;
    case 'inferenceFps':
      return ctx.perfInferenceFps;
    default:
      final segments = key.split('.');
      final perf = ctx.perfJson;
      if (perf == null) {
        return null;
      }
      return _dig(perf, segments);
  }
}

dynamic _dig(dynamic root, List<String> segments) {
  dynamic current = root;
  for (final segment in segments) {
    if (current is Map<String, dynamic>) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}

bool _compareValues(dynamic left, dynamic right, String operator) {
  if (operator == '==' || operator == '!=') {
    final equality = left == right;
    return operator == '==' ? equality : !equality;
  }

  final leftNum = _asDouble(left);
  final rightNum = _asDouble(right);
  if (leftNum == null || rightNum == null) {
    return false;
  }
  return _compareNumeric(leftNum, rightNum, operator);
}

bool _compareNumeric(double left, double right, String operator) {
  switch (operator) {
    case '<':
      return left < right;
    case '<=':
      return left <= right;
    case '>':
      return left > right;
    case '>=':
      return left >= right;
    default:
      return false;
  }
}

double? _asDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  if (value is bool) {
    return value ? 1.0 : 0.0;
  }
  return null;
}

String _formatValue(dynamic value) {
  if (value == null) {
    return 'null';
  }
  if (value is num) {
    return value.toString();
  }
  if (value is bool) {
    return value ? 'true' : 'false';
  }
  return value.toString();
}

int _resolveRepCount(Map<String, dynamic> resultJson) {
  final direct = resultJson['repCount'];
  if (direct is num) {
    return direct.toInt();
  }
  final reps = resultJson['reps'];
  if (reps is List) {
    return reps.length;
  }
  return 0;
}

File? _locateOutputFile(Directory outDir, String fileName) {
  final direct = File(_resolvePath(outDir.path, fileName));
  if (direct.existsSync()) {
    return direct;
  }
  final logsDir = Directory(_resolvePath(outDir.path, 'logs'));
  final logCandidate = File(_resolvePath(logsDir.path, fileName));
  if (logCandidate.existsSync()) {
    return logCandidate;
  }
  return null;
}

String _resolvePath(String base, String relative) {
  final baseUri = Directory(base).uri;
  final normalized = relative.replaceAll('\', '/');
  return baseUri.resolve(normalized).toFilePath();
}

String _basenameWithoutExtension(String path) {
  final normalized = path.replaceAll('\', '/');
  final slash = normalized.lastIndexOf('/');
  final fileName = slash == -1 ? normalized : normalized.substring(slash + 1);
  final dot = fileName.lastIndexOf('.');
  return dot == -1 ? fileName : fileName.substring(0, dot);
}

String _absoluteFilePath(String path) => File(path).absolute.path;

String _absoluteDirPath(String path) => Directory(path).absolute.path;
