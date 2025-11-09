// lib/services/keypoint_skeleton.dart
//
// Skeleton connection definitions for keypoint visualization
// Defines bone pairs and visual properties for drawing pose overlays

import 'dart:ui';

/// Represents a connection between two keypoints (a "bone")
class SkeletonConnection {
  final String startPoint;
  final String endPoint;
  final Color color;
  final double strokeWidth;

  const SkeletonConnection({
    required this.startPoint,
    required this.endPoint,
    required this.color,
    this.strokeWidth = 3.0,
  });
}

/// ML Kit 33-point skeleton connections
/// Based on BlazePose topology
class KeypointSkeleton {
  /// Color scheme for different body parts
  static const Color colorHead = Color(0xFF00BCD4); // Cyan
  static const Color colorTorso = Color(0xFF4CAF50); // Green
  static const Color colorArms = Color(0xFFFF9800); // Orange
  static const Color colorLegs = Color(0xFF2196F3); // Blue
  
  /// Keypoint visual properties
  static const double keypointRadius = 4.0;
  static const Color keypointHighConfidence = Color(0xFF4CAF50); // Green
  static const Color keypointLowConfidence = Color(0xFF9E9E9E); // Gray
  // 🔧 降低 MLKit 绘制阈值，保证可视化先稳定
  static const double confidenceThreshold = 0.3;
  
  /// All skeleton connections for ML Kit 33-point model
  static const List<SkeletonConnection> connections = [
    // Head connections
    SkeletonConnection(
      startPoint: 'nose',
      endPoint: 'left_eye_inner',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'left_eye_inner',
      endPoint: 'left_eye',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'left_eye',
      endPoint: 'left_eye_outer',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'left_eye_outer',
      endPoint: 'left_ear',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'nose',
      endPoint: 'right_eye_inner',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'right_eye_inner',
      endPoint: 'right_eye',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'right_eye',
      endPoint: 'right_eye_outer',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'right_eye_outer',
      endPoint: 'right_ear',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'mouth_left',
      endPoint: 'mouth_right',
      color: colorHead,
    ),
    
    // Torso connections
    SkeletonConnection(
      startPoint: 'left_shoulder',
      endPoint: 'right_shoulder',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'left_shoulder',
      endPoint: 'left_hip',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'right_shoulder',
      endPoint: 'right_hip',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'left_hip',
      endPoint: 'right_hip',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    
    // Left arm connections
    SkeletonConnection(
      startPoint: 'left_shoulder',
      endPoint: 'left_elbow',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'left_elbow',
      endPoint: 'left_wrist',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'left_wrist',
      endPoint: 'left_pinky',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'left_wrist',
      endPoint: 'left_index',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'left_wrist',
      endPoint: 'left_thumb',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'left_pinky',
      endPoint: 'left_index',
      color: colorArms,
      strokeWidth: 1.5,
    ),
    
    // Right arm connections
    SkeletonConnection(
      startPoint: 'right_shoulder',
      endPoint: 'right_elbow',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'right_elbow',
      endPoint: 'right_wrist',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'right_wrist',
      endPoint: 'right_pinky',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'right_wrist',
      endPoint: 'right_index',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'right_wrist',
      endPoint: 'right_thumb',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'right_pinky',
      endPoint: 'right_index',
      color: colorArms,
      strokeWidth: 1.5,
    ),
    
    // Left leg connections
    SkeletonConnection(
      startPoint: 'left_hip',
      endPoint: 'left_knee',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'left_knee',
      endPoint: 'left_ankle',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'left_ankle',
      endPoint: 'left_heel',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'left_ankle',
      endPoint: 'left_foot_index',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'left_heel',
      endPoint: 'left_foot_index',
      color: colorLegs,
      strokeWidth: 2.0,
    ),
    
    // Right leg connections
    SkeletonConnection(
      startPoint: 'right_hip',
      endPoint: 'right_knee',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'right_knee',
      endPoint: 'right_ankle',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'right_ankle',
      endPoint: 'right_heel',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'right_ankle',
      endPoint: 'right_foot_index',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'right_heel',
      endPoint: 'right_foot_index',
      color: colorLegs,
      strokeWidth: 2.0,
    ),
  ];
  
  /// Convert color to ARGB integer for native platform communication
  static int colorToArgb(Color color) {
    return (color.alpha << 24) | (color.red << 16) | (color.green << 8) | color.blue;
  }
  
  /// Get serializable connection data for native platform
  static List<Map<String, dynamic>> getConnectionsForNative() {
    // MLKit 适配器输出的名称为驼峰式，这里将连接表中的 snake_case 映射为驼峰式
    const Map<String, String> alias = {
      'nose': 'nose',
      'left_eye_inner': 'leftEyeInner',
      'left_eye': 'leftEye',
      'left_eye_outer': 'leftEyeOuter',
      'right_eye_inner': 'rightEyeInner',
      'right_eye': 'rightEye',
      'right_eye_outer': 'rightEyeOuter',
      'left_ear': 'leftEar',
      'right_ear': 'rightEar',
      'mouth_left': 'leftMouth',
      'mouth_right': 'rightMouth',
      'left_shoulder': 'leftShoulder',
      'right_shoulder': 'rightShoulder',
      'left_elbow': 'leftElbow',
      'right_elbow': 'rightElbow',
      'left_wrist': 'leftWrist',
      'right_wrist': 'rightWrist',
      'left_pinky': 'leftPinky',
      'right_pinky': 'rightPinky',
      'left_index': 'leftIndex',
      'right_index': 'rightIndex',
      'left_thumb': 'leftThumb',
      'right_thumb': 'rightThumb',
      'left_hip': 'leftHip',
      'right_hip': 'rightHip',
      'left_knee': 'leftKnee',
      'right_knee': 'rightKnee',
      'left_ankle': 'leftAnkle',
      'right_ankle': 'rightAnkle',
      'left_heel': 'leftHeel',
      'right_heel': 'rightHeel',
      'left_foot_index': 'leftFootIndex',
      'right_foot_index': 'rightFootIndex',
    };

    return connections.map((conn) {
      final start = alias[conn.startPoint] ?? conn.startPoint;
      final end = alias[conn.endPoint] ?? conn.endPoint;
      return {
        'start': start,
        'end': end,
        'color': colorToArgb(conn.color),
        'strokeWidth': conn.strokeWidth,
      };
    }).toList();
  }
  
  /// Get keypoint visual properties for native platform
  static Map<String, dynamic> getKeypointPropertiesForNative() {
    return {
      'radius': keypointRadius,
      'highConfidenceColor': colorToArgb(keypointHighConfidence),
      'lowConfidenceColor': colorToArgb(keypointLowConfidence),
      'confidenceThreshold': confidenceThreshold,
    };
  }

  // ========================= MoveNet (17-point) =========================
  static List<Map<String, dynamic>> getConnectionsForNativeMoveNet() {
    List<Map<String, dynamic>> build(String a, String b, Color c, {double w = 3.0}) =>
        [
          {
            'start': a,
            'end': b,
            'color': colorToArgb(c),
            'strokeWidth': w,
          }
        ];

    final c = <Map<String, dynamic>>[];

    // Head
    c.addAll(build('nose', 'leftEye', colorHead));
    c.addAll(build('nose', 'rightEye', colorHead));
    c.addAll(build('leftEye', 'leftEar', colorHead));
    c.addAll(build('rightEye', 'rightEar', colorHead));

    // Torso
    c.addAll(build('leftShoulder', 'rightShoulder', colorTorso, w: 4.0));
    c.addAll(build('leftShoulder', 'leftHip', colorTorso, w: 4.0));
    c.addAll(build('rightShoulder', 'rightHip', colorTorso, w: 4.0));
    c.addAll(build('leftHip', 'rightHip', colorTorso, w: 4.0));

    // Arms
    c.addAll(build('leftShoulder', 'leftElbow', colorArms));
    c.addAll(build('leftElbow', 'leftWrist', colorArms));
    c.addAll(build('rightShoulder', 'rightElbow', colorArms));
    c.addAll(build('rightElbow', 'rightWrist', colorArms));

    // Legs
    c.addAll(build('leftHip', 'leftKnee', colorLegs, w: 4.0));
    c.addAll(build('leftKnee', 'leftAnkle', colorLegs, w: 4.0));
    c.addAll(build('rightHip', 'rightKnee', colorLegs, w: 4.0));
    c.addAll(build('rightKnee', 'rightAnkle', colorLegs, w: 4.0));

    return c;
  }

  static Map<String, dynamic> getKeypointPropertiesForNativeMoveNet() {
    return {
      'radius': keypointRadius,
      'highConfidenceColor': colorToArgb(keypointHighConfidence),
      'lowConfidenceColor': colorToArgb(keypointLowConfidence),
      // Lower temporarily to visualize low-confidence MoveNet outputs
      'confidenceThreshold': 0.1,
    };
  }
}

