import 'dart:convert';

import 'keypoint_names.dart';

class NeutralVideoInfo {
  final String basename;
  final double fpsIntended;
  final int width;
  final int height;
  final int durationMs;

  const NeutralVideoInfo({
    required this.basename,
    required this.fpsIntended,
    required this.width,
    required this.height,
    required this.durationMs,
  });
}

class NeutralEngineInfo {
  final String name;
  final String model;
  final String sdkVersion;

  const NeutralEngineInfo({
    required this.name,
    required this.model,
    required this.sdkVersion,
  });
}

class NeutralSamplingInfo {
  final int stride;
  final double effectiveFps;

  const NeutralSamplingInfo({
    required this.stride,
    required this.effectiveFps,
  });
}

class NeutralKeypointValue {
  final String name;
  final double x;
  final double y;
  final double? z;
  final double score;

  const NeutralKeypointValue({
    required this.name,
    required this.x,
    required this.y,
    this.z,
    required this.score,
  });
}

class NeutralFrameData {
  final int frameIndex;
  final int timestampMs;
  final bool lowConfidence;
  final bool mirrorApplied;
  final List<NeutralKeypointValue> keypoints;

  const NeutralFrameData({
    required this.frameIndex,
    required this.timestampMs,
    required this.lowConfidence,
    required this.mirrorApplied,
    required this.keypoints,
  });
}

class NeutralKeypointSeries {
  final String version;
  final NeutralVideoInfo video;
  final NeutralEngineInfo engine;
  final NeutralSamplingInfo sampling;
  final List<NeutralFrameData> frames;

  const NeutralKeypointSeries({
    required this.version,
    required this.video,
    required this.engine,
    required this.sampling,
    required this.frames,
  });

  double get effectiveFps => sampling.effectiveFps;
}

class NeutralKeypointParseError implements Exception {
  final String message;
  NeutralKeypointParseError(this.message);
  @override
  String toString() => 'NeutralKeypointParseError: $message';
}

double _asDouble(Object? value, String path) {
  if (value is num) return value.toDouble();
  throw NeutralKeypointParseError(
      'Expected number at $path, got ${value.runtimeType}');
}

int _asInt(Object? value, String path) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw NeutralKeypointParseError(
      'Expected integer at $path, got ${value.runtimeType}');
}

bool _asBool(Object? value, String path) {
  if (value is bool) return value;
  throw NeutralKeypointParseError(
      'Expected bool at $path, got ${value.runtimeType}');
}

String _asString(Object? value, String path) {
  if (value is String) return value;
  throw NeutralKeypointParseError(
      'Expected string at $path, got ${value.runtimeType}');
}

Map<String, dynamic> _asMap(Object? value, String path) {
  if (value is Map<String, dynamic>) return value;
  throw NeutralKeypointParseError(
      'Expected object at $path, got ${value.runtimeType}');
}

List<dynamic> _asList(Object? value, String path) {
  if (value is List) return value;
  throw NeutralKeypointParseError(
      'Expected array at $path, got ${value.runtimeType}');
}

NeutralKeypointSeries parseNeutralKeypointSeries(String jsonStr) {
  late final Map<String, dynamic> root;
  try {
    final decoded = json.decode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw NeutralKeypointParseError('Top-level JSON must be an object.');
    }
    root = decoded;
  } catch (e) {
    if (e is NeutralKeypointParseError) rethrow;
    throw NeutralKeypointParseError('Invalid JSON: $e');
  }
  return parseNeutralKeypointSeriesFromMap(root);
}

NeutralKeypointSeries parseNeutralKeypointSeriesFromMap(
    Map<String, dynamic> root) {
  final version = _asString(root['version'], 'version');
  if (version != 'vB1.1') {
    throw NeutralKeypointParseError(
        'Unsupported neutral keypoints version "$version" (expected vB1.1).');
  }

  final videoMap = _asMap(root['video'], 'video');
  final basename = videoMap.containsKey('basename')
      ? _asString(videoMap['basename'], 'video.basename')
      : '';
  final video = NeutralVideoInfo(
    basename: basename,
    fpsIntended: _asDouble(videoMap['fpsIntended'], 'video.fpsIntended'),
    width: _asInt(videoMap['width'], 'video.width'),
    height: _asInt(videoMap['height'], 'video.height'),
    durationMs: _asInt(videoMap['durationMs'], 'video.durationMs'),
  );

  final engineMap = _asMap(root['engine'], 'engine');
  final engine = NeutralEngineInfo(
    name: _asString(engineMap['name'], 'engine.name'),
    model: _asString(engineMap['model'], 'engine.model'),
    sdkVersion: _asString(engineMap['sdkVersion'], 'engine.sdkVersion'),
  );

  final samplingMap = _asMap(root['sampling'], 'sampling');
  final sampling = NeutralSamplingInfo(
    stride: _asInt(samplingMap['stride'], 'sampling.stride'),
    effectiveFps:
        _asDouble(samplingMap['effectiveFps'], 'sampling.effectiveFps'),
  );

  final framesList = _asList(root['frames'], 'frames');
  if (framesList.isEmpty) {
    throw NeutralKeypointParseError('frames must not be empty.');
  }

  final frames = <NeutralFrameData>[];
  int? lastTimestamp;

  for (var i = 0; i < framesList.length; i++) {
    final frameMap = _asMap(framesList[i], 'frames[$i]');
    final frameIndex = _asInt(frameMap['frameIndex'], 'frames[$i].frameIndex');
    final timestamp = _asInt(frameMap['timestampMs'], 'frames[$i].timestampMs');
    if (frameIndex < 0) {
      throw NeutralKeypointParseError(
          'frames[$i].frameIndex must be >= 0, got $frameIndex');
    }
    if (timestamp < 0) {
      throw NeutralKeypointParseError(
          'frames[$i].timestampMs must be >= 0, got $timestamp');
    }
    if (lastTimestamp != null && timestamp < lastTimestamp) {
      throw NeutralKeypointParseError(
          'frames[$i].timestampMs=$timestamp is not monotonic. Previous=$lastTimestamp');
    }
    lastTimestamp = timestamp;

    final lowConfidence =
        _asBool(frameMap['lowConfidence'], 'frames[$i].lowConfidence');
    final mirrorApplied =
        _asBool(frameMap['mirrorApplied'], 'frames[$i].mirrorApplied');

    final keypointsList =
        _asList(frameMap['keypoints'], 'frames[$i].keypoints');
    final keypoints = <NeutralKeypointValue>[];
    for (var j = 0; j < keypointsList.length; j++) {
      final kpMap = _asMap(keypointsList[j], 'frames[$i].keypoints[$j]');
      final name = _asString(kpMap['name'], 'frames[$i].keypoints[$j].name');
      if (!kNeutralKeypointNameSet.contains(name)) {
        throw NeutralKeypointParseError(
            'frames[$i].keypoints[$j].name="$name" is not a recognized neutral keypoint.');
      }
      final x = _asDouble(kpMap['x'], 'frames[$i].keypoints[$j].x');
      final y = _asDouble(kpMap['y'], 'frames[$i].keypoints[$j].y');
      final score = _asDouble(kpMap['score'], 'frames[$i].keypoints[$j].score');
      if (x < 0.0 || x > 1.0) {
        throw NeutralKeypointParseError(
            'frames[$i].keypoints[$j].x must be within [0,1], got $x');
      }
      if (y < 0.0 || y > 1.0) {
        throw NeutralKeypointParseError(
            'frames[$i].keypoints[$j].y must be within [0,1], got $y');
      }
      if (score < 0.0 || score > 1.0) {
        throw NeutralKeypointParseError(
            'frames[$i].keypoints[$j].score must be within [0,1], got $score');
      }
      final z = kpMap.containsKey('z') && kpMap['z'] != null
          ? _asDouble(kpMap['z'], 'frames[$i].keypoints[$j].z')
          : null;

      keypoints.add(NeutralKeypointValue(
        name: name,
        x: x,
        y: y,
        z: z,
        score: score,
      ));
    }

    frames.add(NeutralFrameData(
      frameIndex: frameIndex,
      timestampMs: timestamp,
      lowConfidence: lowConfidence,
      mirrorApplied: mirrorApplied,
      keypoints: keypoints,
    ));
  }

  return NeutralKeypointSeries(
    version: version,
    video: video,
    engine: engine,
    sampling: sampling,
    frames: frames,
  );
}

Map<String, dynamic> neutralKeypointSeriesToJson(
        NeutralKeypointSeries series) =>
    {
      'version': series.version,
      'video': {
        'basename': series.video.basename,
        'fpsIntended': series.video.fpsIntended,
        'width': series.video.width,
        'height': series.video.height,
        'durationMs': series.video.durationMs,
      },
      'engine': {
        'name': series.engine.name,
        'model': series.engine.model,
        'sdkVersion': series.engine.sdkVersion,
      },
      'sampling': {
        'stride': series.sampling.stride,
        'effectiveFps': series.sampling.effectiveFps,
      },
      'frames': series.frames
          .map((frame) => {
                'frameIndex': frame.frameIndex,
                'timestampMs': frame.timestampMs,
                'lowConfidence': frame.lowConfidence,
                'mirrorApplied': frame.mirrorApplied,
                'keypoints': frame.keypoints
                    .map((kp) => {
                          'name': kp.name,
                          'x': kp.x,
                          'y': kp.y,
                          if (kp.z != null) 'z': kp.z,
                          'score': kp.score,
                        })
                    .toList(),
              })
          .toList(),
    };
