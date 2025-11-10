// lib/services/video_analysis_service.dart
//
// 完整视频分析服务 - 基于原生平台通道 + ML Kit + aiwa_core
// 
// 架构：分阶段处理
// 1. 阶段 0-20%：原生 MediaMetadataRetriever/AVFoundation 提取帧
// 2. 阶段 20-90%：ML Kit 姿态检测
// 3. 阶段 90-100%：分析管道 (aiwa_core)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'package:aiwa_app/services/visualization/keypoint_overlay_generator.dart';
import 'package:aiwa_app/services/native/native_frame_extractor.dart';
import 'package:aiwa_app/services/utils/cancellation_token.dart';
import 'package:aiwa_app/services/config/config_sync.dart';
import 'package:aiwa_app/pose/pose_engine_factory.dart';
import 'package:aiwa_app/pose/temporal_smoother.dart';

import 'package:aiwa_core/aiwa_core.dart';

/// 视频信息类
class _VideoInfo {
  final String path;
  final int width;
  final int height;
  final double fps;
  final int durationMs;

  const _VideoInfo({
    required this.path,
    required this.width,
    required this.height,
    required this.fps,
    required this.durationMs,
  });
}

/// 视频分析服务
class VideoAnalysisService {
  /// 分析视频并生成事件流
  /// 
  /// 返回: (stream: 事件流, task: 分析任务的 Future)
  static ({Stream<Map<String, dynamic>> stream, Future<void> task}) analyzeVideo({
    required CancellationToken token,
    required Strictness strictness,
    required String videoPath,
    required String sessionRoot,
    required String configPath,
    required String sessionId,
  }) {
    late StreamController<Map<String, dynamic>> controller;
    final Completer<void> taskCompleter = Completer<void>();

    controller = StreamController<Map<String, dynamic>>.broadcast(
      onListen: () {
        // 启动分析任务并保存 Future
        _runVideoAnalysis(
          token: token,
          strictness: strictness,
          controller: controller,
          videoPath: videoPath,
          sessionRoot: sessionRoot,
          configPath: configPath,
          sessionId: sessionId,
        ).then((_) {
          if (!taskCompleter.isCompleted) {
            taskCompleter.complete();
          }
        }).catchError((Object e, StackTrace st) {
          debugPrint('[VideoAnalysis] Fatal error: $e\n$st');
          if (!taskCompleter.isCompleted) {
            taskCompleter.completeError(e, st);
          }
          if (!controller.isClosed) {
            controller.add({
              'event': 'ERROR',
              'sessionId': sessionId,
              'code': '500_INTERNAL',
              'message': 'Analysis failed: $e',
            });
            controller.close();
          }
        });
      },
      // ✅ 关键修复：订阅取消时关闭 controller，触发检查点
      onCancel: () {
        debugPrint('[VideoAnalysis] [$sessionId] Subscription cancelled, closing controller');
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    return (stream: controller.stream, task: taskCompleter.future);
  }

  /// 执行完整的视频分析流程
  static Future<void> _runVideoAnalysis({
    required CancellationToken token,
    required Strictness strictness,
    required StreamController<Map<String, dynamic>> controller,
    required String videoPath,
    required String sessionRoot,
    required String configPath,
    required String sessionId,
  }) async {
    PoseEngine? engine;
    
    // 中间数据保存（用于降级存储）
    NeutralKeypointSeries? neutralSeries;
    Map<String, dynamic>? qualityMetrics;
    
    try {
      // 0. 读取配置并创建引擎
      final config = await readAppRuntimeConfig();
      final engineName = (config['engine'] as String?)?.trim() ?? 'MLKit';
      
      debugPrint('[VideoAnalysis] Creating pose engine: $engineName');
      engine = createPoseEngine(engineName);
      
      // 初始化引擎（按引擎类型设置不同的 minScore）
      final isMoveNet = engineName.toLowerCase().contains('movenet');
      final isMlkit = engineName.toLowerCase().contains('mlkit');
      final poseConfig = PoseEngineConfig(
        preferAccurate: true,
        outputZ: false,
        // MoveNet 分数偏低：推理阶段不筛，覆盖阶段再可视化
        minScore: isMoveNet ? 0.0 : (isMlkit ? 0.2 : 0.3),
        returnEmptyWhenLow: false,
      );
      await engine.init(poseConfig);
      
      final engineInfo = getEngineInfo(engineName);
      debugPrint('[VideoAnalysis] Engine info: $engineInfo');
      
      // 1. 发送 START 事件
      controller.add({
        'event': 'START',
        'sessionId': sessionId,
        'input': {'path': videoPath},
        'params': {
          'engine': engineName,
          'model': engineInfo['name'] ?? engineName,
          'keypointCount': engineInfo['keypointCount'] ?? 'unknown',
          'stride': 2,
          'targetResolution': '720p',
        },
      });

      // 2. 探测视频信息
      debugPrint('[VideoAnalysis] Probing video: $videoPath');
      final videoInfo = await _probeVideo(videoPath);
      debugPrint('[VideoAnalysis] Video: ${videoInfo.width}x${videoInfo.height}, '
          '${videoInfo.fps}fps, ${videoInfo.durationMs}ms');

      // 3. 阶段 1：提取帧 (0-20%)
      controller.add({
        'event': 'PHASE',
        'sessionId': sessionId,
        'phase': 'decode',
      });

      if (token.isCancelling) {
        debugPrint('[VideoAnalysis] Cancelled before frame extraction');
        return;
      }

      final framesDir = Directory(p.join(sessionRoot, 'frames'));
      await framesDir.create(recursive: true);

      const stride = 2;
      final frames = await _extractFrames(
        token: token,
        videoPath: videoPath,
        framesDir: framesDir,
        stride: stride,
        videoInfo: videoInfo,
        controller: controller,
        onProgress: (processed, total) {
          controller.add({
            'event': 'PROGRESS',
            'sessionId': sessionId,
            'phase': 'decode',
            'processed': processed,
            'total': total,
            'p95MsPerFrame': 10,
            'etaSec': ((total - processed) * 0.01).toInt(),
          });
        },
      );

      debugPrint('[VideoAnalysis] Extracted ${frames.length} frames');

      // 4. 阶段 2：姿态检测 (20-90%)
      controller.add({
        'event': 'PHASE',
        'sessionId': sessionId,
        'phase': 'infer',
      });

      if (token.isCancelling) {
        debugPrint('[VideoAnalysis] Cancelled before pose detection');
        return;
      }

      // 使用 FrameStreamer（aiwa_core）进行姿态检测
      // 注意：frames 已经过 stride 采样，所以这里 stride=1
      final streamResult = await _inferPosesWithFrameStreamer(
        token: token,
        engine: engine,
        frames: frames,
        videoInfo: videoInfo,
        stride: stride,
        controller: controller,
        engineInfo: engineInfo,
        onProgress: (idx, total) {
          controller.add({
            'event': 'PROGRESS',
            'sessionId': sessionId,
            'phase': 'infer',
            'processed': idx + 1,
            'total': total,
            'p95MsPerFrame': 100,
            'etaSec': ((total - idx - 1) * 0.1).toInt(),
          });
        },
      );

      // 提取 NeutralFrame 列表并应用时序平滑
      final rawNeutralFrames = streamResult.frames;

      // 🔧 时序平滑器：减少抖动和间歇性断线
      final smoother = TemporalSmoother(
        fps: videoInfo.fps,
        scoreDecay: 0.9,
        maxMissingFrames: 5,
      );
      
      final smoothedFrames = <NeutralFrame>[];
      for (final frame in rawNeutralFrames) {
        if (token.isCancelling) {
          debugPrint('[VideoAnalysis] Cancelled during temporal smoothing');
          return;
        }
        smoothedFrames.add(smoother.smooth(frame));
      }
      
      // 转换为 JSON 格式（用于后续管线）
      final neutralFrames = smoothedFrames.map((frame) => {
        'frameIndex': frame.frameIndex,
        'timestampMs': frame.timestampMs,
        'lowConfidence': frame.lowConfidence,
        'mirrorApplied': frame.mirrorApplied,
        'keypoints': frame.keypoints.map((kp) => {
          'name': kp.name,
          'x': kp.x,
          'y': kp.y,
          'score': kp.score,
          if (kp.z != null) 'z': kp.z,
        }).toList(),
      }).toList();
      
      debugPrint('[VideoAnalysis] Completed pose detection for ${neutralFrames.length} frames');

      // 5. 计算质量指标（使用 aiwa_core 的标准化方法）
      // ✅ 重构说明：复用 computeQualityFromKeypoints 替代手动统计（约 70 行）
      final poseFrames = smoothedFrames.map((frame) => PoseFrame(
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
      )).toList();
      
      final quality = computeQualityFromKeypoints(poseFrames);

      // 保存质量指标用于降级存储
      qualityMetrics = {
        'lowConfidence': quality.lowConfidence,
        'coverage': quality.coverage,
      };

      debugPrint('[VideoAnalysis] 🔍 Quality Metrics (from aiwa_core):');
      debugPrint('[VideoAnalysis] 🔍   Coverage: ${(quality.coverage * 100).toStringAsFixed(1)}%');
      debugPrint('[VideoAnalysis] 🔍   Low confidence: ${quality.lowConfidence}');

      controller.add({
        'event': 'METRIC',
        'sessionId': sessionId,
        'coverage': quality.coverage,
        'lowConfidence': quality.lowConfidence,
      });

      debugPrint('[VideoAnalysis] Quality: ${(quality.coverage * 100).toInt()}% coverage');

      // 6. 阶段 3：分析管道 (90-100%)
      controller.add({
        'event': 'PHASE',
        'sessionId': sessionId,
        'phase': 'analyze',
      });

      if (token.isCancelling) {
        debugPrint('[VideoAnalysis] Cancelled before pipeline execution');
        return;
      }

      // 构建 NeutralKeypointSeries（保存用于降级存储）
      neutralSeries = _buildNeutralSeries(
        frameJsons: neutralFrames,
        videoInfo: videoInfo,
        stride: stride,
      );

      // 加载规则
      final ruleSet = await _loadRuleSet();

      // 运行分析管道
      final poseSeries = poseSeriesFromNeutral(neutralSeries);
      debugPrint('[VideoAnalysis] 🔧 Creating pipeline with strictness: ${strictness.value}');
      final pipeline = OfflinePipeline(ruleSet, strictness);
      final result = await pipeline.run(poseSeries);

      debugPrint('[VideoAnalysis] Pipeline complete');
      debugPrint('[VideoAnalysis] 📊 Result JSON meta.strictness: ${result.resultJson['meta']?['strictness']}');
      debugPrint('[VideoAnalysis] 📊 Result JSON scores: ${result.resultJson['scores']}');

      // 7. 保存输出文件
      await _saveOutputs(
        sessionRoot: sessionRoot,
        neutralSeries: neutralSeries,
        result: result,
      );

      debugPrint('[VideoAnalysis] Outputs saved');

      // 7.5. 镜像导出到外部存储（方便 adb pull）
      await _mirrorToExternalStorage(sessionRoot: sessionRoot);

      // 7.6. Generate keypoint overlay video (best effort - don't fail if it errors)
      try {
        debugPrint('[VideoAnalysis] Generating keypoint overlay video...');
        final overlayVideoPath = await KeypointOverlayGenerator.generateOverlayVideo(
          sessionRoot: sessionRoot,
        );
        debugPrint('[VideoAnalysis] - keypoints_overlay.mp4: ✓ ($overlayVideoPath)');
      } catch (e, st) {
        debugPrint('[VideoAnalysis] WARNING: Failed to generate overlay video (non-fatal): $e');
        debugPrint('[VideoAnalysis] Stack trace: $st');
        // Don't throw - overlay video is optional, partial results are still valid
      }

      // 8. 发送 DONE 事件
      controller.add({
        'event': 'DONE',
        'sessionId': sessionId,
        'artifacts': {
          'root': sessionRoot,
          'files': [
            'neutral_keypoints.json',
            'result.json',
            'angles.csv',
            'logs/perf.json',
          ],
        },
      });

      debugPrint('[VideoAnalysis] Analysis complete');
      
    } on AngleComputeFailed catch (e) {
      // 降级错误：角度计算失败，但关键点存在，可以保存部分数据
      debugPrint('[VideoAnalysis] ⚠️  Angle computation failed, saving partial data: $e');
      debugPrint('[VideoAnalysis] ⚠️  Current strictness: ${strictness.value}');
      
      if (neutralSeries != null && qualityMetrics != null) {
        try {
          // 生成降级版result.json
          final partialResult = _buildPartialResult(
            neutralSeries: neutralSeries,
            failureCode: e.code,
            failureMessage: e.message,
            quality: qualityMetrics,
            strictnessOverride: strictness.value, // 传递strictness
          );
          
          // 保存部分输出
          await _savePartialOutputs(
            sessionRoot: sessionRoot,
            neutralSeries: neutralSeries,
            partialResult: partialResult,
          );
          
          // 发送DONE事件（带partial标记）
          if (!controller.isClosed) {
            controller.add({
              'event': 'DONE',
              'sessionId': sessionId,
              'partial': true,
              'partialReason': {
                'code': e.code,
                'message': e.message,
              },
              'artifacts': {
                'root': sessionRoot,
                'files': [
                  'neutral_keypoints.json',
                  'result.json',
                  'keypoints_overlay.mp4',
                  'logs/perf.json',
                ],
              },
            });
          }
        } catch (saveError) {
          debugPrint('[VideoAnalysis] Failed to save partial data: $saveError');
          if (!controller.isClosed) {
            controller.add({
              'event': 'ERROR',
              'sessionId': sessionId,
              'code': '500_INTERNAL',
              'message': 'Failed to save partial results: $saveError',
            });
          }
        }
      } else {
        // 数据不足，按致命错误处理
        debugPrint('[VideoAnalysis] Insufficient data for partial result');
        if (!controller.isClosed) {
          controller.add({
            'event': 'ERROR',
            'sessionId': sessionId,
            'code': '500_INTERNAL',
            'message': 'Analysis failed: insufficient data for partial result',
          });
        }
      }
      
    } on MetricsComputeFailed catch (e) {
      // 降级错误：指标计算失败，但角度存在
      debugPrint('[VideoAnalysis] ⚠️  Metrics computation failed, saving partial data: $e');
      debugPrint('[VideoAnalysis] ⚠️  Current strictness: ${strictness.value}');
      
      if (neutralSeries != null && qualityMetrics != null) {
        try {
          final partialResult = _buildPartialResult(
            neutralSeries: neutralSeries,
            failureCode: e.code,
            failureMessage: e.message,
            quality: qualityMetrics,
            strictnessOverride: strictness.value, // 传递strictness
          );
          
          await _savePartialOutputs(
            sessionRoot: sessionRoot,
            neutralSeries: neutralSeries,
            partialResult: partialResult,
          );
          
          if (!controller.isClosed) {
            controller.add({
              'event': 'DONE',
              'sessionId': sessionId,
              'partial': true,
              'partialReason': {
                'code': e.code,
                'message': e.message,
              },
              'artifacts': {
                'root': sessionRoot,
                'files': [
                  'neutral_keypoints.json',
                  'result.json',
                  'keypoints_overlay.mp4',
                  'logs/perf.json',
                ],
              },
            });
          }
        } catch (saveError) {
          debugPrint('[VideoAnalysis] Failed to save partial data: $saveError');
          if (!controller.isClosed) {
            controller.add({
              'event': 'ERROR',
              'sessionId': sessionId,
              'code': '500_INTERNAL',
              'message': 'Failed to save partial results: $saveError',
            });
          }
        }
      } else {
        if (!controller.isClosed) {
          controller.add({
            'event': 'ERROR',
            'sessionId': sessionId,
            'code': '500_INTERNAL',
            'message': 'Analysis failed: insufficient data for partial result',
          });
        }
      }
      
    } on FormatException catch (e) {
      // 致命错误：帧提取失败，清理目录
      debugPrint('[VideoAnalysis] Fatal error (frame extraction): $e');
      await _cleanupSessionOnFatalError(sessionRoot);
      
      if (!controller.isClosed) {
        controller.add({
          'event': 'ERROR',
          'sessionId': sessionId,
          'code': '500_FRAME_EXTRACTION_ERROR',
          'message': 'Frame extraction failed: $e',
          'fatal': true,
        });
      }
      
    } on AiwaError catch (e) {
      // AiwaError系列：根据isRecoverable判断
      debugPrint('[VideoAnalysis] ⚠️  AiwaError caught: $e (recoverable: ${e.isRecoverable})');
      debugPrint('[VideoAnalysis] ⚠️  Current strictness: ${strictness.value}');
      
      if (e.isRecoverable && neutralSeries != null && qualityMetrics != null) {
        // 可恢复错误，尝试保存部分数据
        try {
          final partialResult = _buildPartialResult(
            neutralSeries: neutralSeries,
            failureCode: e.code,
            failureMessage: e.message,
            quality: qualityMetrics,
            strictnessOverride: strictness.value, // 传递strictness
          );
          
          await _savePartialOutputs(
            sessionRoot: sessionRoot,
            neutralSeries: neutralSeries,
            partialResult: partialResult,
          );
          
          if (!controller.isClosed) {
            controller.add({
              'event': 'DONE',
              'sessionId': sessionId,
              'partial': true,
              'partialReason': {
                'code': e.code,
                'message': e.message,
              },
              'artifacts': {
                'root': sessionRoot,
                'files': [
                  'neutral_keypoints.json',
                  'result.json',
                  'keypoints_overlay.mp4',
                  'logs/perf.json',
                ],
              },
            });
          }
        } catch (saveError) {
          debugPrint('[VideoAnalysis] Failed to save partial data: $saveError');
          if (!controller.isClosed) {
            controller.add({
              'event': 'ERROR',
              'sessionId': sessionId,
              'code': '500_INTERNAL',
              'message': 'Failed to save partial results: $saveError',
            });
          }
        }
      } else {
        // 致命错误或数据不足，清理并报错
        await _cleanupSessionOnFatalError(sessionRoot);
        if (!controller.isClosed) {
          controller.add({
            'event': 'ERROR',
            'sessionId': sessionId,
            'code': e.code,
            'message': e.message,
            'fatal': true,
          });
        }
      }
      
    } catch (e, st) {
      // 其他未知错误：致命错误，清理
      debugPrint('[VideoAnalysis] Unexpected error: $e\n$st');
      await _cleanupSessionOnFatalError(sessionRoot);
      
      if (!controller.isClosed) {
        controller.add({
          'event': 'ERROR',
          'sessionId': sessionId,
          'code': '500_INTERNAL',
          'message': 'Analysis failed: $e',
          'fatal': true,
        });
      }
    } finally {
      await engine?.close();
      if (!controller.isClosed) {
        controller.close();
      }
    }
  }

  /// 探测视频信息
  static Future<_VideoInfo> _probeVideo(String videoPath) async {
    VideoPlayerController? controller;
    
    try {
      controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();

      final size = controller.value.size;
      final duration = controller.value.duration;

      return _VideoInfo(
        path: videoPath,
        width: size.width.toInt(),
        height: size.height.toInt(),
        fps: 30.0, // 假设 30fps，VideoPlayer 不提供精确 fps
        durationMs: duration.inMilliseconds,
      );
    } finally {
      await controller?.dispose();
    }
  }

  /// 使用原生平台通道提取帧（流式处理，实时进度）
  /// 
  /// Android: MediaMetadataRetriever with EventChannel
  /// iOS: AVFoundation with EventChannel
  /// 
  /// 特性：
  /// - 实时进度更新（每帧报告）
  /// - 流式处理，内存占用低
  /// - 系统原生 API，性能优异
  /// - 限制输出分辨率（720p）
  /// - JPEG质量95%
  static Future<List<File>> _extractFrames({
    required CancellationToken token,
    required String videoPath,
    required Directory framesDir,
    required int stride,
    required _VideoInfo videoInfo,
    required StreamController<Map<String, dynamic>> controller,
    void Function(int, int)? onProgress,
  }) async {
    await framesDir.create(recursive: true);
    
    final targetFps = videoInfo.fps / stride;
    final totalFrames = (videoInfo.durationMs * targetFps / 1000).round();
    
    debugPrint('[VideoAnalysis] Extracting $totalFrames frames at ${targetFps}fps using native streaming API');
    
    // Validate video file exists
    final videoFile = File(videoPath);
    if (!await videoFile.exists()) {
      throw FormatException('Video file not found: $videoPath');
    }
    
    // Report initial progress
    onProgress?.call(0, totalFrames);
    
    final extractedFrames = <File>[];
    int frameIndex = 0;
    
    try {
      // Use stream-based extraction with real-time progress
      await for (final progress in NativeFrameExtractor.extractFramesWithProgress(
        videoPath: videoPath,
        targetFps: targetFps,
        maxWidth: 720,
        maxHeight: 1280,
        quality: 95,
        token: token,
      )) {
        // Check if cancelled
        if (token.isCancelling) {
          debugPrint('[VideoAnalysis] Cancellation detected during frame extraction');
          return extractedFrames; // Early exit
        }
        
        // Report progress immediately (every frame)
        onProgress?.call(progress.processed, progress.total);
        
        // Save frame if we have data
        if (progress.frameData != null) {
          final framePath = p.join(
            framesDir.path,
            'frame_${(frameIndex + 1).toString().padLeft(6, '0')}.jpg',
          );
          final file = File(framePath);
          await file.writeAsBytes(progress.frameData!);
          extractedFrames.add(file);
          frameIndex++;
        }
      }
      
      debugPrint('[VideoAnalysis] Successfully saved ${extractedFrames.length}/$totalFrames frames');
      
      return extractedFrames;
      
    } on NativeFrameExtractionException catch (e) {
      debugPrint('[VideoAnalysis] Native frame extraction error: ${e.code} - ${e.message}');
      throw FormatException('Native frame extraction failed: ${e.message}\nCode: ${e.code}\nDetails: ${e.details ?? "none"}');
    } catch (e) {
      debugPrint('[VideoAnalysis] Unexpected error during frame extraction: $e');
      throw FormatException('Frame extraction failed: $e');
    }
  }

  /// 使用 FrameStreamer（aiwa_core）进行姿态检测
  /// 
  /// ✅ 重构说明：
  /// - 复用 aiwa_core 的 FrameStreamer 替代手写推理循环
  /// - 统一日志与错误处理逻辑
  /// - 减少约 160 行重复代码
  static Future<FrameStreamResult> _inferPosesWithFrameStreamer({
    required CancellationToken token,
    required PoseEngine engine,
    required List<File> frames,
    required _VideoInfo videoInfo,
    required int stride,
    required StreamController<Map<String, dynamic>> controller,
    required Map<String, dynamic> engineInfo,
    void Function(int, int)? onProgress,
  }) async {
    // 创建 FrameStreamer 配置
    final config = FrameStreamerConfig(
      engineName: (engineInfo['name'] as String?) ?? 'unknown',
      modelName: (engineInfo['model'] as String?) ?? 'unknown',
      sdkVersion: (engineInfo['sdkVersion'] as String?) ?? 'unknown',
      videoBasename: 'video',
      fps: videoInfo.fps,
      stride: 1, // frames 已经过 stride 采样，这里设为 1
      mirror: false,
    );
    
    const engineConfig = PoseEngineConfig(
      preferAccurate: true,
      outputZ: false,
      minScore: 0.0, // 推理阶段不筛，后续质量统计时再判断
      returnEmptyWhenLow: false,
    );
    
    final streamer = FrameStreamer(
      engine: engine,
      engineConfig: engineConfig,
      config: config,
    );
    
    // 将 List<File> 转换为 Stream<RawImageFrame>
    final frameStream = _createFrameStream(
      frames: frames,
      videoInfo: videoInfo,
      token: token,
      onProgress: onProgress,
    );
    
    // 运行 FrameStreamer
    return await streamer.run(frameStream);
  }
  
  /// 创建帧流（从文件列表）
  static Stream<RawImageFrame> _createFrameStream({
    required List<File> frames,
    required _VideoInfo videoInfo,
    required CancellationToken token,
    void Function(int, int)? onProgress,
  }) async* {
    for (int idx = 0; idx < frames.length; idx++) {
      if (token.isCancelling) {
        debugPrint('[VideoAnalysis] Cancellation detected during frame streaming at $idx');
        return;
      }
      
      final frameFile = frames[idx];

      try {
        // 读取帧数据
          final frameBytes = await frameFile.readAsBytes();
        
        // 获取实际尺寸
        int actualWidth = videoInfo.width;
        int actualHeight = videoInfo.height;
        try {
          final codec = await ui.instantiateImageCodec(frameBytes);
          final frameImage = await codec.getNextFrame();
          actualWidth = frameImage.image.width;
          actualHeight = frameImage.image.height;
          frameImage.image.dispose();
        } catch (e) {
          debugPrint('[VideoAnalysis] Failed to read frame dimensions: $e');
        }

        // 调试日志（前 3 帧）
        if (idx < 3) {
          debugPrint('[VideoAnalysis] 🔍 Frame $idx:');
          debugPrint('[VideoAnalysis]   Size: $actualWidth x $actualHeight');
          debugPrint('[VideoAnalysis]   File: ${frameFile.path}');
        }

        yield RawImageFrame(
          bytes: frameBytes,
          width: actualWidth,
          height: actualHeight,
          rotationDeg: 0,
        );

      // 进度回调
      if (onProgress != null && ((idx + 1) % 10 == 0 || idx == frames.length - 1)) {
        onProgress(idx, frames.length);
      }
      } catch (e) {
        debugPrint('[VideoAnalysis] Failed to read frame $idx: $e');
        // 跳过损坏的帧
        continue;
      }
    }
  }

  // 🔧 已移除：_emptyFrameJson 函数，FrameStreamer 已处理空帧逻辑
  // 🔧 已移除：_inferPoses 手写推理循环（约 160 行），改用 FrameStreamer
  // 🔧 已移除：_landmarksToNeutral 函数，已被 adaptMlKitPose (keypoint_adapter.dart) 替代
  // 现在使用 PoseEngine 接口和 FrameStreamer 统一处理

  /// 构建 NeutralKeypointSeries
  static NeutralKeypointSeries _buildNeutralSeries({
    required List<Map<String, dynamic>> frameJsons,
    required _VideoInfo videoInfo,
    required int stride,
  }) {
    final effectiveFps = videoInfo.fps / stride;

    return NeutralKeypointSeries(
      version: 'vB1.1',
      video: NeutralVideoInfo(
        basename: p.basenameWithoutExtension(videoInfo.path),
        fpsIntended: videoInfo.fps,
        width: videoInfo.width,
        height: videoInfo.height,
        durationMs: videoInfo.durationMs,
      ),
      engine: const NeutralEngineInfo(
        name: 'mlkit',
        model: 'accurate',
        sdkVersion: 'google_mlkit_pose_detection@0.14.0',
      ),
      sampling: NeutralSamplingInfo(
        stride: stride,
        effectiveFps: effectiveFps,
      ),
      frames: frameJsons.map(_jsonToNeutralFrameData).toList(),
    );
  }

  /// JSON 转 NeutralFrameData
  static NeutralFrameData _jsonToNeutralFrameData(Map<String, dynamic> json) {
    return NeutralFrameData(
      frameIndex: json['frameIndex'] as int,
      timestampMs: json['timestampMs'] as int,
      lowConfidence: json['lowConfidence'] as bool,
      mirrorApplied: json['mirrorApplied'] as bool,
      keypoints: (json['keypoints'] as List).map((kp) {
        return NeutralKeypointValue(
          name: kp['name'] as String,
          x: (kp['x'] as num).toDouble(),
          y: (kp['y'] as num).toDouble(),
          z: (kp['z'] as num?)?.toDouble(),
          score: (kp['score'] as num).toDouble(),
        );
      }).toList(),
    );
  }

  /// 加载规则集
  static Future<RuleSet> _loadRuleSet() async {
    try {
      // 从 assets 加载 squat.v1.json
      final ruleStr = await rootBundle.loadString('assets/rules/squat.v1.json');
      return parseRuleSet(ruleStr);
    } catch (e) {
      throw Exception('Failed to load rule set: $e');
    }
  }

  /// 保存输出文件（离线三件套）
  static Future<void> _saveOutputs({
    required String sessionRoot,
    required NeutralKeypointSeries neutralSeries,
    required ({String anglesCsv, Map<String, dynamic> resultJson}) result,
  }) async {
    // 1. neutral_keypoints.json
    final neutralFile = File(p.join(sessionRoot, 'neutral_keypoints.json'));
    await neutralFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(neutralKeypointSeriesToJson(neutralSeries)),
    );

    // 2. result.json
    final resultFile = File(p.join(sessionRoot, 'result.json'));
    debugPrint('[VideoAnalysis] 💾 Saving result.json');
    debugPrint('[VideoAnalysis] 💾 meta.strictness: ${result.resultJson['meta']?['strictness']}');
    debugPrint('[VideoAnalysis] 💾 scores.form: ${result.resultJson['scores']?['form']}');
    debugPrint('[VideoAnalysis] 💾 scores.stability: ${result.resultJson['scores']?['stability']}');
    debugPrint('[VideoAnalysis] 💾 scores.tempo: ${result.resultJson['scores']?['tempo']}');
    debugPrint('[VideoAnalysis] 💾 scores.overall: ${result.resultJson['scores']?['overall']}');
    await resultFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(result.resultJson),
    );

    // 3. angles.csv
    final anglesFile = File(p.join(sessionRoot, 'angles.csv'));
    await anglesFile.writeAsString(result.anglesCsv);

    // 4. logs/perf.json
    final logsDir = Directory(p.join(sessionRoot, 'logs'));
    await logsDir.create(recursive: true);

    final perfLog = {
      'durationMs': neutralSeries.video.durationMs,
      'framesProcessed': neutralSeries.frames.length,
      'effectiveFps': neutralSeries.sampling.effectiveFps,
      'stride': neutralSeries.sampling.stride,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final perfFile = File(p.join(logsDir.path, 'perf.json'));
    await perfFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(perfLog),
    );
  }

  /// 镜像导出到外部存储（方便 adb pull）
  static Future<void> _mirrorToExternalStorage({
    required String sessionRoot,
  }) async {
    try {
      // 获取外部存储路径（Android/data/<pkg>/files）
      final extBase = await getExternalStorageDirectory();
      if (extBase == null) {
        debugPrint('[VideoAnalysis] ⚠️  External storage not available, skip mirroring');
        return;
      }

      // 创建导出目录
      final sessionName = p.basename(sessionRoot);
      final mirrorDir = Directory(
        p.join(extBase.path, 'export', sessionName),
      )..createSync(recursive: true);

      // 镜像所有输出文件
      final filesToMirror = [
        'neutral_keypoints.json',
        'result.json',
        'angles.csv',
        'logs/perf.json',
      ];

      var mirroredCount = 0;
      for (final relPath in filesToMirror) {
        final srcFile = File(p.join(sessionRoot, relPath));
        if (srcFile.existsSync()) {
          final dstPath = relPath.contains('/')
              ? p.join(mirrorDir.path, p.dirname(relPath), p.basename(relPath))
              : p.join(mirrorDir.path, relPath);
          final dstFile = File(dstPath);
          await dstFile.parent.create(recursive: true);
          await dstFile.writeAsBytes(
            await srcFile.readAsBytes(),
            flush: true,
          );
          mirroredCount++;
        }
      }

      debugPrint('[VideoAnalysis] 📦 Mirrored $mirroredCount files to: ${mirrorDir.path}');
      debugPrint('[VideoAnalysis] 💡 To pull: adb pull ${mirrorDir.path} ./');
    } on FileSystemException catch (e) {
      debugPrint('[VideoAnalysis] ⚠️  Mirror export failed: ${e.osError}');
      // 不抛出异常，导出失败不应影响主流程
    } catch (e) {
      debugPrint('[VideoAnalysis] ⚠️  Mirror export failed: $e');
    }
  }

  /// 生成降级版result.json
  static Map<String, dynamic> _buildPartialResult({
    required NeutralKeypointSeries neutralSeries,
    required String failureCode,
    required String failureMessage,
    required Map<String, dynamic> quality,
    String? strictnessOverride, // 新增参数：允许传入strictness
  }) {
    final totalFrames = neutralSeries.frames.length;
    final usableFrames = neutralSeries.frames
        .where((f) => !f.lowConfidence)
        .length;
    final usableRatio = totalFrames > 0 ? usableFrames / totalFrames : 0.0;
    
    // ⚠️ DEBUG: 记录降级结果生成
    final effectiveStrictness = strictnessOverride ?? 'relaxed';
    debugPrint('[VideoAnalysis] ⚠️  _buildPartialResult: generating partial result');
    debugPrint('[VideoAnalysis] ⚠️  failureCode: $failureCode');
    debugPrint('[VideoAnalysis] ⚠️  strictness (override=${strictnessOverride != null}): $effectiveStrictness');
    debugPrint('[VideoAnalysis] ⚠️  scores will be null (form, stability, tempo, overall)');
    
    return {
      'version': '2.0',
      'partial': true,
      'partialReason': {
        'code': failureCode,
        'message': failureMessage,
        'details': {
          'keypointsDetected': totalFrames,
          'usableFrames': usableFrames,
          'usableRatio': usableRatio,
          'failedStage': 'angle_computation',
          'availableData': ['keypoints', 'quality_metrics', 'frames'],
        },
      },
      'scores': {
        'form': null,
        'stability': null,
        'tempo': null,
        'overall': null,
      },
      'repCount': 0,
      'quality': quality,
      'meta': {
        'template': 'squat',
        'strictness': effectiveStrictness,
        'engine': neutralSeries.engine.name,
        'fps': neutralSeries.sampling.effectiveFps.round(),
      },
      'evidence': <Map<String, dynamic>>[],
    };
  }

  /// 保存部分输出（降级存储）
  static Future<void> _savePartialOutputs({
    required String sessionRoot,
    required NeutralKeypointSeries neutralSeries,
    required Map<String, dynamic> partialResult,
  }) async {
    debugPrint('[VideoAnalysis] 💾 _savePartialOutputs: saving partial result');
    debugPrint('[VideoAnalysis] 💾 partialResult.meta.strictness: ${partialResult['meta']?['strictness']}');
    debugPrint('[VideoAnalysis] 💾 partialResult.scores: ${partialResult['scores']}');
    
    // 1. 保存 neutral_keypoints.json（核心数据）
    final neutralFile = File(p.join(sessionRoot, 'neutral_keypoints.json'));
    await neutralFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(neutralKeypointSeriesToJson(neutralSeries)),
    );

    // 2. 保存降级版 result.json
    final resultFile = File(p.join(sessionRoot, 'result.json'));
    await resultFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(partialResult),
    );

    // 3. 保存性能日志
    final logsDir = Directory(p.join(sessionRoot, 'logs'));
    await logsDir.create(recursive: true);

    final perfLog = {
      'durationMs': neutralSeries.video.durationMs,
      'framesProcessed': neutralSeries.frames.length,
      'effectiveFps': neutralSeries.sampling.effectiveFps,
      'stride': neutralSeries.sampling.stride,
      'timestamp': DateTime.now().toIso8601String(),
      'partial': true,
      'partialReason': partialResult['partialReason'],
    };

    final perfFile = File(p.join(logsDir.path, 'perf.json'));
    await perfFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(perfLog),
    );

    debugPrint('[VideoAnalysis] Partial outputs saved (degraded mode)');
    debugPrint('[VideoAnalysis] - neutral_keypoints.json: ✓');
    debugPrint('[VideoAnalysis] - result.json (partial): ✓');
    debugPrint('[VideoAnalysis] - logs/perf.json: ✓');

    // 3.5. 镜像导出到外部存储（即使是降级模式也导出）
    await _mirrorToExternalStorage(sessionRoot: sessionRoot);

    // 4. Generate keypoint overlay video (best effort - don't fail if it errors)
    try {
      debugPrint('[VideoAnalysis] Generating keypoint overlay video...');
      final overlayVideoPath = await KeypointOverlayGenerator.generateOverlayVideo(
        sessionRoot: sessionRoot,
      );
      debugPrint('[VideoAnalysis] - keypoints_overlay.mp4: ✓ ($overlayVideoPath)');
    } catch (e, st) {
      debugPrint('[VideoAnalysis] WARNING: Failed to generate overlay video (non-fatal): $e');
      debugPrint('[VideoAnalysis] Stack trace: $st');
      // Don't throw - overlay video is optional, partial results are still valid
    }
  }

  /// 清理会话目录（仅限致命错误）
  static Future<void> _cleanupSessionOnFatalError(String sessionRoot) async {
    try {
      final sessionDir = Directory(sessionRoot);
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        debugPrint('[VideoAnalysis] Cleaned up session directory: $sessionRoot');
      }
    } catch (e) {
      debugPrint('[VideoAnalysis] Failed to cleanup session directory: $e');
      // 不抛出异常，避免掩盖原始错误
    }
  }

  // 🔧 已移除：_kNeutralKeypointNames 本地列表，改用 aiwa_core/pose/keypoint_names.dart 中的 kNeutralKeypointNames
  // 🔧 已移除：_kMlKitToNeutralMap 映射已不再使用
  // 现在使用 keypoint_adapter.dart 中的 adaptMlKitPose 函数进行转换
}
