class PhaseSeg {
  final int startMs, endMs;
  PhaseSeg(this.startMs, this.endMs);
}

// 简化：基于 knee_main 一阶差分方向 + minMs=250（或规则覆盖）
List<PhaseSeg> segmentDownUp(List<int> tMs, List<double?> kneeMain, {required int minMs}) {
  // 生成 Down 与 Up 的时间段，确保每段持续 ≥ minMs（缺测帧不改变趋势，直接跳过）
  // ……（实现略，按 v1.1 口径）
  return <PhaseSeg>[];
}
