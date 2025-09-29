class PhaseSeg {
  final int startMs, endMs;
  final bool isDown; // true 表示下蹲 (angle decreasing)，false 表示起身 (angle increasing)
  PhaseSeg(this.startMs, this.endMs, this.isDown);
}

List<PhaseSeg> segmentDownUp(List<int> tMs, List<double?> kneeMain,
    {required int minMs}) {
  final samples = <({int t, double angle})>[];
  for (var i = 0; i < kneeMain.length; i++) {
    final angle = kneeMain[i];
    if (angle != null) {
      samples.add((t: tMs[i], angle: angle));
    }
  }
  if (samples.length < 2) {
    return <PhaseSeg>[];
  }

  final segs = <PhaseSeg>[];
  bool? currentDown;
  int? segStart;
  var prev = samples.first;

  for (var i = 1; i < samples.length; i++) {
    final curr = samples[i];
    final diff = curr.angle - prev.angle;
    if (diff.abs() < 1e-3) {
      prev = curr;
      continue;
    }

    final isDown = diff < 0;
    if (currentDown == null) {
      currentDown = isDown;
      segStart = prev.t;
    } else if (isDown != currentDown) {
      final segEnd = prev.t;
      if (segStart != null && segEnd - segStart >= minMs) {
        segs.add(PhaseSeg(segStart, segEnd, currentDown));
      }
      currentDown = isDown;
      segStart = prev.t;
    }

    prev = curr;
  }

  if (currentDown != null) {
    final segEnd = prev.t;
    final start = segStart ?? samples.first.t;
    if (segEnd - start >= minMs) {
      segs.add(PhaseSeg(start, segEnd, currentDown));
    }
  }

  return segs;
}
