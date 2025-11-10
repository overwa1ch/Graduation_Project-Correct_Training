// lib/pose/mlkit_pose_engine.dart
//
// 修正点：
// - 引入 dart:ui 的 Size（ui.Size）
// - 为 InputImageMetadata 提供非空的 bytesPerRow
// - 按平台选择合适的 InputImageFormat（Android: NV21；iOS: BGRA8888）
// - 其余保持与里程碑 B 设计一致

import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui show Size;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'package:aiwa_core/aiwa_core.dart';

import 'package:aiwa_app/pose/adapter/keypoint_adapter.dart';
import 'package:aiwa_app/pose/per_joint_threshold.dart';

class MlKitPoseEngine implements PoseEngine {
  late PoseDetector _detector;
  late PoseEngineConfig _config;
  bool _initialized = false;
  
  // 🔧 分关节阈值过滤器
  late PerJointThresholdFilter _thresholdFilter;

  MlKitPoseEngine();

  @override
  Future<void> init(PoseEngineConfig config) async {
    _config = config;

    final options = config.preferAccurate
        ? PoseDetectorOptions(
            mode: PoseDetectionMode.stream,
            model: PoseDetectionModel.accurate,
          )
        : PoseDetectorOptions(
            mode: PoseDetectionMode.stream,
            model: PoseDetectionModel.base,
          );

    _detector = PoseDetector(options: options);
    
    // 🔧 初始化分关节阈值过滤器（MLKit 使用较严格的阈值）
    _thresholdFilter = PerJointThresholdFilter(PerJointThresholdConfig.mlkit);
    
    _initialized = true;
  }

  @override
  Future<NeutralFrame> infer(PoseEngineInput input) async {
    if (!_initialized) {
      throw StateError('MlKitPoseEngine not initialized. Call init() first.');
    }

    // 🔧 修复：优先使用 filePath（避免 JPEG 字节格式不匹配问题）
    // - 如果提供 filePath，使用 InputImage.fromFilePath（自动处理 JPEG/PNG 等格式）
    // - 如果没有 filePath，回退到 fromBytes（需要原始格式如 NV21/BGRA8888）
    InputImage inputImage;
    
    if (input.filePath != null) {
      // 使用文件路径（推荐方式，自动处理 JPEG/PNG 等编码格式）
      inputImage = InputImage.fromFilePath(input.filePath!);
    } else {
      // 回退到原始字节方式（需要原始格式，不支持 JPEG 编码）
      final Uint8List? bytes = input.imageBytes;
      if (bytes == null) {
        throw ArgumentError(
            'MlKitPoseEngine requires either filePath or imageBytes (raw format) in PoseEngineInput.');
      }

      // 选择格式 + 计算 bytesPerRow
      // - Android 使用 NV21（camera 插件最好配置 ImageFormatGroup.nv21）
      // - iOS 使用 BGRA8888（camera 插件配置 ImageFormatGroup.bgra8888）
      final InputImageFormat format =
          Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.nv21;

      // 经验值：
      // - NV21（Y 平面）通常 bytesPerRow ~= width
      // - BGRA8888 每像素 4 字节，bytesPerRow = width * 4
      // 如果你从 camera 的 plane 直接拿到 bytesPerRow，请以相机返回的为准。
      final int bytesPerRow = Platform.isIOS ? (input.width * 4) : input.width;

      inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: ui.Size(input.width.toDouble(), input.height.toDouble()),
          rotation: _rotationFromDeg(input.rotationDeg),
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
    }

    final List<Pose> poses = await _detector.processImage(inputImage);
    if (poses.isEmpty) {
      return NeutralFrame(
        frameIndex: input.frameIndex,
        timestampMs: input.timestampMs,
        width: input.width,
        height: input.height,
        keypoints: const [],
        lowConfidence: true,
        mirrorApplied: input.mirrorHorizontally,
      );
    }

    final pose = poses.first;
    final keypoints = adaptMlKitPose(
      pose: pose,
      width: input.width,
      height: input.height,
      keepZ: _config.outputZ,
      minScore: _config.minScore,
      returnEmptyWhenLow: _config.returnEmptyWhenLow,
    );
    final processed = input.mirrorHorizontally
        ? keypoints
            .map(
                (kp) => kp.copyWith(x: (1.0 - kp.x).clamp(0.0, 1.0).toDouble()))
            .toList(growable: false)
        : List<NeutralKeypoint>.from(keypoints, growable: false);

    // 🔧 使用分关节阈值过滤（更智能的过滤策略）
    // 先用基础阈值 0.2 过滤，再用分关节阈值
    final preFiltered = processed.where((kp) => kp.score >= 0.2).toList(growable: false);
    final filtered = _thresholdFilter.filter(preFiltered);
    final highConfidenceCount = processed.where((kp) => kp.score >= 0.4).length;
    final highConfidenceRatio = kMlKitNeutralKeypointCount == 0
        ? 0.0
        : highConfidenceCount / kMlKitNeutralKeypointCount;
    final bool lowConfidence = processed.isEmpty || highConfidenceRatio < 0.6;

    return NeutralFrame(
      frameIndex: input.frameIndex,
      timestampMs: input.timestampMs,
      width: input.width,
      height: input.height,
      keypoints: filtered,
      lowConfidence: lowConfidence,
      mirrorApplied: input.mirrorHorizontally,
    );
  }

  @override
  Future<void> close() async {
    if (_initialized) {
      await _detector.close();
      _initialized = false;
    }
  }

  InputImageRotation _rotationFromDeg(int deg) {
    switch ((deg % 360 + 360) % 360) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }
}
