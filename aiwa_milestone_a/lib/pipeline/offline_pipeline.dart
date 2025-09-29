import 'dart:math' as math;

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
    final angles = _computeAngles(filteredPts);

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

    final repSummaries = reps.asMap().entries.map((entry) {
      final idx = entry.key;
      final rep = entry.value;
      final valleyAngle = _angleAt(mainKnee, tMs, rep.valleyMs);
      return {
        'index': idx + 1,
        'startMs': rep.startMs,
        'valleyMs': rep.valleyMs,
        'endMs': rep.endMs,
        if (valleyAngle != null) 'kneeValleyAngle': round1(valleyAngle),
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
      'scores': {
        'overall': 0.0,
        'form': 0.0,
        'stability': 0.0,
        'tempo': 0.0,
      },
      'issues': <Map<String, dynamic>>[],
      'evidence': evidence,
    };

    return (anglesCsv: anglesCsv, resultJson: resultJson);
  }
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
    return round1(angleABC(hip, knee, ankle));
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
    return round1((left + right) / 2.0);
  }
  final value = left ?? right;
  return value == null ? null : round1(value);
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
