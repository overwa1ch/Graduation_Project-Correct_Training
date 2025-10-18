// kp_models.dart
import 'dart:convert';

import '../core/errors.dart';

class KPFrame {
  final int tMs;
  final List<List<double>> pts; // length == 17, each [x,y,score]
  KPFrame(this.tMs, this.pts);
}

class KeypointSeries {
  final double fps;
  final List<KPFrame> frames;
  KeypointSeries(this.fps, this.frames);
}

double _asDouble(Object? v, String path) {
  if (v is num) return v.toDouble();
  throw InputKpInvalid('Expected number at $path, got ${v.runtimeType}');
}

int _asIntMs(Object? v, String path) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  throw InputKpInvalid('Expected integer ms at $path, got ${v.runtimeType}');
}

List<List<double>> _normalizePts(Object? raw, String path) {
  // 形态 A: [[x,y,score], ...]
  if (raw is List) {
    if (raw.isEmpty) {
      throw InputKpInvalid('Empty pts at $path');
    }
    // A1: 元素是 List（[[x,y,score], ...]）
    if (raw.first is List) {
      final out = <List<double>>[];
      for (var i = 0; i < raw.length; i++) {
        final e = raw[i];
        if (e is! List) {
          throw InputKpInvalid('pts[$i] expected List at $path, got ${e.runtimeType}');
        }
        if (e.length < 2) {
          throw InputKpInvalid('pts[$i] requires at least [x,y,(score)], got length ${e.length}');
        }
        final x = _asDouble(e[0], '$path[$i][0]');
        final y = _asDouble(e[1], '$path[$i][1]');
        final s = e.length >= 3 ? _asDouble(e[2], '$path[$i][2]') : 0.0;
        out.add([x, y, s]);
      }
      return out;
    }
    // A2: 元素是 Map（[{x:..,y:..,score:..}, ...]）
    if (raw.first is Map) {
      final out = <List<double>>[];
      for (var i = 0; i < raw.length; i++) {
        final e = raw[i];
        if (e is! Map) {
          throw InputKpInvalid('pts[$i] expected Map at $path, got ${e.runtimeType}');
        }
        final x = _asDouble(e['x'], '$path[$i].x');
        final y = _asDouble(e['y'], '$path[$i].y');
        final s = e.containsKey('score') ? _asDouble(e['score'], '$path[$i].score') : 0.0;
        out.add([x, y, s]);
      }
      return out;
    }
    throw InputKpInvalid('Unsupported pts list element type at $path: ${raw.first.runtimeType}');
  }

  // 形态 C: {"0":[x,y,s], "1":[x,y,s], ...}
  if (raw is Map) {
    final out = <List<double>>[];
    final keys = raw.keys
        .map((k) => int.tryParse(k.toString()))
        .where((k) => k != null)
        .cast<int>()
        .toList()
      ..sort();
    if (keys.isEmpty) {
      throw InputKpInvalid('pts map has no numeric keys at $path');
    }
    for (final k in keys) {
      final e = raw[k.toString()];
      if (e is! List || e.length < 2) {
        throw InputKpInvalid('pts["$k"] must be [x,y,(score)] at $path, got ${e.runtimeType}');
      }
      final x = _asDouble(e[0], '$path["$k"][0]');
      final y = _asDouble(e[1], '$path["$k"][1]');
      final s = e.length >= 3 ? _asDouble(e[2], '$path["$k"][2]') : 0.0;
      out.add([x, y, s]);
    }
    return out;
  }

  throw InputKpInvalid('Unsupported pts type at $path: ${raw.runtimeType}');
}

KeypointSeries parseKeypointSeries(String jsonStr) {
  late final Map<String, dynamic> m;
  try {
    final root = json.decode(jsonStr);
    if (root is! Map<String, dynamic>) {
      throw InputKpInvalid('Top-level must be an object with {fps, frames}');
    }
    m = root;
  } catch (e) {
    throw InputKpInvalid('Invalid JSON: $e');
  }

  return parseKeypointSeriesFromMap(m);
}

KeypointSeries parseKeypointSeriesFromMap(Map<String, dynamic> m) {
  final fps = _asDouble(m['fps'], 'fps');
  if (fps <= 0) throw InputKpInvalid('fps must be > 0');

  final framesRaw = m['frames'];
  if (framesRaw is! List) {
    throw InputKpInvalid('frames must be a List, got ${framesRaw.runtimeType}');
  }
  if (framesRaw.isEmpty) {
    throw InputKpInvalid('frames is empty');
  }

  final frames = <KPFrame>[];
  int? lastT;

  for (var i = 0; i < framesRaw.length; i++) {
    final f = framesRaw[i];
    if (f is! Map) {
      throw InputKpInvalid('frames[$i] must be an object with {t, pts}');
    }
    final tMs = _asIntMs(f['t'], 'frames[$i].t');
    if (tMs < 0) throw InputKpInvalid('frames[$i].t must be >= 0');
    if (lastT != null && tMs < lastT) {
      throw InputKpInvalid('frames[$i].t is not monotonic (previous=$lastT, current=$tMs)');
    }
    lastT = tMs;

    final pts = _normalizePts(f['pts'], 'frames[$i].pts');

    if (pts.length != 17) {
      throw ModelAdapterMissing(
          'Milestone A requires 17 keypoints (MoveNet17), got ${pts.length} at frames[$i].pts');
    }

    frames.add(KPFrame(tMs, pts));
  }

  return KeypointSeries(fps, frames);
}
