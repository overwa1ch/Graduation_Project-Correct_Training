import 'dart:math' as math;

import '../core/errors.dart';
import '../core/perf_timer.dart';
import '../core/rounding.dart';
import '../math/angles.dart';
import '../math/one_euro.dart';
import '../pose/keypoint_names.dart';
import 'pose_series.dart';
import '../result/csv_export.dart';
import '../spec/rule_models.dart';

import 'counting.dart';
import 'phases.dart';
import 'quality.dart';

class OfflinePipeline {
  final RuleSet rules;
  final Strictness strictness;
  OfflinePipeline(this.rules, this.strictness);

  Future<({String anglesCsv, Map<String, dynamic> resultJson})> run(
    PoseSeries series, {
    PerfTimer? timer,
  }) async {
    final frames = series.frames;
    final tMs = frames.map((f) => f.timestampMs).toList(growable: false);

    final filteredPts = _filterKeypoints(series);
    timer?.lap('filtering');
    
    // 🔍 诊断：统计过滤后的关键点检测情况
    _diagnoseFilteredKeypoints(filteredPts, series.frames);
    
    final rawAngles = _computeAngles(filteredPts);
    timer?.lap('angles');

    // 🔍 诊断：统计角度计算结果
    final kneeLValidCount = rawAngles.kneeL.where((v) => v != null).length;
    final kneeRValidCount = rawAngles.kneeR.where((v) => v != null).length;
    final trunkValidCount = rawAngles.trunk.where((v) => v != null).length;
    print('[OfflinePipeline] 🔍 Angle computation results:');
    print('[OfflinePipeline] 🔍   Total frames: ${rawAngles.kneeL.length}');
    print('[OfflinePipeline] 🔍   Left knee valid: $kneeLValidCount (${(kneeLValidCount / rawAngles.kneeL.length * 100).toStringAsFixed(1)}%)');
    print('[OfflinePipeline] 🔍   Right knee valid: $kneeRValidCount (${(kneeRValidCount / rawAngles.kneeR.length * 100).toStringAsFixed(1)}%)');
    print('[OfflinePipeline] 🔍   Trunk valid: $trunkValidCount (${(trunkValidCount / rawAngles.trunk.length * 100).toStringAsFixed(1)}%)');

    final hasAnyKnee = rawAngles.kneeL.any((v) => v != null) ||
        rawAngles.kneeR.any((v) => v != null);
    if (!hasAnyKnee) {
      // 🔍 详细诊断：为什么没有knee angles
      _diagnoseKneeAngleFailure(series.frames, filteredPts, rawAngles);
      throw AngleComputeFailed('No valid knee angles available for analysis.');
    }

    final hasTrunk = rawAngles.trunk.any((v) => v != null);
    if (!hasTrunk) {
      // 🔍 详细诊断：为什么没有trunk angles
      _diagnoseTrunkAngleFailure(series.frames, filteredPts, rawAngles);
      throw AngleComputeFailed('No valid trunk angles available for analysis.');
    }

    final angles = _smoothAngles(series.fps, rawAngles);

    final rows = <List<num?>>[];
    for (var i = 0; i < frames.length; i++) {
      rows.add([
        frames[i].timestampMs,
        angles.kneeL[i],
        angles.kneeR[i],
        angles.trunk[i],
      ]);
    }
    final anglesCsv = buildAnglesCsv(rows);

    final mainKnee = List<double?>.generate(frames.length, (i) {
      final l = angles.kneeL[i];
      final r = angles.kneeR[i];
      if (l == null && r == null) return null;
      if (l == null) return r;
      if (r == null) return l;
      return math.min(l, r);
    }, growable: false);

    if (mainKnee.every((element) => element == null)) {
      throw AngleComputeFailed('Unable to derive primary knee angle track.');
    }

    final minPhaseMs = (rules.phases['minMs'] as num?)?.toInt() ?? 250;
    final phaseSegs = segmentDownUp(tMs, mainKnee, minMs: minPhaseMs);
    timer?.lap('phaseSeg');

    final counts = rules.counts;
    final minIntervalMs = (counts['minIntervalMs'] as num?)?.toInt() ?? 600;
    final windowMs = (counts['windowMs'] as num?)?.toInt() ?? 150;
    final strictProfile = (rules.strictness[strictness.value] as Map?) ??
        const <String, dynamic>{};
    final minValley = (strictProfile['minValleyKneeAngle'] as num?) ??
        (strictness == Strictness.strict ? 80 : 90);
    final detectionThreshold = (strictProfile['detectionThreshold'] as num?) ??
        (strictness == Strictness.strict ? 100 : 120);

    final reps = countReps(
      tMs: tMs,
      kneeL: angles.kneeL,
      kneeR: angles.kneeR,
      minIntervalMs: minIntervalMs,
      windowMs: windowMs,
      minValleyKneeAngle: minValley,
      detectionThreshold: detectionThreshold,
    );
    timer?.lap('scoring');

    final qualifiedReps = reps.where((rep) => rep.qualified).toList();

    final quality = computeQualityFromKeypoints(frames);
    timer?.lap('quality');

    final metrics = rules.metrics;
    final depthSpec = (metrics['depth'] as Map)['kneeAngleMin'] as Map;
    final depthStrict = (depthSpec['strict'] as num).toDouble();
    final depthRelaxed = (depthSpec['relaxed'] as num).toDouble();
    final depthIssueThreshold =
        strictness == Strictness.strict ? depthStrict : depthRelaxed;

    final valgusSpec = metrics['valgus'] as Map;
    final kneeOutSpec = valgusSpec['kneeOutAngleMin'] as Map;
    final kneeOutStrict = (kneeOutSpec['strict'] as num).toDouble();
    final kneeOutRelaxed = (kneeOutSpec['relaxed'] as num).toDouble();
    final valgusIssueThreshold =
        strictness == Strictness.strict ? kneeOutStrict : kneeOutRelaxed;
    final valgusWindowMs = (valgusSpec['windowMs'] as num?)?.toInt() ?? 200;

    final trunkSpec = (metrics['trunk'] as Map)['maxForwardLean'] as Map;
    final trunkStrict = (trunkSpec['strict'] as num).toDouble();
    final trunkRelaxed = (trunkSpec['relaxed'] as num).toDouble();
    final trunkIssueThreshold =
        strictness == Strictness.strict ? trunkStrict : trunkRelaxed;

    final tempoSpec = metrics['tempo'] as Map;
    final tempoEccentric = (tempoSpec['eccentricMs'] as List)
        .map((e) => (e as num).toDouble())
        .toList();
    final tempoRatio =
        (tempoSpec['ratio'] as List).map((e) => (e as num).toDouble()).toList();

    final allRepMetrics = reps.isEmpty
        ? <_RepMetrics>[]
        : _collectRepMetrics(
            tMs: tMs,
            mainKnee: mainKnee,
            reps: reps,
            trunk: angles.trunk,
            filteredPts: filteredPts,
            valgusWindowMs: valgusWindowMs,
          );

    final qualifiedRepMetrics = <_RepMetrics>[];
    for (var i = 0; i < reps.length; i++) {
      if (reps[i].qualified && i < allRepMetrics.length) {
        qualifiedRepMetrics.add(allRepMetrics[i]);
      }
    }

    final repSummaries = reps.asMap().entries.map((entry) {
      final idx = entry.key;
      final rep = entry.value;
      final metric = idx < allRepMetrics.length ? allRepMetrics[idx] : null;
      return {
        'index': idx + 1,
        'startMs': rep.startMs,
        'valleyMs': rep.valleyMs,
        'endMs': rep.endMs,
        'qualified': rep.qualified,
        'valleyAngle': round1(rep.valleyAngle),
        if (metric != null) ...{
          'kneeValleyAngle': round1(metric.kneeValleyAngle),
          'minKneeOutAngle': round1(metric.minKneeOutAngle),
          'maxForwardLean': round1(metric.maxForwardLean),
          'tempo': {
            'eccentricMs': metric.eccentricMs,
            'concentricMs': metric.concentricMs,
            'ratio': _round2(metric.ratio),
          },
        },
      };
    }).toList();

    final evidence = <Map<String, dynamic>>[
      ...phaseSegs.map((seg) => {
            'type': seg.isDown ? 'phaseDown' : 'phaseUp',
            'startMs': seg.startMs,
            'endMs': seg.endMs,
          }),
      ...repSummaries.map((rep) => {
            'type': 'rep',
            ...rep,
          }),
    ];

    final issuesCollector = _IssueAccumulator(evidence);

    if (qualifiedRepMetrics.isNotEmpty) {
      var qualifiedIndex = 0;
      for (var i = 0;
          i < reps.length && qualifiedIndex < qualifiedRepMetrics.length;
          i++) {
        final rep = reps[i];
        if (!rep.qualified) continue;
        final metric = qualifiedRepMetrics[qualifiedIndex++];
        if (metric.kneeValleyAngle > depthIssueThreshold + 1e-6) {
          issuesCollector.add(
            code: 'DEPTH_INSUFFICIENT',
            frameMs: rep.valleyMs,
            severity: 'major',
            measured: metric.kneeValleyAngle,
            higherIsWorse: true,
          );
        }
        if (metric.minKneeOutAngle < valgusIssueThreshold - 1e-6) {
          issuesCollector.add(
            code: 'KNEE_VALGUS',
            frameMs: rep.valleyMs,
            severity: 'major',
            measured: metric.minKneeOutAngle,
            higherIsWorse: false,
          );
        }
        if (metric.maxForwardLean > trunkIssueThreshold + 1e-6) {
          issuesCollector.add(
            code: 'TRUNK_LEAN_EXCESSIVE',
            frameMs: rep.valleyMs,
            severity: 'moderate',
            measured: metric.maxForwardLean,
            higherIsWorse: true,
          );
        }
      }
    }

    final issues = issuesCollector.toList();

    final weights = rules.scoreWeights;
    print('[OfflinePipeline] 📊 Computing scores: strictness=${strictness.value}');
    print('[OfflinePipeline] 📊 reps.length=${reps.length}, qualifiedRepMetrics.length=${qualifiedRepMetrics.length}');
    
    final scores = qualifiedRepMetrics.isEmpty
        ? (() {
            print('[OfflinePipeline] 📊 Using _computeScoresNoReps (no qualified reps)');
            final computed = _computeScoresNoReps(
              mainKnee: mainKnee,
              trunk: angles.trunk,
              trunkThreshold:
                  strictness == Strictness.strict ? trunkStrict : trunkRelaxed,
              allReps: reps,
              depthTarget: minValley.toDouble(),
              detectionThreshold: detectionThreshold.toDouble(),
              tempoEccentric: tempoEccentric,
              tempoRatio: tempoRatio,
              weights: weights,
            );
            print('[OfflinePipeline] 📊 _computeScoresNoReps result: $computed');
            return computed;
          })()
        : (() {
            print('[OfflinePipeline] 📊 Using _computeScores (${qualifiedRepMetrics.length} qualified reps)');
            final computed = _computeScores(
              repMetrics: qualifiedRepMetrics,
              depthStrict: depthStrict,
              depthRelaxed: depthRelaxed,
              trunkStrict: trunkStrict,
              trunkRelaxed: trunkRelaxed,
              kneeOutStrict: kneeOutStrict,
              kneeOutRelaxed: kneeOutRelaxed,
              tempoEccentric: tempoEccentric,
              tempoRatio: tempoRatio,
              weights: weights,
            );
            print('[OfflinePipeline] 📊 _computeScores result: $computed');
            return computed;
          })();

    final feedback = _generateFeedback(
      strictness: strictness,
      allReps: reps,
      qualifiedReps: qualifiedReps,
      targetAngle: minValley.toDouble(),
      detectionThreshold: detectionThreshold.toDouble(),
    );

    print('[OfflinePipeline] 📝 Building resultJson');
    print('[OfflinePipeline] 📝 meta.strictness: ${strictness.value}');
    print('[OfflinePipeline] 📝 scores to write: $scores');
    
    final resultJson = <String, dynamic>{
      'meta': {
        'template': rules.template,
        'fps': series.fps,
        'ruleVersion': rules.version,
        'strictness': strictness.value,
        if (series.metadata.engine != null) 'engine': series.metadata.engine,
        if (series.metadata.engineVersion != null)
          'engineVersion': series.metadata.engineVersion,
        if (series.metadata.inputResolution != null)
          'inputResolution': series.metadata.inputResolution,
        if (series.metadata.samplingStride != null)
          'samplingStride': series.metadata.samplingStride,
      },
      'quality': {
        'coverage': quality.coverage,
        'lowConfidence': quality.lowConfidence,
      },
      'repCount': qualifiedReps.length,
      'attemptsCount': reps.length,
      'reps': repSummaries,
      'scores': scores,
      'issues': issues,
      'evidence': evidence,
    };

    if (feedback != null) {
      resultJson['feedback'] = feedback;
    }

    return (anglesCsv: anglesCsv, resultJson: resultJson);
  }
}

Map<String, dynamic>? _generateFeedback({
  required Strictness strictness,
  required List<Rep> allReps,
  required List<Rep> qualifiedReps,
  required double targetAngle,
  required double detectionThreshold,
}) {
  final attemptsTotal = allReps.length;
  final attemptsQualified = qualifiedReps.length;
  final attemptsUnqualified = attemptsTotal - attemptsQualified;

  if (attemptsTotal == 0) {
    return {
      'mode': strictness.value,
      'attempts': {
        'total': 0,
        'qualified': 0,
        'unqualified': 0,
      },
      'suggestions': [
        'No squat motion detected.',
        'Ensure your full body is visible and perform at least one complete squat during recording.',
      ],
    };
  }

  final avgAngle =
      allReps.map((rep) => rep.valleyAngle).reduce((a, b) => a + b) /
          attemptsTotal;

  final feedback = <String, dynamic>{
    'mode': strictness.value,
    'attempts': {
      'total': attemptsTotal,
      'qualified': attemptsQualified,
      'unqualified': attemptsUnqualified,
    },
    'avgAngle': round1(avgAngle),
    'targetAngle': targetAngle,
    'detectionThreshold': detectionThreshold,
  };

  final suggestions = <String>[];
  final toneRelaxed = strictness == Strictness.relaxed;

  if (attemptsQualified == 0) {
    final gap = avgAngle - targetAngle;
    suggestions.add(
      'Depth insufficient: average squat depth is ${round1(avgAngle)}°, target is under ${targetAngle.toInt()}°.',
    );
    if (toneRelaxed) {
      suggestions.add(
          'Try sitting your hips back a little more, as if reaching for a low chair.');
      suggestions.add(
          'Slow down the descent and pause briefly at the bottom to build confidence.');
    } else {
      suggestions.add(
          'Drive the knees forward slightly and keep lowering the hips until thighs are parallel to the floor.');
      suggestions.add(
          'Focus on stability—maintain a proud chest and keep heels grounded as you reach depth.');
    }
    if (gap > 0) {
      suggestions.add(
          'You only need to lower roughly ${gap.toInt()}° further to hit the target.');
    }
  } else if (attemptsQualified == attemptsTotal) {
    suggestions.add(
        'Great work! Every attempt met the ${strictness.value} depth requirement.');
    if (toneRelaxed) {
      suggestions.add(
          'Consider switching to strict mode to challenge yourself with an 80° depth goal.');
    } else {
      suggestions.add(
          'Maintain this consistency and watch for knee tracking and trunk control to keep improving.');
    }
  } else {
    final unqualifiedAngles = allReps
        .where((rep) => !rep.qualified)
        .map((rep) => rep.valleyAngle)
        .toList();
    final avgUnqualified = unqualifiedAngles.isEmpty
        ? null
        : unqualifiedAngles.reduce((a, b) => a + b) / unqualifiedAngles.length;
    suggestions.add(
      '${attemptsQualified} attempts met the target, ${attemptsUnqualified} still need work.',
    );
    if (avgUnqualified != null) {
      final gap = avgUnqualified - targetAngle;
      suggestions.add(
        'On the missed reps you averaged ${round1(avgUnqualified)}°, about ${gap.toInt()}° shy of the goal.',
      );
    }
    if (toneRelaxed) {
      suggestions.add(
          'Stay patient—focus on repeating the successful reps and gradually deepen the remaining attempts.');
    } else {
      suggestions.add(
          'Study your successful reps and replicate that depth—keep hips traveling down and back without collapsing the chest.');
    }
  }

  feedback['suggestions'] = suggestions;
  return feedback;
}

class _RepMetrics {
  final double kneeValleyAngle;
  final double minKneeOutAngle;
  final double maxForwardLean;
  final int eccentricMs;
  final int concentricMs;
  final double ratio;

  const _RepMetrics({
    required this.kneeValleyAngle,
    required this.minKneeOutAngle,
    required this.maxForwardLean,
    required this.eccentricMs,
    required this.concentricMs,
    required this.ratio,
  });
}

class _IssueAccumulator {
  final Map<String, _IssueSummary> _issues = {};
  final List<Map<String, dynamic>> _evidence;

  _IssueAccumulator(this._evidence);

  void add({
    required String code,
    required int frameMs,
    required String severity,
    double? measured,
    required bool higherIsWorse,
  }) {
    final summary =
        _issues.putIfAbsent(code, () => _IssueSummary(code, severity));
    summary.frames.add(frameMs);
    if (measured != null) {
      summary.updateWorst(measured, higherIsWorse: higherIsWorse);
    }
    _evidence.add({
      'type': 'issue',
      'code': code,
      'frameMs': frameMs,
      if (measured != null) 'value': round1(measured),
    });
  }

  List<Map<String, dynamic>> toList() {
    return _issues.values.map((e) => e.toJson()).toList();
  }
}

class _IssueSummary {
  final String code;
  final String severity;
  final List<int> frames = [];
  double? _worst;

  _IssueSummary(this.code, this.severity);

  void updateWorst(double measured, {required bool higherIsWorse}) {
    if (_worst == null) {
      _worst = measured;
      return;
    }
    if (higherIsWorse) {
      _worst = math.max(_worst!, measured);
    } else {
      _worst = math.min(_worst!, measured);
    }
  }

  Map<String, dynamic> toJson() {
    final sortedFrames = [...frames]..sort();
    return {
      'code': code,
      'frames': sortedFrames,
      'severity': severity,
      if (_worst != null) 'worst': round1(_worst!),
    };
  }
}

List<_RepMetrics> _collectRepMetrics({
  required List<int> tMs,
  required List<double?> mainKnee,
  required List<Rep> reps,
  required List<double?> trunk,
  required List<Map<String, _PoseCoord?>> filteredPts,
  required int valgusWindowMs,
}) {
  final indexByTime = <int, int>{};
  for (var i = 0; i < tMs.length; i++) {
    indexByTime[tMs[i]] = i;
  }

  final results = <_RepMetrics>[];

  for (var i = 0; i < reps.length; i++) {
    final rep = reps[i];
    final valleyAngle = _angleAt(mainKnee, tMs, rep.valleyMs);
    if (valleyAngle == null) {
      throw MetricsComputeFailed(
          'Missing knee angle at valley for rep ${i + 1}.');
    }

    final indices = _indicesBetween(tMs, rep.startMs, rep.endMs);
    if (indices.isEmpty) {
      throw MetricsComputeFailed('No frames covering rep interval ${i + 1}.');
    }

    double? maxTrunk;
    double? minKneeOut;

    for (final idx in indices) {
      final trunkAngle = trunk[idx];
      if (trunkAngle != null) {
        maxTrunk =
            maxTrunk == null ? trunkAngle : math.max(maxTrunk, trunkAngle);
      }
    }

    final halfWindow = (valgusWindowMs / 2).round();
    final windowStart = math.max(rep.startMs, rep.valleyMs - halfWindow);
    final windowEnd = math.min(rep.endMs, rep.valleyMs + halfWindow);
    var valgusIndices = _indicesBetween(tMs, windowStart, windowEnd);
    if (valgusIndices.isEmpty) {
      final valleyIdx = indexByTime[rep.valleyMs];
      if (valleyIdx != null) {
        valgusIndices = [valleyIdx];
      }
    }

    for (final idx in valgusIndices) {
      final pts = filteredPts[idx];
      final left = _kneeOutAngle(pts, kLeftHip, kLeftKnee, kLeftAnkle);
      final right = _kneeOutAngle(pts, kRightHip, kRightKnee, kRightAnkle);
      final candidates = <double>[];
      if (left != null) candidates.add(left);
      if (right != null) candidates.add(right);
      if (candidates.isEmpty) continue;
      final frameMin = candidates.reduce(math.min);
      minKneeOut =
          minKneeOut == null ? frameMin : math.min(minKneeOut, frameMin);
    }

    if (maxTrunk == null) {
      throw MetricsComputeFailed(
          'Unable to determine trunk angle for rep ${i + 1}.');
    }
    if (minKneeOut == null) {
      throw MetricsComputeFailed(
          'Unable to determine knee valgus for rep ${i + 1}.');
    }

    final eccentricMs = rep.valleyMs - rep.startMs;
    final concentricMs = rep.endMs - rep.valleyMs;
    if (eccentricMs <= 0 || concentricMs <= 0) {
      throw MetricsComputeFailed('Invalid tempo window for rep ${i + 1}.');
    }
    final ratio = eccentricMs / concentricMs;

    results.add(_RepMetrics(
      kneeValleyAngle: valleyAngle,
      minKneeOutAngle: minKneeOut,
      maxForwardLean: maxTrunk,
      eccentricMs: eccentricMs,
      concentricMs: concentricMs,
      ratio: ratio,
    ));
  }

  return results;
}

double _round2(double value) => ((value * 100).roundToDouble()) / 100.0;

List<int> _indicesBetween(List<int> tMs, int start, int end) {
  final out = <int>[];
  for (var i = 0; i < tMs.length; i++) {
    final t = tMs[i];
    if (t >= start && t <= end) {
      out.add(i);
    }
  }
  return out;
}

Map<String, double> _computeScores({
  required List<_RepMetrics> repMetrics,
  required double depthStrict,
  required double depthRelaxed,
  required double trunkStrict,
  required double trunkRelaxed,
  required double kneeOutStrict,
  required double kneeOutRelaxed,
  required List<double> tempoEccentric,
  required List<double> tempoRatio,
  required Map<String, num> weights,
}) {
  double scoreDepth(_RepMetrics m) => _scoreFromBounds(
        value: m.kneeValleyAngle,
        a: depthStrict,
        b: depthRelaxed,
        lowerIsBetter: true,
      );
  double scoreTrunk(_RepMetrics m) => _scoreFromBounds(
        value: m.maxForwardLean,
        a: trunkStrict,
        b: trunkRelaxed,
        lowerIsBetter: true,
      );
  double scoreValgus(_RepMetrics m) => _scoreFromBounds(
        value: m.minKneeOutAngle,
        a: kneeOutStrict,
        b: kneeOutRelaxed,
        lowerIsBetter: false,
      );

  final depthScores = repMetrics.map(scoreDepth).toList();
  final trunkScores = repMetrics.map(scoreTrunk).toList();
  final valgusScores = repMetrics.map(scoreValgus).toList();

  final formScore = _average([_average(depthScores), _average(trunkScores)]);
  final stabilityScore = _average(valgusScores);

  final avgEccentric =
      _average(repMetrics.map((m) => m.eccentricMs.toDouble()).toList());
  final avgRatio = _average(repMetrics.map((m) => m.ratio).toList());
  final tempoScoreEcc = _scoreRange(
    value: avgEccentric,
    min: tempoEccentric[0],
    max: tempoEccentric[1],
  );
  final tempoScoreRatio = _scoreRange(
    value: avgRatio,
    min: tempoRatio[0],
    max: tempoRatio[1],
  );
  final tempoScore = _average([tempoScoreEcc, tempoScoreRatio]);

  double weight(String key) => (weights[key] ?? 0).toDouble();

  final overall = formScore * weight('form') +
      stabilityScore * weight('stability') +
      tempoScore * weight('tempo');

  return {
    'form': _roundScore(formScore),
    'stability': _roundScore(stabilityScore),
    'tempo': _roundScore(tempoScore),
    'overall': _roundScore(overall),
  };
}

Map<String, double> _computeScoresNoReps({
  required List<double?> mainKnee,
  required List<double?> trunk,
  required double trunkThreshold,
  required List<Rep> allReps,
  required double depthTarget,
  required double detectionThreshold,
  required List<double> tempoEccentric,
  required List<double> tempoRatio,
  required Map<String, num> weights,
}) {
  final trunkValues = trunk.whereType<double>().toList();
  final maxTrunk =
      trunkValues.isEmpty ? 0.0 : trunkValues.reduce((a, b) => a > b ? a : b);
  final trunkDeficit = math.max(0.0, maxTrunk - trunkThreshold);
  final trunkScore = _clampScore(100.0 - (trunkDeficit * 1.5));

  double depthScore = 100.0;
  if (allReps.isNotEmpty) {
    final avgValley =
        allReps.map((rep) => rep.valleyAngle).reduce((a, b) => a + b) /
            allReps.length;
    final minSeparation = 5.0;
    final effectiveDetection = detectionThreshold <= depthTarget + minSeparation
        ? depthTarget + minSeparation
        : detectionThreshold;
    depthScore = _scoreFromBounds(
      value: avgValley,
      a: depthTarget,
      b: effectiveDetection,
      lowerIsBetter: true,
    );
  }

  final form = _average([depthScore, trunkScore]);

  final kneeValues = mainKnee.whereType<double>().toList();
  double stabilityPenalty = 0.0;
  if (mainKnee.length >= 5 && kneeValues.isNotEmpty) {
    final mean = kneeValues.reduce((a, b) => a + b) / kneeValues.length;
    final variance =
        kneeValues.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            kneeValues.length;
    final stdDev = math.sqrt(variance);
    stabilityPenalty = stdDev * 2.0;
  }
  final stability = _clampScore(100.0 - stabilityPenalty);

  double tempoScore = 100.0;
  if (allReps.isNotEmpty) {
    final eccentricDurations = allReps
        .map((rep) => (rep.valleyMs - rep.startMs).toDouble())
        .where((value) => value > 0)
        .toList();

    final ratios = <double>[];
    for (var i = 0; i < allReps.length; i++) {
      final ecc = allReps[i].valleyMs - allReps[i].startMs;
      final conc = allReps[i].endMs - allReps[i].valleyMs;
      if (ecc > 0 && conc > 0) {
        ratios.add(ecc / conc);
      }
    }

    if (eccentricDurations.isNotEmpty) {
      final avgEccentric = _average(eccentricDurations);
      final tempoScoreEcc = _scoreRange(
        value: avgEccentric,
        min: tempoEccentric[0],
        max: tempoEccentric[1],
      );

      final avgRatio = ratios.isNotEmpty ? _average(ratios) : null;
      final tempoScoreRatio = avgRatio == null
          ? 100.0
          : _scoreRange(
              value: avgRatio,
              min: tempoRatio[0],
              max: tempoRatio[1],
            );
      tempoScore = _average([tempoScoreEcc, tempoScoreRatio]);
    }
  }

  double weight(String key) => (weights[key] ?? 0).toDouble();
  final overall = form * weight('form') +
      stability * weight('stability') +
      tempoScore * weight('tempo');

  return {
    'form': _roundScore(form),
    'stability': _roundScore(stability),
    'tempo': _roundScore(tempoScore),
    'overall': _roundScore(overall),
  };
}

double _roundScore(double value) => ((value * 10).roundToDouble()) / 10.0;

double _scoreFromBounds({
  required double value,
  required double a,
  required double b,
  required bool lowerIsBetter,
}) {
  final best = lowerIsBetter ? math.min(a, b) : math.max(a, b);
  final worst = lowerIsBetter ? math.max(a, b) : math.min(a, b);

  if ((best - worst).abs() < 1e-6) {
    final meets = lowerIsBetter ? value <= best : value >= best;
    return meets ? 100.0 : 0.0;
  }

  if (lowerIsBetter) {
    if (value <= best) return 100.0;
    if (value >= worst) return 0.0;
    final ratio = (value - best) / (worst - best);
    return _clampScore((1 - ratio) * 100.0);
  } else {
    if (value >= best) return 100.0;
    if (value <= worst) return 0.0;
    final ratio = (value - worst) / (best - worst);
    return _clampScore(ratio * 100.0);
  }
}

double _scoreRange(
    {required double value, required double min, required double max}) {
  var low = min;
  var high = max;
  if (low > high) {
    final tmp = low;
    low = high;
    high = tmp;
  }

  if ((high - low).abs() < 1e-6) {
    return (value - low).abs() < 1e-6 ? 100.0 : 0.0;
  }

  if (value >= low && value <= high) {
    return 100.0;
  }

  final span = high - low;
  if (value < low) {
    final diff = low - value;
    return _clampScore((1 - diff / span) * 100.0);
  } else {
    final diff = value - high;
    return _clampScore((1 - diff / span) * 100.0);
  }
}

double _clampScore(double v) => math.max(0.0, math.min(100.0, v));

double _average(List<double> values) {
  if (values.isEmpty) {
    return 0.0;
  }
  final sum = values.reduce((a, b) => a + b);
  return sum / values.length;
}

({List<double?> kneeL, List<double?> kneeR, List<double?> trunk}) _smoothAngles(
  double fps,
  ({List<double?> kneeL, List<double?> kneeR, List<double?> trunk}) raw,
) {
  final kneeL = <double?>[];
  final kneeR = <double?>[];
  final trunk = <double?>[];

  final step = 1.0 / fps;
  var kneeLT = 0.0;
  var kneeRT = 0.0;
  var trunkT = 0.0;

  final kneeLFilter = OneEuroFilter(minCutoff: 1.0, beta: 0.005, dCutoff: 1.0);
  final kneeRFilter = OneEuroFilter(minCutoff: 1.0, beta: 0.005, dCutoff: 1.0);
  final trunkFilter = OneEuroFilter(minCutoff: 1.0, beta: 0.005, dCutoff: 1.0);

  for (var i = 0; i < raw.kneeL.length; i++) {
    final left = raw.kneeL[i];
    if (left != null) {
      kneeL.add(kneeLFilter.filter(kneeLT, left));
      kneeLT += step;
    } else {
      kneeL.add(null);
    }

    final right = raw.kneeR[i];
    if (right != null) {
      kneeR.add(kneeRFilter.filter(kneeRT, right));
      kneeRT += step;
    } else {
      kneeR.add(null);
    }

    final trunkValue = raw.trunk[i];
    if (trunkValue != null) {
      trunk.add(trunkFilter.filter(trunkT, trunkValue));
      trunkT += step;
    } else {
      trunk.add(null);
    }
  }

  return (kneeL: kneeL, kneeR: kneeR, trunk: trunk);
}

({List<double?> kneeL, List<double?> kneeR, List<double?> trunk})
    _computeAngles(List<Map<String, _PoseCoord?>> filteredPts) {
  final kneeL = <double?>[];
  final kneeR = <double?>[];
  final trunk = <double?>[];

  for (final pts in filteredPts) {
    kneeL.add(_kneeAngle(pts, kLeftHip, kLeftKnee, kLeftAnkle));
    kneeR.add(_kneeAngle(pts, kRightHip, kRightKnee, kRightAnkle));
    trunk.add(_trunkAngle(pts));
  }

  return (kneeL: kneeL, kneeR: kneeR, trunk: trunk);
}

class _PoseCoord {
  final double x;
  final double y;
  const _PoseCoord(this.x, this.y);
}

double? _kneeAngle(
    Map<String, _PoseCoord?> pts, String hip, String knee, String ankle) {
  try {
    final hipPt = pts[hip];
    final kneePt = pts[knee];
    final anklePt = pts[ankle];
    if (hipPt == null || kneePt == null || anklePt == null) {
      return null;
    }
    final hipV = V2(hipPt.x, hipPt.y);
    final kneeV = V2(kneePt.x, kneePt.y);
    final ankleV = V2(anklePt.x, anklePt.y);
    return angleABC(hipV, kneeV, ankleV);
  } catch (_) {
    return null;
  }
}

double? _kneeOutAngle(
    Map<String, _PoseCoord?> pts, String hip, String knee, String ankle) {
  try {
    final hipPt = pts[hip];
    final kneePt = pts[knee];
    final anklePt = pts[ankle];
    if (hipPt == null || kneePt == null || anklePt == null) {
      return null;
    }
    final thigh = V2(kneePt.x - hipPt.x, kneePt.y - hipPt.y);
    final shank = V2(anklePt.x - kneePt.x, anklePt.y - kneePt.y);
    final thighDeg = _angleFromVertical(thigh);
    final shankDeg = _angleFromVertical(shank);
    return (thighDeg + shankDeg) / 2.0;
  } catch (_) {
    return null;
  }
}

double? _trunkAngle(Map<String, _PoseCoord?> pts) {
  try {
    final leftShoulder = pts[kLeftShoulder];
    final rightShoulder = pts[kRightShoulder];
    final leftHip = pts[kLeftHip];
    final rightHip = pts[kRightHip];
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return null;
    }
    final shoulder = V2(
      (leftShoulder.x + rightShoulder.x) / 2.0,
      (leftShoulder.y + rightShoulder.y) / 2.0,
    );
    final hip = V2(
      (leftHip.x + rightHip.x) / 2.0,
      (leftHip.y + rightHip.y) / 2.0,
    );
    return trunkAngle(shoulder, hip);
  } catch (_) {
    return null;
  }
}

double _angleFromVertical(V2 v) {
  final n = math.sqrt(v.x * v.x + v.y * v.y);
  if (n == 0) throw StateError('Zero-length vector');
  final cosv = (v.y / n).clamp(-1.0, 1.0);
  final deg = math.acos(cosv) * 180.0 / math.pi;
  return deg <= 90 ? deg : 180 - deg;
}

List<Map<String, _PoseCoord?>> _filterKeypoints(PoseSeries series) {
  final frameCount = series.frames.length;
  final trackedNames = {
    ...kPoseSeriesRequiredJoints,
  };

  final rawTracks = {
    for (final name in trackedNames) name: <_PoseCoord?>[],
  };

  for (final frame in series.frames) {
    for (final entry in rawTracks.entries) {
      final name = entry.key;
      final kp = frame.keypoints[name];
      if (kp != null && kp.isReliable) {
        entry.value.add(_PoseCoord(kp.x, kp.y));
      } else {
        entry.value.add(null);
      }
    }
  }

  final interpolated = {
    for (final entry in rawTracks.entries)
      entry.key: _interpolateCoords(entry.value, maxGap: 3),
  };

  final filteredTracks = {
    for (final entry in interpolated.entries)
      entry.key: _applyOneEuro(entry.value, series.fps),
  };

  final frames = List.generate(
    frameCount,
    (_) => <String, _PoseCoord?>{},
    growable: false,
  );

  for (final entry in filteredTracks.entries) {
    final name = entry.key;
    final track = entry.value;
    for (var i = 0; i < track.length; i++) {
      frames[i][name] = track[i];
    }
  }

  return frames;
}

/// 诊断过滤后的关键点检测情况
void _diagnoseFilteredKeypoints(
  List<Map<String, _PoseCoord?>> filteredPts,
  List<PoseFrame> originalFrames,
) {
  if (filteredPts.isEmpty) {
    print('[OfflinePipeline] 🔍 ⚠️  No filtered points available');
    return;
  }

  final requiredJoints = [kLeftHip, kLeftKnee, kLeftAnkle, kRightHip, kRightKnee, kRightAnkle];
  final stats = <String, int>{};
  
  for (final joint in requiredJoints) {
    stats[joint] = 0;
  }

  // 统计过滤后的关键点
  for (final pts in filteredPts) {
    for (final joint in requiredJoints) {
      if (pts[joint] != null) {
        stats[joint] = (stats[joint] ?? 0) + 1;
      }
    }
  }

  // 统计原始关键点的置信度
  final originalStats = <String, Map<String, dynamic>>{};
  for (final joint in requiredJoints) {
    originalStats[joint] = {'detected': 0, 'reliable': 0, 'totalScore': 0.0};
  }

  for (final frame in originalFrames) {
    for (final joint in requiredJoints) {
      final kp = frame.keypoints[joint];
      if (kp != null) {
        originalStats[joint]!['detected'] = (originalStats[joint]!['detected'] as int) + 1;
        originalStats[joint]!['totalScore'] = (originalStats[joint]!['totalScore'] as double) + kp.score;
        if (kp.isReliable) {
          originalStats[joint]!['reliable'] = (originalStats[joint]!['reliable'] as int) + 1;
        }
      }
    }
  }

  print('[OfflinePipeline] 🔍 Filtered keypoints statistics:');
  print('[OfflinePipeline] 🔍   Total frames: ${filteredPts.length}');
  for (final joint in requiredJoints) {
    final filteredCount = stats[joint] ?? 0;
    final filteredPercent = (filteredCount / filteredPts.length * 100).toStringAsFixed(1);
    final orig = originalStats[joint]!;
    final origDetected = orig['detected'] as int;
    final origReliable = orig['reliable'] as int;
    final avgScore = origDetected > 0 ? (orig['totalScore'] as double) / origDetected : 0.0;
    final reliablePercent = originalFrames.isNotEmpty ? (origReliable / originalFrames.length * 100).toStringAsFixed(1) : '0.0';
    
    print('[OfflinePipeline] 🔍   $joint:');
    print('[OfflinePipeline] 🔍     Original: detected=$origDetected/${originalFrames.length}, reliable=$origReliable (${reliablePercent}%), avgScore=${avgScore.toStringAsFixed(3)}');
    print('[OfflinePipeline] 🔍     Filtered: $filteredCount/${filteredPts.length} (${filteredPercent}%)');
  }
}

/// 诊断knee角度计算失败的原因
void _diagnoseKneeAngleFailure(
  List<PoseFrame> frames,
  List<Map<String, _PoseCoord?>> filteredPts,
  ({List<double?> kneeL, List<double?> kneeR, List<double?> trunk}) rawAngles,
) {
  print('[OfflinePipeline] 🔍 ⚠️  Knee angle computation failure diagnosis:');
  print('[OfflinePipeline] 🔍   Total frames: ${frames.length}');
  print('[OfflinePipeline] 🔍   Left knee angles: ${rawAngles.kneeL.where((v) => v != null).length}/${rawAngles.kneeL.length} valid');
  print('[OfflinePipeline] 🔍   Right knee angles: ${rawAngles.kneeR.where((v) => v != null).length}/${rawAngles.kneeR.length} valid');
  
  // 检查前5个失败的帧
  int failureSampleCount = 0;
  const maxSamples = 5;
  
  for (var i = 0; i < filteredPts.length && failureSampleCount < maxSamples; i++) {
    final pts = filteredPts[i];
    final leftKneeAngle = rawAngles.kneeL[i];
    final rightKneeAngle = rawAngles.kneeR[i];
    
    if (leftKneeAngle == null && rightKneeAngle == null) {
      failureSampleCount++;
      final frame = i < frames.length ? frames[i] : null;
      final missingLeft = <String>[];
      final missingRight = <String>[];
      
      if (pts[kLeftHip] == null) missingLeft.add('leftHip');
      if (pts[kLeftKnee] == null) missingLeft.add('leftKnee');
      if (pts[kLeftAnkle] == null) missingLeft.add('leftAnkle');
      
      if (pts[kRightHip] == null) missingRight.add('rightHip');
      if (pts[kRightKnee] == null) missingRight.add('rightKnee');
      if (pts[kRightAnkle] == null) missingRight.add('rightAnkle');
      
      print('[OfflinePipeline] 🔍   Frame $i failure:');
      if (frame != null) {
        final leftHipKp = frame.keypoints[kLeftHip];
        final leftKneeKp = frame.keypoints[kLeftKnee];
        final leftAnkleKp = frame.keypoints[kLeftAnkle];
        final rightHipKp = frame.keypoints[kRightHip];
        final rightKneeKp = frame.keypoints[kRightKnee];
        final rightAnkleKp = frame.keypoints[kRightAnkle];
        
        print('[OfflinePipeline] 🔍     Left side: hip=${leftHipKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${leftHipKp?.isReliable ?? false}), knee=${leftKneeKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${leftKneeKp?.isReliable ?? false}), ankle=${leftAnkleKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${leftAnkleKp?.isReliable ?? false})');
        print('[OfflinePipeline] 🔍     Right side: hip=${rightHipKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${rightHipKp?.isReliable ?? false}), knee=${rightKneeKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${rightKneeKp?.isReliable ?? false}), ankle=${rightAnkleKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${rightAnkleKp?.isReliable ?? false})');
      }
      print('[OfflinePipeline] 🔍     Missing after filter: left=[${missingLeft.join(", ")}], right=[${missingRight.join(", ")}]');
    }
  }
}

/// 诊断trunk角度计算失败的原因
void _diagnoseTrunkAngleFailure(
  List<PoseFrame> frames,
  List<Map<String, _PoseCoord?>> filteredPts,
  ({List<double?> kneeL, List<double?> kneeR, List<double?> trunk}) rawAngles,
) {
  print('[OfflinePipeline] 🔍 ⚠️  Trunk angle computation failure diagnosis:');
  print('[OfflinePipeline] 🔍   Total frames: ${frames.length}');
  print('[OfflinePipeline] 🔍   Trunk angles: ${rawAngles.trunk.where((v) => v != null).length}/${rawAngles.trunk.length} valid');
  
  // 检查前5个失败的帧
  int failureSampleCount = 0;
  const maxSamples = 5;
  
  for (var i = 0; i < filteredPts.length && failureSampleCount < maxSamples; i++) {
    final pts = filteredPts[i];
    final trunkAngle = rawAngles.trunk[i];
    
    if (trunkAngle == null) {
      failureSampleCount++;
      final frame = i < frames.length ? frames[i] : null;
      final missing = <String>[];
      
      if (pts[kLeftShoulder] == null) missing.add('leftShoulder');
      if (pts[kRightShoulder] == null) missing.add('rightShoulder');
      if (pts[kLeftHip] == null) missing.add('leftHip');
      if (pts[kRightHip] == null) missing.add('rightHip');
      
      print('[OfflinePipeline] 🔍   Frame $i failure:');
      if (frame != null) {
        final leftShoulderKp = frame.keypoints[kLeftShoulder];
        final rightShoulderKp = frame.keypoints[kRightShoulder];
        final leftHipKp = frame.keypoints[kLeftHip];
        final rightHipKp = frame.keypoints[kRightHip];
        
        print('[OfflinePipeline] 🔍     Left shoulder: ${leftShoulderKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${leftShoulderKp?.isReliable ?? false})');
        print('[OfflinePipeline] 🔍     Right shoulder: ${rightShoulderKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${rightShoulderKp?.isReliable ?? false})');
        print('[OfflinePipeline] 🔍     Left hip: ${leftHipKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${leftHipKp?.isReliable ?? false})');
        print('[OfflinePipeline] 🔍     Right hip: ${rightHipKp?.score.toStringAsFixed(3) ?? "null"} (reliable=${rightHipKp?.isReliable ?? false})');
      }
      print('[OfflinePipeline] 🔍     Missing after filter: [${missing.join(", ")}]');
    }
  }
}

List<_PoseCoord?> _interpolateCoords(List<_PoseCoord?> values,
    {required int maxGap}) {
  final result = List<_PoseCoord?>.from(values);
  var index = 0;
  while (index < result.length) {
    if (result[index] != null) {
      index++;
      continue;
    }

    final gapStart = index;
    while (index < result.length && result[index] == null) {
      index++;
    }
    final gapEnd = index - 1;
    final gapLength = gapEnd - gapStart + 1;

    int? prevIdx = gapStart - 1;
    while (prevIdx != null && prevIdx >= 0 && result[prevIdx] == null) {
      prevIdx--;
    }
    if (prevIdx != null && prevIdx < 0) {
      prevIdx = null;
    }

    int? nextIdx = index;
    while (
        nextIdx != null && nextIdx < result.length && result[nextIdx] == null) {
      nextIdx++;
    }
    if (nextIdx != null && nextIdx >= result.length) {
      nextIdx = null;
    }

    if (prevIdx == null || nextIdx == null || gapLength > maxGap) {
      continue;
    }

    final start = result[prevIdx]!;
    final end = result[nextIdx]!;
    final span = nextIdx - prevIdx;
    for (var offset = 1; offset <= gapLength; offset++) {
      final ratio = offset / span;
      final x = start.x + (end.x - start.x) * ratio;
      final y = start.y + (end.y - start.y) * ratio;
      result[gapStart + offset - 1] = _PoseCoord(x, y);
    }
  }

  return result;
}

List<_PoseCoord?> _applyOneEuro(List<_PoseCoord?> values, double fps) {
  if (fps <= 0) {
    return List<_PoseCoord?>.from(values);
  }

  final filterX = OneEuroFilter(minCutoff: 1.0, beta: 0.01, dCutoff: 1.0);
  final filterY = OneEuroFilter(minCutoff: 1.0, beta: 0.01, dCutoff: 1.0);
  final result = List<_PoseCoord?>.from(values);

  for (var i = 0; i < values.length; i++) {
    final sample = values[i];
    if (sample == null) {
      result[i] = null;
      continue;
    }
    final t = i / fps;
    final fx = filterX.filter(t, sample.x);
    final fy = filterY.filter(t, sample.y);
    result[i] = _PoseCoord(fx, fy);
  }

  return result;
}

double? _angleAt(List<double?> angles, List<int> tMs, int targetMs) {
  for (var i = 0; i < angles.length; i++) {
    if (tMs[i] == targetMs) {
      return angles[i];
    }
  }
  return null;
}
