import '../pose/keypoint_names.dart';

class PoseLandmark {
  final double x;
  final double y;
  final double? z;
  final double score;

  const PoseLandmark({
    required this.x,
    required this.y,
    required this.score,
    this.z,
  });

  bool get isReliable => score >= 0.5;
}

class PoseFrame {
  final int index;
  final int timestampMs;
  final bool lowConfidence;
  final Map<String, PoseLandmark> keypoints;

  const PoseFrame({
    required this.index,
    required this.timestampMs,
    required this.lowConfidence,
    required this.keypoints,
  });
}

class PoseSeriesMetadata {
  final String? engine;
  final String? engineVersion;
  final String? inputResolution;
  final int? samplingStride;
  final int? width;
  final int? height;
  final bool? mirrorApplied;

  const PoseSeriesMetadata({
    this.engine,
    this.engineVersion,
    this.inputResolution,
    this.samplingStride,
    this.width,
    this.height,
    this.mirrorApplied,
  });
}

class PoseSeries {
  final double fps;
  final List<PoseFrame> frames;
  final PoseSeriesMetadata metadata;

  const PoseSeries({
    required this.fps,
    required this.frames,
    required this.metadata,
  });
}

const List<String> kPoseSeriesRequiredJoints = [
  kLeftHip,
  kRightHip,
  kLeftKnee,
  kRightKnee,
  kLeftAnkle,
  kRightAnkle,
  kLeftShoulder,
  kRightShoulder,
];
