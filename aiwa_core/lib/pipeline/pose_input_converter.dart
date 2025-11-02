import '../pose/keypoint_names.dart';
import '../pose/kp_models.dart';
import '../pose/neutral_keypoint_series.dart';
import 'pose_series.dart';

/// Neutral格式到Pipeline格式的关键点名称转换映射
/// 
/// 处理特例（mouth_left/right 顺序不同）
const Map<String, String> _neutralToPipelineNameMap = {
  'mouth_left': 'leftMouth',
  'mouth_right': 'rightMouth',
};

/// 将snake_case格式转换为camelCase格式
/// 
/// 示例：
/// - `left_hip` → `leftHip`
/// - `left_eye_inner` → `leftEyeInner`
/// - `nose` → `nose` (无下划线，保持不变)
String _convertSnakeToCamel(String snakeCase) {
  // 先检查特例映射
  if (_neutralToPipelineNameMap.containsKey(snakeCase)) {
    return _neutralToPipelineNameMap[snakeCase]!;
  }
  
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

  // 🔍 诊断：验证名称转换
  if (series.frames.isNotEmpty) {
    final firstFrame = series.frames.first;
    final sampleKeypoints = firstFrame.keypoints.take(6).map((kp) => '${kp.name}→${_convertSnakeToCamel(kp.name)}').join(', ');
    print('[PoseInputConverter] 🔍 Name conversion sample (first 6): $sampleKeypoints');
    
    // 检查关键的下半身关键点是否存在
    final requiredLowerBody = ['left_hip', 'left_knee', 'left_ankle', 'right_hip', 'right_knee', 'right_ankle'];
    final foundLowerBody = <String>[];
    for (final kp in firstFrame.keypoints) {
      if (requiredLowerBody.contains(kp.name)) {
        foundLowerBody.add(kp.name);
      }
    }
    print('[PoseInputConverter] 🔍 Lower body keypoints in neutral format: ${foundLowerBody.length}/${requiredLowerBody.length}');
    if (foundLowerBody.isNotEmpty) {
      final converted = foundLowerBody.map((name) => _convertSnakeToCamel(name)).join(', ');
      print('[PoseInputConverter] 🔍 Converted names: $converted');
    }
  }

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

PoseSeries poseSeriesFromLegacy(KeypointSeries series) {
  final frames = <PoseFrame>[];
  for (var i = 0; i < series.frames.length; i++) {
    final frame = series.frames[i];
    final keypoints = <String, PoseLandmark>{};
    for (var j = 0; j < frame.pts.length && j < kMoveNet17Names.length; j++) {
      final raw = frame.pts[j];
      keypoints[kMoveNet17Names[j]] = PoseLandmark(
        x: raw[0],
        y: raw[1],
        score: raw[2],
      );
    }
    final highConfidenceCount =
        keypoints.values.where((kp) => kp.isReliable).length;
    final ratio = kMoveNet17Names.isEmpty
        ? 0.0
        : highConfidenceCount / kMoveNet17Names.length;
    final lowConfidence = keypoints.isEmpty || ratio < 0.7;
    frames.add(PoseFrame(
      index: i,
      timestampMs: frame.tMs,
      lowConfidence: lowConfidence,
      keypoints: keypoints,
    ));
  }

  final meta = const PoseSeriesMetadata(
    engine: 'movenet',
    engineVersion: null,
    inputResolution: null,
    samplingStride: 1,
    mirrorApplied: false,
  );

  return PoseSeries(
    fps: series.fps,
    frames: frames,
    metadata: meta,
  );
}
