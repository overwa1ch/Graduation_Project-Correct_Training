// lib/pose/movenet_pose_engine.dart
//
// MoveNet 姿态引擎实现
// 基于 TensorFlow Lite 的 MoveNet SinglePose 模型
// 
// 特性：
// - 支持 Lightning (192x192) 和 Thunder (256x256) 模型
// - 输出 17 个关键点
// - 坐标格式：[y, x, confidence]
// - 归一化坐标 [0, 1]

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'package:aiwa_core/aiwa_core.dart';
import 'package:aiwa_app/pose/per_joint_threshold.dart';

/// MoveNet 模型类型
enum MovenetModel {
  lightning, // 192x192, 更快
  thunder,   // 256x256, 更准确
}

class MovenetPoseEngine implements PoseEngine {
  late Interpreter _interpreter;
  late PoseEngineConfig _config;
  final MovenetModel _modelType;
  bool _initialized = false;
  
  // 🔧 分关节阈值过滤器
  late PerJointThresholdFilter _thresholdFilter;
  
  int get _inputSize => _modelType == MovenetModel.lightning ? 192 : 256;

  // 记录最近一次预处理时的缩放与裁剪参数，用于将模型输出坐标映射回原始图像坐标
  double _lastScale = 1.0;
  int _lastOffsetX = 0;
  int _lastOffsetY = 0;

  MovenetPoseEngine({MovenetModel modelType = MovenetModel.lightning})
      : _modelType = modelType;

  @override
  Future<void> init(PoseEngineConfig config) async {
    _config = config;

    try {
      // 加载模型文件
      final modelPath = _modelType == MovenetModel.lightning
          ? 'assets/models/movenet_lightning.tflite'
          : 'assets/models/movenet_thunder.tflite';

      debugPrint('[MovenetPoseEngine] Loading model: $modelPath');
      
      _interpreter = await Interpreter.fromAsset(modelPath);
      
      // 验证输入输出张量
      final inputTensor = _interpreter.getInputTensor(0);
      final outputTensor = _interpreter.getOutputTensor(0);
      
      debugPrint('[MovenetPoseEngine] Input shape: ${inputTensor.shape}');
      debugPrint('[MovenetPoseEngine] Input type: ${inputTensor.type}');
      debugPrint('[MovenetPoseEngine] Output shape: ${outputTensor.shape}');
      debugPrint('[MovenetPoseEngine] Output type: ${outputTensor.type}');
      
      // 🔧 初始化分关节阈值过滤器（MoveNet 使用宽松的阈值）
      _thresholdFilter = PerJointThresholdFilter(PerJointThresholdConfig.movenet);
      debugPrint('[MovenetPoseEngine] Using per-joint thresholds: core=0.15, major=0.1, peripheral=0.05');
      
      _initialized = true;
      debugPrint('[MovenetPoseEngine] Initialized successfully');
    } on PlatformException catch (e) {
      throw StateError('Failed to load MoveNet model: ${e.message}');
    } catch (e) {
      throw StateError('Unexpected error loading MoveNet: $e');
    }
  }

  @override
  Future<NeutralFrame> infer(PoseEngineInput input) async {
    if (!_initialized) {
      throw StateError('MovenetPoseEngine not initialized. Call init() first.');
    }

    try {
      // 预处理图像
      final preprocessed = await _preprocessImage(input);
      
      // TFLite 推理
      // 🔧 修复：输出格式是 [1, 1, 17, 3] 其中每个关键点为 [y, x, confidence]
      final output = List.generate(
        1,
        (_) => List.generate(
          1, // 🔧 注意：实际输出是 [1, 1, 17, 3]，不是 [1, 17, 3]
          (_) => List.generate(
            17,
            (_) => List.filled(3, 0.0),
          ),
        ),
      );
      
      _interpreter.run(preprocessed, output);
      
      // 🔧 修复：解析输出时需要提取 output[0][0] 来获取 [17, 3] 的数据
      final List<List<double>> modelOutput = output[0][0];

      // 🔍 诊断：前 3 帧打印原始模型输出的前 3 个关键点
      if (input.frameIndex < 3) {
        for (int i = 0; i < 3 && i < modelOutput.length; i++) {
          final p = modelOutput[i];
          debugPrint('[MovenetPoseEngine] 🔍   Raw KP$i: y=${p[0].toStringAsFixed(3)}, x=${p[1].toStringAsFixed(3)}, conf=${p[2].toStringAsFixed(3)}');
        }
      }

      final keypoints = _parseOutput(
        modelOutput,
        input.width,
        input.height,
      );

      // 🔍 诊断日志：前3帧输出原始关键点信息
      if (input.frameIndex < 3) {
        debugPrint('[MovenetPoseEngine] 🔍 Frame ${input.frameIndex} - Raw keypoints: ${keypoints.length}');
        final requiredNames = ['leftHip', 'rightHip', 'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle'];
        for (final name in requiredNames) {
          final kp = keypoints.firstWhere(
            (k) => k.name == name,
            orElse: () => NeutralKeypoint(name: name, x: 0, y: 0, score: 0),
          );
          if (kp.score > 0) {
            debugPrint('[MovenetPoseEngine] 🔍   $name: x=${kp.x.toStringAsFixed(3)}, y=${kp.y.toStringAsFixed(3)}, score=${kp.score.toStringAsFixed(3)}, isReliable=${kp.score >= 0.5}');
          }
        }
        final avgScore = keypoints.isEmpty ? 0.0 : keypoints.map((k) => k.score).reduce((a, b) => a + b) / keypoints.length;
        debugPrint('[MovenetPoseEngine] 🔍   Average score: ${avgScore.toStringAsFixed(3)}');
      }

      // 处理镜像
      final processed = input.mirrorHorizontally
          ? keypoints
              .map((kp) => kp.copyWith(x: (1.0 - kp.x).clamp(0.0, 1.0)))
              .toList(growable: false)
          : List<NeutralKeypoint>.from(keypoints, growable: false);

      // 🔧 使用分关节阈值过滤（更智能的过滤策略）
      // 如果配置的 minScore > 0，则先用统一阈值过滤，再用分关节阈值
      final preFiltered = _config.minScore > 0.0
          ? processed.where((kp) => kp.score >= _config.minScore).toList(growable: false)
          : processed;
      final filtered = _thresholdFilter.filter(preFiltered);
      
      // 🔍 诊断日志：过滤前后对比（前3帧）
      if (input.frameIndex < 3) {
        debugPrint('[MovenetPoseEngine] 🔍 Frame ${input.frameIndex} - Filtering:');
        debugPrint('[MovenetPoseEngine] 🔍   Before filter: ${processed.length} keypoints');
        debugPrint('[MovenetPoseEngine] 🔍   After filter (minScore=${_config.minScore}): ${filtered.length} keypoints');
        final reliableCount = processed.where((kp) => kp.score >= 0.5).length;
        debugPrint('[MovenetPoseEngine] 🔍   Reliable (score>=0.5): $reliableCount/${processed.length}');
        
        // 检查必需关键点的过滤情况
        final requiredNames = ['leftHip', 'rightHip', 'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle'];
        var requiredBefore = 0;
        var requiredAfter = 0;
        var requiredReliable = 0;
        for (final name in requiredNames) {
          final before = processed.firstWhere((k) => k.name == name, orElse: () => NeutralKeypoint(name: name, x: 0, y: 0, score: 0));
          final after = filtered.firstWhere((k) => k.name == name, orElse: () => NeutralKeypoint(name: name, x: 0, y: 0, score: 0));
          if (before.score > 0) requiredBefore++;
          if (after.score > 0) requiredAfter++;
          if (before.score >= 0.5) requiredReliable++;
        }
        debugPrint('[MovenetPoseEngine] 🔍   Required joints (6): before=$requiredBefore, after=$requiredAfter, reliable=$requiredReliable');
      }
      
      // 计算高置信度比例
      final highConfidenceCount = processed.where((kp) => kp.score >= 0.5).length;
      final highConfidenceRatio = processed.isEmpty
          ? 0.0
          : highConfidenceCount / 17; // MoveNet 总是 17 个点
      
      final bool lowConfidence = processed.isEmpty || highConfidenceRatio < 0.5;

      return NeutralFrame(
        frameIndex: input.frameIndex,
        timestampMs: input.timestampMs,
        width: input.width,
        height: input.height,
        keypoints: filtered,
        lowConfidence: lowConfidence,
        mirrorApplied: input.mirrorHorizontally,
      );
    } on FormatException catch (e) {
      // 图像格式错误：可恢复，返回空帧
      debugPrint('[MovenetPoseEngine] Image format error: $e');
      return NeutralFrame(
        frameIndex: input.frameIndex,
        timestampMs: input.timestampMs,
        width: input.width,
        height: input.height,
        keypoints: const [],
        lowConfidence: true,
        mirrorApplied: input.mirrorHorizontally,
      );
    } on PlatformException catch (e) {
      // TFLite 平台异常：可能是致命错误
      debugPrint('[MovenetPoseEngine] TFLite error: $e');
      throw StateError('MoveNet inference failed: ${e.message}');
    } catch (e) {
      // 其他未知错误
      debugPrint('[MovenetPoseEngine] Unexpected error: $e');
      throw StateError('MoveNet inference unexpected error: $e');
    }
  }

  @override
  Future<void> close() async {
    if (_initialized) {
      _interpreter.close();
      _initialized = false;
      debugPrint('[MovenetPoseEngine] Closed');
    }
  }

  /// 预处理图像：解码 → Letterbox缩放+填充 → 记录缩放与填充参数 → 扁平 Uint8List（RGB，0-255）
  /// 
  /// Letterbox 策略：
  /// - 等比缩放使长边对齐模型输入尺寸
  /// - 短边用黑色填充至方形
  /// - 记录 scale 和 pad 参数用于输出坐标映射
  /// - 优势：不裁剪肢体，边缘关节点置信度更高
  Future<Uint8List> _preprocessImage(
    PoseEngineInput input,
  ) async {
    // 从 imageBytes 或文件路径读取图像
    final Uint8List? bytes = input.imageBytes;
    if (bytes == null) {
      throw ArgumentError('MovenetPoseEngine requires imageBytes in PoseEngineInput.');
    }

    // 使用 image 包解码
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw const FormatException('Failed to decode image');
    }

    // 🔧 Letterbox 缩放：保持宽高比，短边填充
    // 计算缩放比例（让长边对齐输入尺寸，短边会小于输入尺寸）
    final scaleW = _inputSize / image.width;
    final scaleH = _inputSize / image.height;
    _lastScale = scaleW < scaleH ? scaleW : scaleH; // 注意：取较小的scale

    final scaledWidth = (image.width * _lastScale).round();
    final scaledHeight = (image.height * _lastScale).round();
    
    // 使用 cubic 插值以获得更好的质量
    final scaled = img.copyResize(
      image,
      width: scaledWidth,
      height: scaledHeight,
      interpolation: img.Interpolation.cubic, // 🔧 改进：使用更高质量的插值
    );

    // 计算填充（让缩放后的图像居中）
    _lastOffsetX = ((_inputSize - scaledWidth) / 2).round();
    _lastOffsetY = ((_inputSize - scaledHeight) / 2).round();
    
    // 创建黑色背景的方形图像，然后将缩放后的图像粘贴到中央
    final padded = img.Image(width: _inputSize, height: _inputSize);
    img.fill(padded, color: img.ColorRgb8(0, 0, 0)); // 填充黑色
    
    // 将缩放后的图像复制到中央
    img.compositeImage(
      padded,
      scaled,
      dstX: _lastOffsetX,
      dstY: _lastOffsetY,
    );

    // 构建扁平 Uint8List（长度: H*W*3）
    final int h = _inputSize;
    final int w = _inputSize;
    final Uint8List inputBytes = Uint8List(h * w * 3);
    int idx = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = padded.getPixel(x, y);
        inputBytes[idx++] = pixel.r.toInt(); // 0-255
        inputBytes[idx++] = pixel.g.toInt(); // 0-255
        inputBytes[idx++] = pixel.b.toInt(); // 0-255
      }
    }

    return inputBytes;
  }

  /// 解析 MoveNet 输出为 NeutralKeypoint 列表
  /// 
  /// MoveNet 输出格式：[17, 3]
  /// 每个关键点：[y_normalized, x_normalized, confidence]
  /// 坐标是相对于模型输入尺寸 (_inputSize) 归一化的 [0, 1]
  /// 
  /// 需要转换为相对于原始图像尺寸的归一化坐标
  /// 
  /// Letterbox 坐标映射：
  /// 模型输出 → 去归一化(×inputSize) → 减去pad → 还原缩放(÷scale) → 归一化到原图
  List<NeutralKeypoint> _parseOutput(
    List<List<double>> modelOutput,
    int originalWidth,
    int originalHeight,
  ) {
    final keypoints = <NeutralKeypoint>[];

    for (int i = 0; i < 17 && i < modelOutput.length; i++) {
      final point = modelOutput[i];
      if (point.length < 3) continue;

      // MoveNet 输出：[y, x, confidence] 相对于模型输入尺寸归一化
      final yNormModel = point[0]; // [0, 1] 相对于 _inputSize
      final xNormModel = point[1]; // [0, 1] 相对于 _inputSize
      final confidence = point[2];  // [0, 1]

      // 🔧 Letterbox 坐标反映射：
      // 1) 归一化 -> 填充后的像素坐标（基于 _inputSize）
      final xPadded = xNormModel * _inputSize;
      final yPadded = yNormModel * _inputSize;
      // 2) 减去填充偏移 -> 缩放后的像素坐标
      final xScaled = xPadded - _lastOffsetX;
      final yScaled = yPadded - _lastOffsetY;
      // 3) 还原缩放 -> 原始像素坐标
      final xOriginal = xScaled / _lastScale;
      final yOriginal = yScaled / _lastScale;
      // 4) 归一化到 [0,1]
      final xNormalized = (xOriginal / originalWidth).clamp(0.0, 1.0);
      final yNormalized = (yOriginal / originalHeight).clamp(0.0, 1.0);

      // 使用 MoveNet 17 点名称映射
      final name = kMoveNet17Names[i];

      keypoints.add(NeutralKeypoint(
        name: name,
        x: xNormalized,
        y: yNormalized,
        score: confidence,
        z: null, // MoveNet 不提供 Z 坐标
      ));
    }

    return keypoints;
  }
}

