import 'dart:async';
import 'dart:typed_data';

import 'pose_engine.dart';

class RawImageFrame {
  final Uint8List bytes;
  final int width;
  final int height;
  final int rotationDeg;

  const RawImageFrame({
    required this.bytes,
    required this.width,
    required this.height,
    this.rotationDeg = 0,
  });
}

class FrameStreamerConfig {
  final double fps;
  final int stride;
  final bool mirror;
  final String engineName;
  final String modelName;
  final String sdkVersion;
  final String videoBasename;

  const FrameStreamerConfig({
    required this.engineName,
    required this.modelName,
    required this.sdkVersion,
    required this.videoBasename,
    this.fps = 30.0,
    this.stride = 2,
    this.mirror = true,
  })  : assert(fps > 0),
        assert(stride > 0);

  double get effectiveFps => fps / stride;
}

class FrameStreamResult {
  final FrameStreamerConfig config;
  final List<NeutralFrame> frames;
  final int width;
  final int height;
  final double frameIntervalMs;
  final int durationMs;

  const FrameStreamResult({
    required this.config,
    required this.frames,
    required this.width,
    required this.height,
    required this.frameIntervalMs,
    required this.durationMs,
  });

  Map<String, dynamic> toNeutralKeypointsJson() => {
        'version': 'vB1.1',
        'video': {
          'basename': config.videoBasename,
          'fpsIntended': config.fps,
          'width': width,
          'height': height,
          'durationMs': durationMs,
        },
        'engine': {
          'name': config.engineName,
          'model': config.modelName,
          'sdkVersion': config.sdkVersion,
        },
        'sampling': {
          'stride': config.stride,
          'effectiveFps': config.effectiveFps,
        },
        'frames': frames.map((f) => f.toJson()).toList(),
      };
}

class FrameStreamer {
  final PoseEngine _engine;
  final PoseEngineConfig _engineConfig;
  final FrameStreamerConfig _config;

  FrameStreamer({
    required PoseEngine engine,
    required PoseEngineConfig engineConfig,
    required FrameStreamerConfig config,
  })  : _engine = engine,
        _engineConfig = engineConfig,
        _config = config;

  Future<FrameStreamResult> run(Stream<RawImageFrame> frameStream) async {
    await _engine.init(_engineConfig);

    final outputs = <NeutralFrame>[];
    int? firstWidth;
    int? firstHeight;
    var processedIndex = 0;
    var sourceIndex = 0;
    final frameIntervalMs = 1000.0 * _config.stride / _config.fps;
    var timestampAccumulatorMs = 0.0;

    try {
      await for (final raw in frameStream) {
        final currentSource = sourceIndex;
        sourceIndex++;

        firstWidth ??= raw.width;
        firstHeight ??= raw.height;

        if (currentSource % _config.stride != 0) {
          continue;
        }

        final frameTimestampMs = timestampAccumulatorMs.round();
        final frame = await _engine.infer(PoseEngineInput(
          imageBytes: raw.bytes,
          width: raw.width,
          height: raw.height,
          rotationDeg: raw.rotationDeg,
          frameIndex: processedIndex,
          timestampMs: frameTimestampMs,
          mirrorHorizontally: _config.mirror,
        ));

        outputs.add(frame);
        processedIndex++;
        timestampAccumulatorMs += frameIntervalMs;
      }
    } finally {
      await _engine.close();
    }

    final totalDurationMs =
        outputs.isEmpty ? 0 : timestampAccumulatorMs.round();

    return FrameStreamResult(
      config: _config,
      frames: outputs,
      width: firstWidth ?? 0,
      height: firstHeight ?? 0,
      frameIntervalMs: frameIntervalMs,
      durationMs: totalDurationMs,
    );
  }
}
