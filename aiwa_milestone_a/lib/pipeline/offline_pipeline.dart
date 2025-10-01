import 'dart:math' as math;

import '../core/errors.dart';
import '../core/rounding.dart';
import '../math/angles.dart';
import '../math/one_euro.dart';
import '../pose/kp_models.dart';
import '../pose/movenet17_adapter.dart';
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
      KeypointSeries kp) async {
    final frames = kp.frames;
    final tMs = frames.map((f) => f.tMs).toList(growable: false);

    final filteredPts = _filterKeypoints(frames);
    final rawAngles = _computeAngles(filteredPts);

    final hasAnyKnee = rawAngles.kneeL.any((v) => v != null) ||
        rawAngles.kneeR.any((v) => v != null);
    if (!hasAnyKnee) {
      throw AngleComputeFailed('No valid knee angles available for analysis.');
    }

    final hasTrunk = rawAngles.trunk.any((v) => v != null);
    if (!hasTrunk) {
      throw AngleComputeFailed('No valid trunk angles available for analysis.');
    }

    final angles = _smoothAngles(kp.fps, rawAngles);

    final rows = <List<num?>>[];
    for (var i = 0; i < frames.length; i++) {
      rows.add([
        frames[i].tMs,
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

    final counts = rules.counts;
    final minIntervalMs = (counts['minIntervalMs'] as num?)?.toInt() ?? 600;
    final windowMs = (counts['windowMs'] as num?)?.toInt() ?? 150;
    final strictProfile =
        (rules.strictness[strictness.value] as Map?) ?? const <String, dynamic>{};
    final minValley =
        (strictProfile['minValleyKneeAngle'] as num?) ?? (strictness == Strictness.strict ? 80 : 90);

    final reps = countReps(
      tMs: tMs,
      kneeL: angles.kneeL,
      kneeR: angles.kneeR,
      minIntervalMs: minIntervalMs,
      windowMs: windowMs,
      minValleyKneeAngle: minValley,
    );

    final quality = computeQualityFromKeypoints(
        frames.map((f) => f.pts.map((e) => e.cast<num>()).toList()).toList());

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
    final tempoRatio = (tempoSpec['ratio'] as List)
        .map((e) => (e as num).toDouble())
        .toList();

    final repMetrics = reps.isEmpty
        ? <_RepMetrics>[]
        : _collectRepMetrics(
            tMs: tMs,
            mainKnee: mainKnee,
            reps: reps,
            trunk: angles.trunk,
            filteredPts: filteredPts,
            valgusWindowMs: valgusWindowMs,
          );

    final repSummaries = reps.asMap().entries.map((entry) {
      final idx = entry.key;
      final rep = entry.value;
      final metric = repMetrics[idx];
      return {
        'index': idx + 1,
        'startMs': rep.startMs,
        'valleyMs': rep.valleyMs,
        'endMs': rep.endMs,
        'kneeValleyAngle': round1(metric.kneeValleyAngle),
        'minKneeOutAngle': round1(metric.minKneeOutAngle),
        'maxForwardLean': round1(metric.maxForwardLean),
        'tempo': {
          'eccentricMs': metric.eccentricMs,
          'concentricMs': metric.concentricMs,
          'ratio': _round2(metric.ratio),
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

    if (repMetrics.isNotEmpty) {
      for (var i = 0; i < repMetrics.length; i++) {
        final metric = repMetrics[i];
        final rep = reps[i];
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
    final scores = repMetrics.isEmpty
        ? _computeScoresNoReps(
            mainKnee: mainKnee,
            trunk: angles.trunk,
            trunkThreshold:
                strictness == Strictness.strict ? trunkStrict : trunkRelaxed,
            weights: weights,
          )
        : _computeScores(
            repMetrics: repMetrics,
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

    final resultJson = <String, dynamic>{
      'meta': {
        'template': rules.template,
        'fps': kp.fps,
        'ruleVersion': rules.version,
        'strictness': strictness.value,
      },
      'quality': {
        'coverage': quality.coverage,
        'lowConfidence': quality.lowConfidence,
      },
      'repCount': reps.length,
      'reps': repSummaries,
      'scores': scores,
      'issues': issues,
      'evidence': evidence,
    };

    return (anglesCsv: anglesCsv, resultJson: resultJson);
  }
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
    final summary = _issues.putIfAbsent(code, () => _IssueSummary(code, severity));
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
  required List<List<List<double>>> filteredPts,
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
      throw MetricsComputeFailed('Missing knee angle at valley for rep ${i + 1}.');
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
        maxTrunk = maxTrunk == null ? trunkAngle : math.max(maxTrunk!, trunkAngle);
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
      final left = _kneeOutAngle(pts, L_HIP, L_KNEE, L_ANKLE);
      final right = _kneeOutAngle(pts, R_HIP, R_KNEE, R_ANKLE);
      final candidates = <double>[];
      if (left != null) candidates.add(left);
      if (right != null) candidates.add(right);
      if (candidates.isEmpty) continue;
      final frameMin = candidates.reduce(math.min);
      minKneeOut = minKneeOut == null ? frameMin : math.min(minKneeOut!, frameMin);
    }

    if (maxTrunk == null) {
      throw MetricsComputeFailed('Unable to determine trunk angle for rep ${i + 1}.');
    }
    if (minKneeOut == null) {
      throw MetricsComputeFailed('Unable to determine knee valgus for rep ${i + 1}.');
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

  final avgEccentric = _average(repMetrics.map((m) => m.eccentricMs.toDouble()).toList());
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
  required Map<String, num> weights,
}) {
  final trunkValues = trunk.whereType<double>().toList();
  final maxTrunk = trunkValues.isEmpty
      ? 0.0
      : trunkValues.reduce((a, b) => a > b ? a : b);
  final trunkDeficit = math.max(0.0, maxTrunk - trunkThreshold);
  // Without detected reps we cannot measure depth coverage against valleys, so
  // the depth component stays neutral while trunk lean still reduces the form
  // score, matching the baseline fallback behavior.
  final form = _clampScore(100.0 - (trunkDeficit * 1.5));

  final kneeValues = mainKnee.whereType<double>().toList();
  double stabilityPenalty = 0.0;
  if (mainKnee.length >= 5 && kneeValues.isNotEmpty) {
    final mean = kneeValues.reduce((a, b) => a + b) / kneeValues.length;
    final variance = kneeValues
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        kneeValues.length;
    final stdDev = math.sqrt(variance);
    stabilityPenalty = stdDev * 2.0;
  }
  final stability = _clampScore(100.0 - stabilityPenalty);

  // No repetitions means no tempo measurement; treat as perfect tempo per
  // baseline behavior.
  const tempo = 100.0;

  double weight(String key) => (weights[key] ?? 0).toDouble();
  final overall = form * weight('form') +
      stability * weight('stability') +
      tempo * weight('tempo');

  return {
    'form': _roundScore(form),
    'stability': _roundScore(stability),
    'tempo': _roundScore(tempo),
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

double _scoreRange({required double value, required double min, required double max}) {
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

({List<double?> kneeL, List<double?> kneeR, List<double?> trunk}) _computeAngles(
    List<List<List<double>>> filteredPts) {
  final kneeL = <double?>[];
  final kneeR = <double?>[];
  final trunk = <double?>[];

  for (final pts in filteredPts) {
    kneeL.add(_kneeAngle(pts, L_HIP, L_KNEE, L_ANKLE));
    kneeR.add(_kneeAngle(pts, R_HIP, R_KNEE, R_ANKLE));
    trunk.add(_trunkAngle(pts));
  }

  return (kneeL: kneeL, kneeR: kneeR, trunk: trunk);
}

bool _valid(List<List<double>> pts, int idx) => pts[idx][2] > 0.0;

double? _kneeAngle(List<List<double>> pts, int hipIdx, int kneeIdx, int ankleIdx) {
  if (!_valid(pts, hipIdx) || !_valid(pts, kneeIdx) || !_valid(pts, ankleIdx)) {
    return null;
  }
  final hip = V2(pts[hipIdx][0], pts[hipIdx][1]);
  final knee = V2(pts[kneeIdx][0], pts[kneeIdx][1]);
  final ankle = V2(pts[ankleIdx][0], pts[ankleIdx][1]);
  try {
    return angleABC(hip, knee, ankle);
  } catch (_) {
    return null;
  }
}

double? _kneeOutAngle(
    List<List<double>> pts, int hipIdx, int kneeIdx, int ankleIdx) {
  if (!_valid(pts, hipIdx) || !_valid(pts, kneeIdx) || !_valid(pts, ankleIdx)) {
    return null;
  }
  final hip = V2(pts[hipIdx][0], pts[hipIdx][1]);
  final knee = V2(pts[kneeIdx][0], pts[kneeIdx][1]);
  final ankle = V2(pts[ankleIdx][0], pts[ankleIdx][1]);
  try {
    final thigh = V2(knee.x - hip.x, knee.y - hip.y);
    final shank = V2(ankle.x - knee.x, ankle.y - knee.y);
    final thighDeg = _angleFromVertical(thigh);
    final shankDeg = _angleFromVertical(shank);
    return (thighDeg + shankDeg) / 2.0;
  } catch (_) {
    return null;
  }
}

double? _trunkAngle(List<List<double>> pts) {
  double? single(int shoulderIdx, int hipIdx) {
    if (!_valid(pts, shoulderIdx) || !_valid(pts, hipIdx)) {
      return null;
    }
    final shoulder = V2(pts[shoulderIdx][0], pts[shoulderIdx][1]);
    final hip = V2(pts[hipIdx][0], pts[hipIdx][1]);
    try {
      return trunkAngle(shoulder, hip);
    } catch (_) {
      return null;
    }
  }

  final left = single(L_SHOULDER, L_HIP_IDX);
  final right = single(R_SHOULDER, R_HIP_IDX);
  if (left != null && right != null) {
    return (left + right) / 2.0;
  }
  final value = left ?? right;
  return value;
}

double _angleFromVertical(V2 v) {
  final n = math.sqrt(v.x * v.x + v.y * v.y);
  if (n == 0) throw StateError('Zero-length vector');
  final cosv = (v.y / n).clamp(-1.0, 1.0);
  final deg = math.acos(cosv) * 180.0 / math.pi;
  return deg <= 90 ? deg : 180 - deg;
}

List<List<List<double>>> _filterKeypoints(List<KPFrame> frames) {
  const kpCount = 17;
  final filters = List.generate(
      kpCount, (_) => (x: OneEuroFilter(), y: OneEuroFilter()));

  final smoothed = <List<List<double>>>[];
  for (final frame in frames) {
    final tSec = frame.tMs / 1000.0;
    final pts = <List<double>>[];
    for (var i = 0; i < kpCount; i++) {
      final raw = frame.pts[i];
      final score = raw[2];
      if (score <= 0) {
        pts.add([raw[0].toDouble(), raw[1].toDouble(), score.toDouble()]);
        continue;
      }
      final fx = filters[i].x.filter(tSec, raw[0].toDouble());
      final fy = filters[i].y.filter(tSec, raw[1].toDouble());
      pts.add([fx, fy, score.toDouble()]);
    }
    smoothed.add(pts);
  }
  return smoothed;
}

double? _angleAt(List<double?> angles, List<int> tMs, int targetMs) {
  for (var i = 0; i < angles.length; i++) {
    if (tMs[i] == targetMs) {
      return angles[i];
    }
  }
  return null;
}
