// lib/pose/pose_engine_factory.dart
//
// 姿态引擎工厂
// 根据配置创建相应的 PoseEngine 实现
//
// 支持的引擎：
// - MLKit: Google ML Kit Pose Detection (33 点)
// - MoveNet: TensorFlow Lite MoveNet (17 点)
// - MediaPipe: 未实现（占位）
// - Auto: 自动选择（根据设备性能）

import 'package:flutter/foundation.dart';
import 'package:aiwa_core/pose/pose_engine.dart';
import 'package:aiwa_app/pose/mlkit_pose_engine.dart';
import 'package:aiwa_app/pose/movenet_pose_engine.dart';

/// 创建姿态引擎
/// 
/// 参数:
/// - [engineName]: 引擎名称 ('MLKit', 'MoveNet', 'MediaPipe', 'Auto')
/// 
/// 返回: PoseEngine 实例
/// 
/// 如果引擎名称未识别或未实现，降级到 MLKit
PoseEngine createPoseEngine(String engineName) {
  final normalizedName = engineName.trim().toLowerCase();
  
  debugPrint('[PoseEngineFactory] Creating engine: $engineName');
  
  switch (normalizedName) {
    case 'movenet':
      debugPrint('[PoseEngineFactory] ✅ Using MoveNet Lightning (192x192, 17 points)');
      return MovenetPoseEngine(modelType: MovenetModel.lightning);
      
    case 'movenet-thunder':
      debugPrint('[PoseEngineFactory] ✅ Using MoveNet Thunder (256x256, 17 points)');
      return MovenetPoseEngine(modelType: MovenetModel.thunder);
      
    case 'mlkit':
    case 'blazepose':
      debugPrint('[PoseEngineFactory] ✅ Using ML Kit (BlazePose, 33 points)');
      return MlKitPoseEngine();
      
    case 'mediapipe':
      debugPrint('[PoseEngineFactory] ❌ MediaPipe not implemented, falling back to MLKit');
      return MlKitPoseEngine();
      
    case 'auto':
      // 自动选择：暂时使用 MLKit（稳定性好）
      // 未来可以根据设备性能自动选择
      debugPrint('[PoseEngineFactory] 🤖 Auto mode: selecting MLKit (default)');
      return MlKitPoseEngine();
      
    default:
      debugPrint('[PoseEngineFactory] ⚠️ Unknown engine "$engineName", falling back to MLKit');
      return MlKitPoseEngine();
  }
}

/// 获取引擎信息（用于日志和调试）
Map<String, dynamic> getEngineInfo(String engineName) {
  final normalizedName = engineName.trim().toLowerCase();
  
  switch (normalizedName) {
    case 'movenet':
      return {
        'name': 'MoveNet Lightning',
        'version': 'int8/4',
        'keypointCount': 17,
        'inputSize': '192x192',
        'modelSize': '~3MB',
        'speed': 'fast',
        'accuracy': 'medium',
      };
      
    case 'movenet-thunder':
      return {
        'name': 'MoveNet Thunder',
        'version': 'int8/4',
        'keypointCount': 17,
        'inputSize': '256x256',
        'modelSize': '~5MB',
        'speed': 'medium',
        'accuracy': 'high',
      };
      
    case 'mlkit':
    case 'blazepose':
      return {
        'name': 'ML Kit Pose Detection',
        'version': '0.14.0',
        'keypointCount': 33,
        'inputSize': 'variable',
        'modelSize': 'bundled',
        'speed': 'fast',
        'accuracy': 'high',
      };
      
    case 'mediapipe':
      return {
        'name': 'MediaPipe Pose',
        'version': 'N/A',
        'keypointCount': 33,
        'inputSize': 'N/A',
        'modelSize': 'N/A',
        'speed': 'N/A',
        'accuracy': 'N/A',
        'status': 'not_implemented',
      };
      
    default:
      return {
        'name': 'Unknown',
        'status': 'unknown',
      };
  }
}

/// 验证引擎名称是否有效
bool isValidEngineName(String engineName) {
  final normalizedName = engineName.trim().toLowerCase();
  return const {
    'movenet',
    'movenet-thunder',
    'mlkit',
    'blazepose',
    'mediapipe',
    'auto',
  }.contains(normalizedName);
}

/// 获取所有可用引擎列表
List<String> getAvailableEngines() {
  return [
    'MLKit',
    'MoveNet',
    // 'MediaPipe', // 未实现
    'Auto',
  ];
}

