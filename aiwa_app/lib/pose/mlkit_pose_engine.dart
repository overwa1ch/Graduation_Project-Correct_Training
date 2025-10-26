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
// 如果你的工程里没有直接引用 commons，可以删掉下一行；保留也没问题。
// import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import 'package:aiwa_core/pose/pose_engine.dart';

import 'package:aiwa_app/pose/adapter/keypoint_adapter.dart';

class MlKitPoseEngine implements PoseEngine {
  late PoseDetector _detector;
  late PoseEngineConfig _config;
  bool _initialized = false;

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
    _initialized = true;
  }

  @override
  Future<NeutralFrame> infer(PoseEngineInput input) async {
    if (!_initialized) {
      throw StateError('MlKitPoseEngine not initialized. Call init() first.');
    }

    final Uint8List? bytes = input.imageBytes;
    if (bytes == null) {
      throw ArgumentError(
          'MlKitPoseEngine requires imageBytes in PoseEngineInput.');
    }

    // 选择格式 + 计算 bytesPerRow
    // - Android 使用 NV21（camera 插件最好配置 ImageFormatGroup.nv21）
    // - iOS 使用 BGRA8888（camera 插件配置 ImageFormatGroup.bgra8888）
    // 参见 google_mlkit_commons 的说明与示例。
    final InputImageFormat format =
        Platform.isIOS ? InputImageFormat.bgra8888 : InputImageFormat.nv21;

    // 经验值：
    // - NV21（Y 平面）通常 bytesPerRow ~= width
    // - BGRA8888 每像素 4 字节，bytesPerRow = width * 4
    // 如果你从 camera 的 plane 直接拿到 bytesPerRow，请以相机返回的为准。
    final int bytesPerRow = Platform.isIOS ? (input.width * 4) : input.width;

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: ui.Size(input.width.toDouble(), input.height.toDouble()),
        rotation: _rotationFromDeg(input.rotationDeg),
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );

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

    final filtered =
        processed.where((kp) => kp.score >= 0.3).toList(growable: false);
    final highConfidenceCount = processed.where((kp) => kp.score >= 0.5).length;
    final highConfidenceRatio = kMlKitNeutralKeypointCount == 0
        ? 0.0
        : highConfidenceCount / kMlKitNeutralKeypointCount;
    final bool lowConfidence = processed.isEmpty || highConfidenceRatio < 0.7;

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
