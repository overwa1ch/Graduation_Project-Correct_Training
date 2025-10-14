import '../pose/keypoint_names.dart';
import '../pose/kp_models.dart';
import '../pose/neutral_keypoint_series.dart';
import 'pose_series.dart';

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
                kp.name: PoseLandmark(
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
