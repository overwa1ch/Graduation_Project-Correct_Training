// lib/pose/pose_engine.dart
//
// 里程碑 B：统一的姿态引擎接口定义（可插拔）
// 与文档的一致性：统一接口、对外返回时间戳对齐的关键点序列；多实现（MLKit / MoveNet）
// 参见《项目进度同步：推理引擎抽象（PoseEngine）与 Keypoint Adapter》
//
// 如果你的工程非 Flutter，只用 Dart CLI，也可以仅复用接口与中立类型。

import 'dart:typed_data';

/// 中立关键点：统一名称 + 归一化坐标 + 置信度 + 可选深度
class NeutralKeypoint {
  final String name; // 例如 nose、leftHip、rightKnee 等
  final double x; // 归一化到 [0,1]，相对于帧宽
  final double y; // 归一化到 [0,1]，相对于帧高（注意坐标系：屏幕/图像坐标）
  final double? z; // 可选（ML Kit 提供实验性 Z）
  final double score; // 置信度 [0,1]

  const NeutralKeypoint({
    required this.name,
    required this.x,
    required this.y,
    required this.score,
    this.z,
  });

  NeutralKeypoint copyWith({
    double? x,
    double? y,
    double? score,
    double? z,
  }) {
    return NeutralKeypoint(
      name: name,
      x: x ?? this.x,
      y: y ?? this.y,
      score: score ?? this.score,
      z: z ?? this.z,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'x': x,
        'y': y,
        if (z != null) 'z': z,
        'score': score,
      };
}

/// 单帧中立关键点及其时间/尺寸信息（便于导出与离线管线使用）
class NeutralFrame {
  final int frameIndex; // 序号（从 0 递增）
  final int timestampMs; // 该帧时间戳（毫秒）
  final int width; // 原始帧宽（像素）
  final int height; // 原始帧高（像素）
  final List<NeutralKeypoint> keypoints;
  final bool lowConfidence; // 当前帧是否低置信
  final bool mirrorApplied; // 是否进行了镜像翻转

  const NeutralFrame({
    required this.frameIndex,
    required this.timestampMs,
    required this.width,
    required this.height,
    required this.keypoints,
    this.lowConfidence = false,
    this.mirrorApplied = false,
  });

  Map<String, dynamic> toJson() => {
        'frameIndex': frameIndex,
        'timestampMs': timestampMs,
        'lowConfidence': lowConfidence,
        'mirrorApplied': mirrorApplied,
        'keypoints': keypoints.map((e) => e.toJson()).toList(),
      };
}

/// 引擎配置：是否使用高精度模型、是否输出 Z 值等
class PoseEngineConfig {
  final bool preferAccurate; // ML Kit: base vs accurate
  final bool outputZ; // 是否保留 z 坐标
  final double minScore; // 过滤低置信度关键点
  final bool returnEmptyWhenLow; // 若全部低于 minScore 是否允许返回空

  const PoseEngineConfig({
    this.preferAccurate = false,
    this.outputZ = true,
    this.minScore = 0.0,
    this.returnEmptyWhenLow = false,
  });
}

/// 引擎输入：让实现层可以同时支持多种来源（相机帧/视频解码帧/静态图）
/// - imageBytes/rawBuffer: 可选的原始图像 buffer（某些平台不需要）
/// - metadata: 至少要包含宽高，用于做坐标归一化
class PoseEngineInput {
  final Uint8List? imageBytes;
  final int width;
  final int height;
  final int rotationDeg; // 图像旋转角（如相机传感器方向）
  final int frameIndex;
  final int timestampMs;
  final bool mirrorHorizontally;

  PoseEngineInput({
    required this.width,
    required this.height,
    required this.frameIndex,
    required this.timestampMs,
    this.imageBytes,
    this.rotationDeg = 0,
    this.mirrorHorizontally = false,
  });
}

/// 可插拔姿态引擎统一接口：
/// - init：可选初始化
/// - infer：单帧推理 → 输出 NeutralFrame
/// - close：资源释放
abstract class PoseEngine {
  Future<void> init(PoseEngineConfig config);

  Future<NeutralFrame> infer(PoseEngineInput input);

  Future<void> close();
}
