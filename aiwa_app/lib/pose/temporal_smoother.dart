// lib/pose/temporal_smoother.dart
//
// 时序平滑器：用于姿态关键点的时序平滑和跟踪
// 
// 特性：
// - 对关键点位置和置信度进行 EMA（指数移动平均）平滑
// - 当前帧关键点缺失时，用衰减的历史位置补齐
// - 显著减少间歇性断线和抖动

import 'package:aiwa_core/pose/pose_engine.dart';

/// 单个关键点的历史状态
class _KeypointHistory {
  double x;
  double y;
  double score;
  int lastSeenFrame;

  _KeypointHistory({
    required this.x,
    required this.y,
    required this.score,
    required this.lastSeenFrame,
  });
}

/// 时序平滑器
/// 
/// 用法：
/// ```dart
/// final smoother = TemporalSmoother(alpha: 0.6, maxMissingFrames: 5);
/// for (var frame in frames) {
///   final smoothed = smoother.smooth(frame);
///   // 使用 smoothed 进行后续处理
/// }
/// ```
class TemporalSmoother {
  /// EMA 平滑系数 [0, 1]
  /// - 0.0: 完全使用历史值（极度平滑，延迟大）
  /// - 1.0: 完全使用当前值（无平滑）
  /// - 0.6-0.7: 推荐值，平衡平滑度和响应性
  final double alpha;

  /// 分数衰减系数
  /// 当关键点缺失时，每帧分数乘以此系数
  final double scoreDecay;

  /// 最大补齐帧数
  /// 关键点缺失超过此帧数后，不再补齐
  final int maxMissingFrames;

  /// 历史关键点状态（按名称索引）
  final Map<String, _KeypointHistory> _history = {};

  /// 当前帧索引
  int _currentFrameIndex = -1;

  TemporalSmoother({
    this.alpha = 0.6,
    this.scoreDecay = 0.9,
    this.maxMissingFrames = 5,
  }) : assert(alpha >= 0.0 && alpha <= 1.0),
       assert(scoreDecay >= 0.0 && scoreDecay <= 1.0),
       assert(maxMissingFrames >= 0);

  /// 平滑单帧关键点
  NeutralFrame smooth(NeutralFrame frame) {
    _currentFrameIndex = frame.frameIndex;

    // 构建当前帧关键点索引
    final currentKeypoints = <String, NeutralKeypoint>{};
    for (final kp in frame.keypoints) {
      currentKeypoints[kp.name] = kp;
    }

    final smoothedKeypoints = <NeutralKeypoint>[];

    // 1. 处理当前帧存在的关键点（平滑）
    for (final kp in frame.keypoints) {
      final history = _history[kp.name];

      if (history == null) {
        // 首次出现：直接记录
        _history[kp.name] = _KeypointHistory(
          x: kp.x,
          y: kp.y,
          score: kp.score,
          lastSeenFrame: _currentFrameIndex,
        );
        smoothedKeypoints.add(kp);
      } else {
        // 已有历史：EMA 平滑
        final smoothedX = alpha * kp.x + (1 - alpha) * history.x;
        final smoothedY = alpha * kp.y + (1 - alpha) * history.y;
        final smoothedScore = alpha * kp.score + (1 - alpha) * history.score;

        // 更新历史
        history.x = smoothedX;
        history.y = smoothedY;
        history.score = smoothedScore;
        history.lastSeenFrame = _currentFrameIndex;

        smoothedKeypoints.add(NeutralKeypoint(
          name: kp.name,
          x: smoothedX,
          y: smoothedY,
          score: smoothedScore,
          z: kp.z, // Z 坐标不平滑（如果有的话）
        ));
      }
    }

    // 2. 补齐缺失的关键点（使用衰减的历史位置）
    for (final entry in _history.entries) {
      final name = entry.key;
      final history = entry.value;

      // 如果当前帧没有此关键点
      if (!currentKeypoints.containsKey(name)) {
        final missingFrames = _currentFrameIndex - history.lastSeenFrame;

        // 在允许的缺失帧数内，用衰减的历史值补齐
        if (missingFrames <= maxMissingFrames) {
          final decayedScore = history.score * scoreDecay;

          // 只有分数仍然合理时才补齐
          if (decayedScore > 0.05) {
            smoothedKeypoints.add(NeutralKeypoint(
              name: name,
              x: history.x,
              y: history.y,
              score: decayedScore,
              z: null,
            ));

            // 更新历史分数（衰减）
            history.score = decayedScore;
          }
        }
      }
    }

    return NeutralFrame(
      frameIndex: frame.frameIndex,
      timestampMs: frame.timestampMs,
      width: frame.width,
      height: frame.height,
      keypoints: smoothedKeypoints,
      lowConfidence: frame.lowConfidence,
      mirrorApplied: frame.mirrorApplied,
    );
  }

  /// 重置平滑器状态
  void reset() {
    _history.clear();
    _currentFrameIndex = -1;
  }
}

