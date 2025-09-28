class Quality {
  final double coverage; // 三位小数
  final bool lowConfidence;
  const Quality(this.coverage, this.lowConfidence);
}

// v1.1：覆盖率= 以“帧级关键点可用性”为准（与角度是否成功计算解耦）
// framesPts: List<frame> where frame = List<List<num>>  // [[x,y,score]*17]
Quality computeQualityFromKeypoints(List<List<List<num>>> framesPts) {
  const L_HIP = 11, R_HIP = 12, L_KNEE = 13, R_KNEE = 14, L_ANKLE = 15, R_ANKLE = 16;

  bool valid(List<List<num>> pts, int idx) => pts[idx][2] > 0.0; // v1.1 冻结

  final total = framesPts.length;
  var ok = 0;
  for (final pts in framesPts) {
    final good =
        valid(pts, L_HIP)  && valid(pts, R_HIP) &&
        valid(pts, L_KNEE) && valid(pts, R_KNEE) &&
        valid(pts, L_ANKLE)&& valid(pts, R_ANKLE);
    if (good) ok++;
  }
  final cov = total == 0 ? 0.0 : ok / total;
  final coverage = ((cov * 1000).roundToDouble() / 1000.0); // 三位小数
  final low = cov < 0.7; // v1.1 冻结阈值
  return Quality(coverage, low);
}
