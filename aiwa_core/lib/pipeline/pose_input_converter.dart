import '../pose/neutral_keypoint_series.dart';
import 'pose_series.dart';

/// 将snake_case格式转换为camelCase格式
/// 
/// 示例：
/// - `left_hip` → `leftHip`
/// - `left_eye_inner` → `leftEyeInner`
/// - `nose` → `nose` (无下划线，保持不变)
String _convertSnakeToCamel(String snakeCase) {
  // 如果已经是camelCase或简单名称（如nose），直接返回
  if (!snakeCase.contains('_')) {
    return snakeCase;
  }
  
  // snake_case → camelCase转换
  final parts = snakeCase.split('_');
  if (parts.isEmpty) return snakeCase;
  
  final result = StringBuffer(parts[0]);
  for (var i = 1; i < parts.length; i++) {
    final part = parts[i];
    if (part.isEmpty) continue;
    // 首字母大写，其余保持原样
    result.write(part[0].toUpperCase() + (part.length > 1 ? part.substring(1) : ''));
  }
  
  return result.toString();
}

PoseSeries poseSeriesFromNeutral(NeutralKeypointSeries series) {
  final stride = series.sampling.stride <= 0 ? 1 : series.sampling.stride;
  final fallbackFps = series.video.fpsIntended / stride;
  final fps = series.effectiveFps > 0 ? series.effectiveFps : fallbackFps;

  final frames = series.frames
      .map((frame) => PoseFrame(
            index: frame.frameIndex,
            timestampMs: frame.timestampMs,
            lowConfidence: frame.lowConfidence,
            keypoints: {
              for (final kp in frame.keypoints)
                _convertSnakeToCamel(kp.name): PoseLandmark(
                  x: kp.x,
                  y: kp.y,
                  z: kp.z,
                  score: kp.score,
                ),
            },
          ))
      .toList();

  final anyMirrored = series.frames.any((frame) => frame.mirrorApplied);
  final height = series.video.height;
  final meta = PoseSeriesMetadata(
    engine: series.engine.name,
    engineVersion: series.engine.sdkVersion,
    inputResolution: height > 0 ? '${height}p' : null,
    samplingStride: series.sampling.stride,
    width: series.video.width,
    height: height,
    mirrorApplied: anyMirrored,
  );

  return PoseSeries(
    fps: fps,
    frames: frames,
    metadata: meta,
  );
}
