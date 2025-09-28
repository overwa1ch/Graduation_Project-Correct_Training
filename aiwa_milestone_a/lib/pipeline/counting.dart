class Rep { final int startMs, valleyMs, endMs; Rep(this.startMs,this.valleyMs,this.endMs); }

List<Rep> countReps({
  required List<int> tMs,
  required List<double?> kneeL,
  required List<double?> kneeR,
  required int minIntervalMs,
  required int windowMs,
  required num minValleyKneeAngle, // 按 strict/relaxed 选择
}) {
  // knee_main = min(kneeL, kneeR)（若一侧缺测则取另一侧；两侧皆缺测则该点无效）
  // 在 Down→Up 窗口内寻找谷值，判定谷值 < minValleyKneeAngle 即计数
  // ……（实现略，遵循 v1.1）
  return <Rep>[];
}
