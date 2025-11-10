// lib/services/keypoint_skeleton.dart
//
// Skeleton connection definitions for keypoint visualization
// Defines bone pairs and visual properties for drawing pose overlays

import 'dart:ui';

import 'package:aiwa_core/aiwa_core.dart';

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
  /// Uses canonical camelCase keypoint names from aiwa_core
  static const List<SkeletonConnection> connections = [
    // Head connections
    SkeletonConnection(
      startPoint: 'nose',
      endPoint: 'leftEyeInner',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'leftEyeInner',
      endPoint: 'leftEye',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'leftEye',
      endPoint: 'leftEyeOuter',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'leftEyeOuter',
      endPoint: 'leftEar',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'nose',
      endPoint: 'rightEyeInner',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'rightEyeInner',
      endPoint: 'rightEye',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'rightEye',
      endPoint: 'rightEyeOuter',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'rightEyeOuter',
      endPoint: 'rightEar',
      color: colorHead,
    ),
    SkeletonConnection(
      startPoint: 'leftMouth',
      endPoint: 'rightMouth',
      color: colorHead,
    ),
    
    // Torso connections
    SkeletonConnection(
      startPoint: 'leftShoulder',
      endPoint: 'rightShoulder',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'leftShoulder',
      endPoint: 'leftHip',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'rightShoulder',
      endPoint: 'rightHip',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'leftHip',
      endPoint: 'rightHip',
      color: colorTorso,
      strokeWidth: 4.0,
    ),
    
    // Left arm connections
    SkeletonConnection(
      startPoint: 'leftShoulder',
      endPoint: 'leftElbow',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'leftElbow',
      endPoint: 'leftWrist',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'leftWrist',
      endPoint: 'leftPinky',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'leftWrist',
      endPoint: 'leftIndex',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'leftWrist',
      endPoint: 'leftThumb',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'leftPinky',
      endPoint: 'leftIndex',
      color: colorArms,
      strokeWidth: 1.5,
    ),
    
    // Right arm connections
    SkeletonConnection(
      startPoint: 'rightShoulder',
      endPoint: 'rightElbow',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'rightElbow',
      endPoint: 'rightWrist',
      color: colorArms,
    ),
    SkeletonConnection(
      startPoint: 'rightWrist',
      endPoint: 'rightPinky',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'rightWrist',
      endPoint: 'rightIndex',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'rightWrist',
      endPoint: 'rightThumb',
      color: colorArms,
      strokeWidth: 2.0,
    ),
    SkeletonConnection(
      startPoint: 'rightPinky',
      endPoint: 'rightIndex',
      color: colorArms,
      strokeWidth: 1.5,
    ),
    
    // Left leg connections
    SkeletonConnection(
      startPoint: 'leftHip',
      endPoint: 'leftKnee',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'leftKnee',
      endPoint: 'leftAnkle',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'leftAnkle',
      endPoint: 'leftHeel',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'leftAnkle',
      endPoint: 'leftFootIndex',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'leftHeel',
      endPoint: 'leftFootIndex',
      color: colorLegs,
      strokeWidth: 2.0,
    ),
    
    // Right leg connections
    SkeletonConnection(
      startPoint: 'rightHip',
      endPoint: 'rightKnee',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'rightKnee',
      endPoint: 'rightAnkle',
      color: colorLegs,
      strokeWidth: 4.0,
    ),
    SkeletonConnection(
      startPoint: 'rightAnkle',
      endPoint: 'rightHeel',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'rightAnkle',
      endPoint: 'rightFootIndex',
      color: colorLegs,
      strokeWidth: 2.5,
    ),
    SkeletonConnection(
      startPoint: 'rightHeel',
      endPoint: 'rightFootIndex',
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
    return connections.map((conn) {
      final start = normalizeNeutralKeypointName(conn.startPoint);
      final end = normalizeNeutralKeypointName(conn.endPoint);
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
            'start': normalizeNeutralKeypointName(a),
            'end': normalizeNeutralKeypointName(b),
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

