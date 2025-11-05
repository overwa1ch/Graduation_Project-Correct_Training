// lib/pose/per_joint_threshold.dart
//
// 分关节阈值策略：为不同身体部位设置不同的置信度阈值
// 
// 特性：
// - 躯干关键点（肩、髋）用高阈值（更严格）
// - 主要关节（膝、踝、肘）用中等阈值
// - 远端关节（腕、指、脚趾）用低阈值（更宽松）
// - 符合生理先验：躯干稳定，远端易遮挡

import 'package:aiwa_core/pose/pose_engine.dart';

/// 关节组类型
enum JointGroup {
  core,      // 核心躯干（肩、髋）
  major,     // 主要关节（膝、踝、肘）
  peripheral, // 外围关节（腕、指、脚趾、眼、耳、鼻）
}

/// 分关节阈值配置
class PerJointThresholdConfig {
  /// 核心躯干阈值（更严格）
  final double coreThreshold;

  /// 主要关节阈值（中等）
  final double majorThreshold;

  /// 外围关节阈值（更宽松）
  final double peripheralThreshold;

  const PerJointThresholdConfig({
    this.coreThreshold = 0.5,
    this.majorThreshold = 0.3,
    this.peripheralThreshold = 0.2,
  });

  /// MoveNet 推荐配置（分数普遍偏低）
  static const movenet = PerJointThresholdConfig(
    coreThreshold: 0.15,
    majorThreshold: 0.1,
    peripheralThreshold: 0.05,
  );

  /// MLKit 推荐配置（分数较高）
  static const mlkit = PerJointThresholdConfig(
    coreThreshold: 0.5,
    majorThreshold: 0.3,
    peripheralThreshold: 0.2,
  );
}

/// 分关节阈值过滤器
class PerJointThresholdFilter {
  final PerJointThresholdConfig config;

  /// 关节名称到关节组的映射
  static const Map<String, JointGroup> _jointGroupMap = {
    // 核心躯干
    'leftShoulder': JointGroup.core,
    'rightShoulder': JointGroup.core,
    'leftHip': JointGroup.core,
    'rightHip': JointGroup.core,
    'left_shoulder': JointGroup.core,
    'right_shoulder': JointGroup.core,
    'left_hip': JointGroup.core,
    'right_hip': JointGroup.core,

    // 主要关节
    'leftElbow': JointGroup.major,
    'rightElbow': JointGroup.major,
    'leftKnee': JointGroup.major,
    'rightKnee': JointGroup.major,
    'leftAnkle': JointGroup.major,
    'rightAnkle': JointGroup.major,
    'left_elbow': JointGroup.major,
    'right_elbow': JointGroup.major,
    'left_knee': JointGroup.major,
    'right_knee': JointGroup.major,
    'left_ankle': JointGroup.major,
    'right_ankle': JointGroup.major,

    // 外围关节
    'leftWrist': JointGroup.peripheral,
    'rightWrist': JointGroup.peripheral,
    'leftPinky': JointGroup.peripheral,
    'rightPinky': JointGroup.peripheral,
    'leftIndex': JointGroup.peripheral,
    'rightIndex': JointGroup.peripheral,
    'leftThumb': JointGroup.peripheral,
    'rightThumb': JointGroup.peripheral,
    'leftHeel': JointGroup.peripheral,
    'rightHeel': JointGroup.peripheral,
    'leftFootIndex': JointGroup.peripheral,
    'rightFootIndex': JointGroup.peripheral,
    'left_wrist': JointGroup.peripheral,
    'right_wrist': JointGroup.peripheral,
    'left_pinky': JointGroup.peripheral,
    'right_pinky': JointGroup.peripheral,
    'left_index': JointGroup.peripheral,
    'right_index': JointGroup.peripheral,
    'left_thumb': JointGroup.peripheral,
    'right_thumb': JointGroup.peripheral,
    'left_heel': JointGroup.peripheral,
    'right_heel': JointGroup.peripheral,
    'left_foot_index': JointGroup.peripheral,
    'right_foot_index': JointGroup.peripheral,

    // 面部
    'nose': JointGroup.peripheral,
    'leftEye': JointGroup.peripheral,
    'rightEye': JointGroup.peripheral,
    'leftEar': JointGroup.peripheral,
    'rightEar': JointGroup.peripheral,
    'leftEyeInner': JointGroup.peripheral,
    'rightEyeInner': JointGroup.peripheral,
    'leftEyeOuter': JointGroup.peripheral,
    'rightEyeOuter': JointGroup.peripheral,
    'left_eye': JointGroup.peripheral,
    'right_eye': JointGroup.peripheral,
    'left_ear': JointGroup.peripheral,
    'right_ear': JointGroup.peripheral,
    'left_eye_inner': JointGroup.peripheral,
    'right_eye_inner': JointGroup.peripheral,
    'left_eye_outer': JointGroup.peripheral,
    'right_eye_outer': JointGroup.peripheral,
  };

  PerJointThresholdFilter(this.config);

  /// 根据关节名称获取阈值
  double getThresholdForJoint(String jointName) {
    final group = _jointGroupMap[jointName] ?? JointGroup.peripheral;
    switch (group) {
      case JointGroup.core:
        return config.coreThreshold;
      case JointGroup.major:
        return config.majorThreshold;
      case JointGroup.peripheral:
        return config.peripheralThreshold;
    }
  }

  /// 过滤关键点（使用分关节阈值）
  List<NeutralKeypoint> filter(List<NeutralKeypoint> keypoints) {
    return keypoints.where((kp) {
      final threshold = getThresholdForJoint(kp.name);
      return kp.score >= threshold;
    }).toList(growable: false);
  }

  /// 过滤帧（更新关键点列表）
  NeutralFrame filterFrame(NeutralFrame frame) {
    final filtered = filter(frame.keypoints);
    return NeutralFrame(
      frameIndex: frame.frameIndex,
      timestampMs: frame.timestampMs,
      width: frame.width,
      height: frame.height,
      keypoints: filtered,
      lowConfidence: frame.lowConfidence,
      mirrorApplied: frame.mirrorApplied,
    );
  }
}

