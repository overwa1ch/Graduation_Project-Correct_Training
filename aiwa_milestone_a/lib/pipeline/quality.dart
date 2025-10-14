import 'pose_series.dart';

class Quality {
  final double coverage; // 三位小数
  final bool lowConfidence;
  const Quality(this.coverage, this.lowConfidence);
}

Quality computeQualityFromKeypoints(List<PoseFrame> frames) {
  const requiredJoints = {
    'leftHip',
    'rightHip',
    'leftKnee',
    'rightKnee',
    'leftAnkle',
    'rightAnkle',
  };

  final total = frames.length;
  var ok = 0;
  for (final frame in frames) {
    var validCount = 0;
    for (final joint in requiredJoints) {
      final kp = frame.keypoints[joint];
      if (kp != null && kp.isReliable) {
        validCount++;
      }
    }
    if (validCount == requiredJoints.length) {
      ok++;
    }
  }
  final cov = total == 0 ? 0.0 : ok / total;
  final coverage = ((cov * 1000).roundToDouble() / 1000.0); // 三位小数
  final low = cov < 0.7; // v1.1 冻结阈值
  return Quality(coverage, low);
}
