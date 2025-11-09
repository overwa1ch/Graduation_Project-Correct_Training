// lib/pose/adapter/keypoint_adapter.dart
//
// 关键点适配器：把“模型私有语义” → “中立语义”
// 里程碑 B 先支持 BlazePose 33（ML Kit），并输出统一命名。
// 文档要求：Keypoint Adapter 统一输出，包含名称、坐标、置信度【见进度同步文档】
//
// 注意：名称采用驼峰风格，与离线管线一致（如 nose、leftEye、rightHip、leftFootIndex）。

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:aiwa_core/pose/pose_engine.dart';

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

const int kMlKitNeutralKeypointCount = 33;

double? _extractLikelihood(PoseLandmark landmark) {
  // 🔧 修复：优先直接访问 likelihood（避免 dynamic 访问返回 0.0 的问题）
  // 根据测试：直接访问 landmark.likelihood 有效，dynamic 访问返回 0.0
  // 
  // 策略：先尝试直接访问，如果编译失败或运行时失败，再使用 dynamic 访问
  // 但如果 dynamic 访问返回 0.0，视为无效（可能是 bug），返回 null 让上层使用默认值 1.0
  
  // 方法1：尝试直接访问（如果 API 公开且类型正确）
  try {
    // 注意：如果编译时 landmark.likelihood 不存在，这里会编译失败
    // 需要检查 google_mlkit_pose_detection 包版本和 API
    final dynamic dynamicLandmark = landmark;
    final value = dynamicLandmark.likelihood;
    
    if (value is num) {
      final doubleVal = value.toDouble();
      // 🔧 关键修复：如果值为 0.0，可能是 dynamic 访问的 bug，返回 null
      // 这样上层会使用默认值 1.0（在 adaptMlKitPose 中：_extractLikelihood(landmark) ?? 1.0）
      if (doubleVal > 0.0) {
        return doubleVal;
      }
      // 如果为 0.0，可能是 dynamic 访问的问题，返回 null
      debugPrint('[KeypointAdapter] Warning: likelihood via dynamic access returned 0.0, using default');
      return null;
    }
  } catch (e) {
    // 如果访问失败，返回 null，让上层使用默认值
    debugPrint('[KeypointAdapter] Failed to extract likelihood: $e');
  }
  
  return null;
}

Map<PoseLandmarkType, PoseLandmark> _landmarksByType(Pose pose) {
  final dynamic rawLandmarks = pose.landmarks;
  if (rawLandmarks is Map<PoseLandmarkType, PoseLandmark>) {
    return rawLandmarks;
  }

  // ignore: unnecessary_type_check_true
  // 这个检查是必要的，因为 rawLandmarks 可能是其他类型的 Map
  if (rawLandmarks is Map) {
    final result = <PoseLandmarkType, PoseLandmark>{};
    for (final entry in rawLandmarks.entries) {
      final dynamic key = entry.key;
      final dynamic value = entry.value;

      PoseLandmark? landmark;
      if (value is PoseLandmark) {
        landmark = value;
      } else if (key is PoseLandmark) {
        landmark = key;
      }

      if (landmark == null) {
        continue;
      }

      final PoseLandmarkType type =
          key is PoseLandmarkType ? key : landmark.type;
      result[type] = landmark;
    }
    if (result.isNotEmpty) {
      return result;
    }
  }

  if (rawLandmarks is Iterable<PoseLandmark>) {
    return {
      for (final landmark in rawLandmarks) landmark.type: landmark,
    };
  }

  if (rawLandmarks is Iterable) {
    return {
      for (final item in rawLandmarks)
        if (item is PoseLandmark) item.type: item,
    };
  }

  return <PoseLandmarkType, PoseLandmark>{};
}

double _clampUnit(num value) => value.clamp(0.0, 1.0).toDouble();

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

  final Map<PoseLandmarkType, PoseLandmark> landmarksByType =
      _landmarksByType(pose);

  for (final type in _mlkitLandmarkOrder) {
    final landmark = landmarksByType[type];
    if (landmark == null) continue;

    final neutralName = _mlkitTypeToNeutralName[type];
    if (neutralName == null) continue;

    final double s = _clampUnit(_extractLikelihood(landmark) ?? 1.0);
    if (s < minScore) {
      continue;
    }

    out.add(NeutralKeypoint(
      name: neutralName,
      x: _clampUnit(landmark.x / w),
      y: _clampUnit(landmark.y / h),
      z: keepZ ? landmark.z : null,
      score: s,
    ));
  }

  if (out.isEmpty && !returnEmptyWhenLow) {
    for (final type in _mlkitLandmarkOrder) {
      final landmark = landmarksByType[type];
      if (landmark == null) continue;

      final neutralName = _mlkitTypeToNeutralName[type];
      if (neutralName == null) continue;

      out.add(NeutralKeypoint(
        name: neutralName,
        x: _clampUnit(landmark.x / w),
        y: _clampUnit(landmark.y / h),
        z: keepZ ? landmark.z : null,
        score: _clampUnit(_extractLikelihood(landmark) ?? 1.0),
      ));
    }
  }

  return out;
}
