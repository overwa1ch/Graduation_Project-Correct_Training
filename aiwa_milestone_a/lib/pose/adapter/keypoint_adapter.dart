// lib/pose/adapter/keypoint_adapter.dart
//
// 关键点适配器：把“模型私有语义” → “中立语义”
// 里程碑 B 先支持 BlazePose 33（ML Kit），并输出统一命名。
// 文档要求：Keypoint Adapter 统一输出，包含名称、坐标、置信度【见进度同步文档】
//
// 注意：名称采用驼峰风格，与离线管线一致（如 nose、leftEye、rightHip、leftFootIndex）。

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../pose_engine.dart';

/// MLKit 33 点 → 中立语义名称映射
/// 备注：ML Kit 的 PoseLandmarkType 包含 33 个点（鼻、眼、耳、口角、肩肘腕、髋膝踝、脚跟/脚指、拇指/食指/小指）。
/// 该映射仅负责“名称统一”，不改变坐标系与尺度。
const Map<PoseLandmarkType, String> _mlkitTypeToNeutralName = {
  PoseLandmarkType.nose: 'nose',

  PoseLandmarkType.leftEyeInner: 'leftEyeInner',
  PoseLandmarkType.leftEye: 'leftEye',
  PoseLandmarkType.leftEyeOuter: 'leftEyeOuter',

  PoseLandmarkType.rightEyeInner: 'rightEyeInner',
  PoseLandmarkType.rightEye: 'rightEye',
  PoseLandmarkType.rightEyeOuter: 'rightEyeOuter',

  PoseLandmarkType.leftEar: 'leftEar',
  PoseLandmarkType.rightEar: 'rightEar',

  PoseLandmarkType.leftMouth: 'leftMouth',
  PoseLandmarkType.rightMouth: 'rightMouth',

  PoseLandmarkType.leftShoulder: 'leftShoulder',
  PoseLandmarkType.rightShoulder: 'rightShoulder',

  PoseLandmarkType.leftElbow: 'leftElbow',
  PoseLandmarkType.rightElbow: 'rightElbow',

  PoseLandmarkType.leftWrist: 'leftWrist',
  PoseLandmarkType.rightWrist: 'rightWrist',

  PoseLandmarkType.leftPinky: 'leftPinky',
  PoseLandmarkType.rightPinky: 'rightPinky',

  PoseLandmarkType.leftIndex: 'leftIndex',
  PoseLandmarkType.rightIndex: 'rightIndex',

  PoseLandmarkType.leftThumb: 'leftThumb',
  PoseLandmarkType.rightThumb: 'rightThumb',

  PoseLandmarkType.leftHip: 'leftHip',
  PoseLandmarkType.rightHip: 'rightHip',

  PoseLandmarkType.leftKnee: 'leftKnee',
  PoseLandmarkType.rightKnee: 'rightKnee',

  PoseLandmarkType.leftAnkle: 'leftAnkle',
  PoseLandmarkType.rightAnkle: 'rightAnkle',

  PoseLandmarkType.leftHeel: 'leftHeel',
  PoseLandmarkType.rightHeel: 'rightHeel',

  PoseLandmarkType.leftFootIndex: 'leftFootIndex',
  PoseLandmarkType.rightFootIndex: 'rightFootIndex',
};

const List<PoseLandmarkType> _mlkitLandmarkOrder = [
  PoseLandmarkType.nose,
  PoseLandmarkType.leftEyeInner,
  PoseLandmarkType.leftEye,
  PoseLandmarkType.leftEyeOuter,
  PoseLandmarkType.rightEyeInner,
  PoseLandmarkType.rightEye,
  PoseLandmarkType.rightEyeOuter,
  PoseLandmarkType.leftEar,
  PoseLandmarkType.rightEar,
  PoseLandmarkType.leftMouth,
  PoseLandmarkType.rightMouth,
  PoseLandmarkType.leftShoulder,
  PoseLandmarkType.rightShoulder,
  PoseLandmarkType.leftElbow,
  PoseLandmarkType.rightElbow,
  PoseLandmarkType.leftWrist,
  PoseLandmarkType.rightWrist,
  PoseLandmarkType.leftPinky,
  PoseLandmarkType.rightPinky,
  PoseLandmarkType.leftIndex,
  PoseLandmarkType.rightIndex,
  PoseLandmarkType.leftThumb,
  PoseLandmarkType.rightThumb,
  PoseLandmarkType.leftHip,
  PoseLandmarkType.rightHip,
  PoseLandmarkType.leftKnee,
  PoseLandmarkType.rightKnee,
  PoseLandmarkType.leftAnkle,
  PoseLandmarkType.rightAnkle,
  PoseLandmarkType.leftHeel,
  PoseLandmarkType.rightHeel,
  PoseLandmarkType.leftFootIndex,
  PoseLandmarkType.rightFootIndex,
];

const int kMlKitNeutralKeypointCount = _mlkitLandmarkOrder.length;

/// 将 ML Kit 的 Pose → List<NeutralKeypoint>
/// - 会做坐标归一化（x/width, y/height）
/// - 可选筛除低置信度点
// lib/pose/adapter/keypoint_adapter.dart 里的函数直接替换这个版本
List<NeutralKeypoint> adaptMlKitPose({
  required Pose pose,
  required int width,
  required int height,
  required bool keepZ,
  required double minScore,
  required bool returnEmptyWhenLow,
}) {
  final List<NeutralKeypoint> out = [];
  final int w = (width <= 0) ? 1 : width;
  final int h = (height <= 0) ? 1 : height;

  for (final type in _mlkitLandmarkOrder) {
    final landmark = pose.landmarks[type];
    if (landmark == null) continue;

    final neutralName = _mlkitTypeToNeutralName[type];
    if (neutralName == null) continue;

    final double s = landmark.likelihood.clamp(0.0, 1.0).toDouble();
    if (s < minScore) {
      continue;
    }

    out.add(NeutralKeypoint(
      name: neutralName,
      x: (landmark.x / w).clamp(0.0, 1.0),
      y: (landmark.y / h).clamp(0.0, 1.0),
      z: keepZ ? landmark.z : null,
      score: s,
    ));
  }

  if (out.isEmpty && !returnEmptyWhenLow) {
    for (final type in _mlkitLandmarkOrder) {
      final landmark = pose.landmarks[type];
      if (landmark == null) continue;

      final neutralName = _mlkitTypeToNeutralName[type];
      if (neutralName == null) continue;

      out.add(NeutralKeypoint(
        name: neutralName,
        x: (landmark.x / w).clamp(0.0, 1.0),
        y: (landmark.y / h).clamp(0.0, 1.0),
        z: keepZ ? landmark.z : null,
        score: landmark.likelihood.clamp(0.0, 1.0).toDouble(),
      ));
    }
  }

  return out;
}
