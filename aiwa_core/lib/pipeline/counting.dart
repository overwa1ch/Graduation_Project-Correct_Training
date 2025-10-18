import 'dart:math' as math;

class Rep {
  final int startMs, valleyMs, endMs;
  Rep(this.startMs, this.valleyMs, this.endMs);
}

List<Rep> countReps({
  required List<int> tMs,
  required List<double?> kneeL,
  required List<double?> kneeR,
  required int minIntervalMs,
  required int windowMs,
  required num minValleyKneeAngle,
}) {
  final n = tMs.length;
  final mainAngles = List<double?>.generate(n, (i) {
    final l = kneeL[i];
    final r = kneeR[i];
    if (l == null && r == null) return null;
    if (l == null) return r;
    if (r == null) return l;
    return math.min(l, r);
  });

  final reps = <Rep>[];
  int? lastEnd;

  for (var i = 0; i < n; i++) {
    final centerAngle = mainAngles[i];
    if (centerAngle == null) continue;

    final centerTime = tMs[i];
    var left = i;
    while (left > 0 && centerTime - tMs[left - 1] <= windowMs) {
      left--;
    }
    var right = i;
    while (right + 1 < n && tMs[right + 1] - centerTime <= windowMs) {
      right++;
    }
    if (left == i || right == i) continue;

    var hasHigherLeft = false;
    var hasHigherRight = false;
    var strictlyLowerExists = false;

    for (var j = left; j <= right; j++) {
      final v = mainAngles[j];
      if (v == null) continue;
      if (j < i) {
        if (v > centerAngle + 1e-3) hasHigherLeft = true;
        if (v < centerAngle - 1e-3) {
          strictlyLowerExists = true;
          break;
        }
      } else if (j > i) {
        if (v > centerAngle + 1e-3) hasHigherRight = true;
        if (v < centerAngle - 1e-3) {
          strictlyLowerExists = true;
          break;
        }
      }
    }
    if (strictlyLowerExists) continue;
    if (!hasHigherLeft || !hasHigherRight) continue;
    if (centerAngle >= minValleyKneeAngle) continue;

    final startMs = tMs[left];
    final endMs = tMs[right];
    if (lastEnd != null && centerTime - lastEnd < minIntervalMs) continue;

    reps.add(Rep(startMs, centerTime, endMs));
    lastEnd = endMs;
  }

  return reps;
}
