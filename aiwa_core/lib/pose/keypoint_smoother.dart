// lib/pose/keypoint_smoother.dart
//
// 关键点平滑与插值工具
// 
// 特性：
// - OneEuro 自适应滤波
// - 缺失值线性插值（最大间隔可配置）
// - 统一的平滑逻辑供离线管线和实时端侧使用

import '../core/one_euro.dart';

/// 2D 坐标点
class KeypointCoord {
  final double x;
  final double y;
  
  const KeypointCoord(this.x, this.y);
}

/// 关键点平滑器配置
class KeypointSmootherConfig {
  /// OneEuro 最小截止频率
  final double minCutoff;
  
  /// OneEuro beta 参数（速度敏感度）
  final double beta;
  
  /// OneEuro 导数截止频率
  final double dCutoff;
  
  /// 最大插值间隔（帧数）
  final int maxInterpolationGap;
  
  const KeypointSmootherConfig({
    this.minCutoff = 1.0,
    this.beta = 0.01,
    this.dCutoff = 1.0,
    this.maxInterpolationGap = 3,
  });
  
  /// 默认配置（用于离线管线）
  static const KeypointSmootherConfig defaultConfig = KeypointSmootherConfig();
  
  /// 实时配置（稍微更激进的平滑）
  static const KeypointSmootherConfig realtimeConfig = KeypointSmootherConfig(
    minCutoff: 1.0,
    beta: 0.01,
    dCutoff: 1.0,
    maxInterpolationGap: 5,
  );
}

/// 对坐标序列进行线性插值
/// 
/// 填补不超过 [maxGap] 帧的缺失值
List<KeypointCoord?> interpolateCoords(
  List<KeypointCoord?> values, {
  required int maxGap,
}) {
  final result = List<KeypointCoord?>.from(values);
  var index = 0;
  
  while (index < result.length) {
    if (result[index] != null) {
      index++;
      continue;
    }

    final gapStart = index;
    while (index < result.length && result[index] == null) {
      index++;
    }
    final gapEnd = index - 1;
    final gapLength = gapEnd - gapStart + 1;

    // 查找前一个有效点
    int? prevIdx = gapStart - 1;
    while (prevIdx != null && prevIdx >= 0 && result[prevIdx] == null) {
      prevIdx--;
    }
    if (prevIdx != null && prevIdx < 0) {
      prevIdx = null;
    }

    // 查找后一个有效点
    int? nextIdx = index;
    while (
        nextIdx != null && nextIdx < result.length && result[nextIdx] == null) {
      nextIdx++;
    }
    if (nextIdx != null && nextIdx >= result.length) {
      nextIdx = null;
    }

    // 如果间隔太大或缺少边界点，跳过
    if (prevIdx == null || nextIdx == null || gapLength > maxGap) {
      continue;
    }

    // 线性插值
    final start = result[prevIdx]!;
    final end = result[nextIdx]!;
    final span = nextIdx - prevIdx;
    for (var offset = 1; offset <= gapLength; offset++) {
      final ratio = offset / span;
      final x = start.x + (end.x - start.x) * ratio;
      final y = start.y + (end.y - start.y) * ratio;
      result[gapStart + offset - 1] = KeypointCoord(x, y);
    }
  }

  return result;
}

/// 对坐标序列应用 OneEuro 滤波
/// 
/// [fps] 用于计算时间步长
List<KeypointCoord?> applyOneEuroFilter(
  List<KeypointCoord?> values,
  double fps, {
  double minCutoff = 1.0,
  double beta = 0.01,
  double dCutoff = 1.0,
}) {
  if (fps <= 0) {
    return List<KeypointCoord?>.from(values);
  }

  final filterX = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff);
  final filterY = OneEuroFilter(minCutoff: minCutoff, beta: beta, dCutoff: dCutoff);
  final result = List<KeypointCoord?>.from(values);

  for (var i = 0; i < values.length; i++) {
    final sample = values[i];
    if (sample == null) {
      result[i] = null;
      continue;
    }
    final t = i / fps;
    final fx = filterX.filter(t, sample.x);
    final fy = filterY.filter(t, sample.y);
    result[i] = KeypointCoord(fx, fy);
  }

  return result;
}

/// 完整的关键点平滑流程：插值 + OneEuro 滤波
/// 
/// 典型用法：
/// ```dart
/// final config = KeypointSmootherConfig.defaultConfig;
/// final smoothed = smoothKeypointTrack(rawCoords, fps: 30.0, config: config);
/// ```
List<KeypointCoord?> smoothKeypointTrack(
  List<KeypointCoord?> values,
  double fps, {
  KeypointSmootherConfig config = KeypointSmootherConfig.defaultConfig,
}) {
  // 1. 插值填补缺失值
  final interpolated = interpolateCoords(
    values,
    maxGap: config.maxInterpolationGap,
  );
  
  // 2. OneEuro 滤波平滑
  return applyOneEuroFilter(
    interpolated,
    fps,
    minCutoff: config.minCutoff,
    beta: config.beta,
    dCutoff: config.dCutoff,
  );
}

