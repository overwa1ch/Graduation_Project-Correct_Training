// lib/runner_orchestrator.dart
// Milestone B Runner Orchestrator (vB1.1) — 修正版：mlkit API 对齐 + 外部目录 + 导出镜像
//
// 变更要点：
// - ML Kit: google_mlkit_pose_detection 以别名 ml 引入，避免 PoseLandmark 等命名冲突。
// - PoseDetectionMode.single（单图模式）。
// - pose.landmarks 为 Map，按 Map 访问；33 点顺序用 leftFootIndex/rightFootIndex。
// - 中立关键点每个点包含 name/x/y/z/score，满足 Milestone A 解析要求。
// - 帧目录：内部优先 → 外部回退（App 使用 getExternalStorageDirectory 创建）。
// - 产物写内部，并镜像到外部 export 目录，方便 adb pull。

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show decodeImageFromList, Image;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// 以别名引入，避免与工程内类型冲突
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart'
    as ml;

import 'package:aiwa_core/spec/rule_parser.dart';
import 'package:aiwa_core/spec/rule_models.dart';
import 'package:aiwa_core/pipeline/offline_pipeline.dart';
import 'package:aiwa_core/pipeline/pose_series.dart';
import 'package:aiwa_core/pose/neutral_keypoint_series.dart';
import 'package:aiwa_core/pipeline/pose_input_converter.dart';

const String kDefaultPackageName = 'com.example.aiwa_runner';

class RunnerOrchestrator {
  RunnerOrchestrator({
    required this.videoAssetPath,
    required this.ruleAssetPath,
    required this.engineName, // 'mlkit'
    required this.engineModel, // 'blazepose-full'
    required this.inputResolutionLabel, // '720p'
    required this.fpsIntended, // 30
    required this.samplingStride, // 2
    required this.mirrorAppliedDefault, // false (后置)
    this.packageName = kDefaultPackageName,
    this.engineSdkVersion = 'google_mlkit_pose_detection',
  });

  final String videoAssetPath;
  final String ruleAssetPath;
  final String engineName;
  final String engineModel;
  final String inputResolutionLabel;
  final int fpsIntended;
  final int samplingStride;
  final bool mirrorAppliedDefault;

  final String packageName;
  final String engineSdkVersion;

  Future<String> run() async {
    // 1) 内部工作区（/data/.../app_flutter）
    final docsDir = await getApplicationDocumentsDirectory();
    final workspace = docsDir.path;

    final inputDir = Directory(p.join(workspace, 'input'))
      ..createSync(recursive: true);
    final rulesDir = Directory(p.join(workspace, 'rules'))
      ..createSync(recursive: true);
    final buildRoot = Directory(p.join(workspace, 'build', 'offline_out'))
      ..createSync(recursive: true);
    final logsDir = Directory(p.join(workspace, 'logs'))
      ..createSync(recursive: true);

    // 2) 拷贝资产（视频 & 规则）
    final videoBaseName = p.basenameWithoutExtension(videoAssetPath);
    final copiedVideo = await _copyAssetIfNeeded(
      assetPath: videoAssetPath,
      dstFile: File(p.join(inputDir.path, '$videoBaseName.mp4')),
    );
    final copiedRule = await _copyAssetIfNeeded(
      assetPath: ruleAssetPath,
      dstFile: File(p.join(rulesDir.path, p.basename(ruleAssetPath))),
    );

    final outDir = Directory(p.join(buildRoot.path, videoBaseName))
      ..createSync(recursive: true);

    debugPrint('[BOOT] Workspace: ${docsDir.path}');
    debugPrint('[BOOT] Input video: ${copiedVideo.path}');
    debugPrint('[BOOT] Rule file:   ${copiedRule.path}');
    debugPrint('[BOOT] Output dir:  ${outDir.path}');

    // 3) 帧目录定位：内部优先，其次外部专属目录（由 App 自己创建）
    final internalFramesDir = Directory(
      p.join(inputDir.path, 'frames', videoBaseName),
    );

    Directory? externalFramesDir;
    String? extBasePath;
    try {
      final extBase =
          await getExternalStorageDirectory(); // /storage/emulated/0/Android/data/<pkg>/files
      if (extBase != null) {
        extBasePath = extBase.path;
        debugPrint('[INFO] 外部基路径：$extBasePath');
        externalFramesDir = Directory(
          p.join(extBase.path, 'input', 'frames', videoBaseName),
        )..createSync(recursive: true); // 为 adb push 准备好路径
      } else {
        debugPrint('[WARN] getExternalStorageDirectory() 返回 null，仅尝试内部目录');
      }
    } on FileSystemException catch (e) {
      debugPrint(
        '[ERROR] 创建外部帧目录失败: ${externalFramesDir?.path} | ${e.osError}',
      );
    }

    late final Directory framesDir;
    if (internalFramesDir.existsSync()) {
      framesDir = internalFramesDir;
    } else if (externalFramesDir != null && externalFramesDir.existsSync()) {
      framesDir = externalFramesDir;
      debugPrint('[INFO] 使用外部帧目录：${framesDir.path}');
    } else {
      _printExtractHint(
        internalPath: internalFramesDir.path,
        externalBasePath: extBasePath,
        basename: videoBaseName,
        videoAbsPath: copiedVideo.path,
      );
      throw StateError('未找到任何帧文件，请按提示先抽帧。');
    }

    // 4) 列举帧（仅 jpg/jpeg），排序 + stride 采样
    final allFrames =
        framesDir
            .listSync()
            .whereType<File>()
            .where((f) => _isFrameJpg(f.path))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    if (allFrames.isEmpty) {
      _printExtractHint(
        internalPath: internalFramesDir.path,
        externalBasePath: extBasePath,
        basename: videoBaseName,
        videoAbsPath: copiedVideo.path,
      );
      throw StateError('未找到任何帧文件，请按提示先抽帧。');
    }

    // 推断图像尺寸（解首帧）
    final firstBytes = await allFrames.first.readAsBytes();
    final ui.Image firstImg = await _decodeImage(
      Uint8List.fromList(firstBytes),
    );
    final width = firstImg.width;
    final height = firstImg.height;

    // 按帧率估算时长
    final durationMs = (allFrames.length / fpsIntended * 1000).round();

    // 5) 初始化 ML Kit PoseDetector（accurate + single）
    final detector = ml.PoseDetector(
      options: ml.PoseDetectorOptions(
        model: ml.PoseDetectionModel.accurate,
        mode: ml.PoseDetectionMode.single, // ✅ 正确枚举
      ),
    );

    // 6) 逐帧推理 → vB1.1 中立关键点
    final framesOut = <Map<String, dynamic>>[];
    final inferTimes = <int>[];

    final progressSw = Stopwatch()..start();
    var lastProgMs = 0;

    final total = allFrames.length;
    var usableCount = 0;
    var lowConfCount = 0;

    for (int i = 0; i < total; i += samplingStride) {
      final f = allFrames[i];
      final frameIndex = i; // 原始帧号（与 30fps 时序对应）
      final tsMs = ((frameIndex / fpsIntended) * 1000).round();

      final image = ml.InputImage.fromFilePath(f.path);

      final sw = Stopwatch()..start();
      final poses = await detector.processImage(image);
      sw.stop();
      inferTimes.add(sw.elapsedMilliseconds);

      Map<String, dynamic> frameJson;
      if (poses.isEmpty) {
        // 空结果：按 33 个命名点占位
        frameJson = _emptyFrameJson(
          width: width,
          height: height,
          frameIndex: frameIndex,
          timestampMs: tsMs,
          mirrorApplied: mirrorAppliedDefault,
        );
        lowConfCount++;
      } else {
        final ml.Pose pose = poses.first;

        // 关键：该插件版本 pose.landmarks 是 Map
        final Map<ml.PoseLandmarkType, ml.PoseLandmark> lm = pose.landmarks;

        final mapped = _landmarksToNeutral33(
          lm,
          imgW: width,
          imgH: height,
          mirror: mirrorAppliedDefault,
        );

        final avgScore = mapped.isEmpty
            ? 0.0
            : mapped
                      .map((e) => (e['score'] as num?)?.toDouble() ?? 0.0)
                      .reduce((a, b) => a + b) /
                  mapped.length;

        final lowConf = avgScore < 0.7; // 简单阈值，仅作标记
        if (!lowConf)
          usableCount++;
        else
          lowConfCount++;

        frameJson = {
          'frameIndex': frameIndex,
          'timestampMs': tsMs,
          'mirrorApplied': mirrorAppliedDefault,
          'lowConfidence': lowConf,
          'keypoints': mapped, // 含 name/x/y/z/score
        };
      }

      framesOut.add(frameJson);

      // 每 ~2 秒输出进度
      final nowMs = progressSw.elapsedMilliseconds;
      if (nowMs - lastProgMs >= 2000 || i + samplingStride >= total) {
        final avgMs = inferTimes.isEmpty
            ? 0
            : inferTimes.reduce((a, b) => a + b) ~/ inferTimes.length;
        final usableRatio = framesOut.isEmpty
            ? 0
            : (usableCount * 100 ~/ framesOut.length);
        final lowConfRatio = framesOut.isEmpty
            ? 0
            : (lowConfCount * 100 ~/ framesOut.length);
        debugPrint(
          '[PROG] frames ${framesOut.length}/${(total / samplingStride).ceil()} | '
          'avg ${avgMs} ms | usable ${usableRatio}% | lowConf ${lowConfRatio}%',
        );
        lastProgMs = nowMs;
      }
    }

    await detector.close();

    // 7) 组装 vB1.1 顶层 JSON（中立关键点）
    final neutralRoot = <String, dynamic>{
      'version': 'vB1.1',
      'video': {
        'basename': videoBaseName,
        'width': width,
        'height': height,
        'durationMs': durationMs,
        'fpsIntended': fpsIntended,
      },
      'engine': {
        'name': engineName, // 'mlkit'
        'model': engineModel, // 'blazepose-full'
        'sdkVersion': engineSdkVersion,
      },
      'sampling': {
        'stride': samplingStride,
        'effectiveFps': (fpsIntended / samplingStride).round(),
      },
      'frames': framesOut,
    };

    // 写 neutral_keypoints.json
    final neutralFile = File(p.join(outDir.path, 'neutral_keypoints.json'));
    neutralFile.createSync(recursive: true);
    await neutralFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(neutralRoot),
    );

    // 8) 离线管线（Milestone A）
    final ruleStr = await File(copiedRule.path).readAsString();
    final RuleSet rs = parseRuleSet(ruleStr);

    final neutralSeries = parseNeutralKeypointSeriesFromMap(neutralRoot);
    final PoseSeries poseSeries = poseSeriesFromNeutral(neutralSeries);

    final pipeline = OfflinePipeline(
      rs,
      Strictness.relaxed, // 如需严格评估可改为 Strictness.strict
    );

    final out = await pipeline.run(poseSeries);

    // 9) angles.csv / result.json（注入 4 字段）
    final anglesCsvFile = File(p.join(outDir.path, 'angles.csv'));
    await anglesCsvFile.writeAsString(out.anglesCsv);

    final resultMap =
        json.decode(json.encode(out.resultJson)) as Map<String, dynamic>;
    resultMap['engine'] = engineName;
    resultMap['engineVersion'] = engineSdkVersion;
    resultMap['inputResolution'] = inputResolutionLabel;
    resultMap['samplingStride'] = samplingStride;

    final resultFile = File(p.join(outDir.path, 'result.json'));
    await resultFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(resultMap),
    );

    // 10) 写性能日志 logs/perf.json
    final perf = _buildPerf(
      inferTimes,
      totalFramesTried: framesOut.length,
      usable: usableCount,
      lowConf: lowConfCount,
    );
    final perfFile = File(p.join(logsDir.path, 'perf.json'));
    await perfFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(perf),
    );

    debugPrint('[OUT] neutral_keypoints.json → ${neutralFile.path}');
    debugPrint('[DONE] Output dir: ${outDir.path}');

    // 11) 镜像导出到外部：/files/export/<basename>/ 便于 adb pull
    try {
      final extBase = await getExternalStorageDirectory();
      if (extBase != null) {
        final mirrorDir = Directory(
          p.join(extBase.path, 'export', videoBaseName),
        )..createSync(recursive: true);
        for (final f in Directory(outDir.path).listSync().whereType<File>()) {
          final dst = File(p.join(mirrorDir.path, p.basename(f.path)));
          await dst.writeAsBytes(await f.readAsBytes(), flush: true);
        }
        debugPrint('[OUT] Mirrored to ${mirrorDir.path}');
      } else {
        debugPrint('[WARN] 无法镜像导出：getExternalStorageDirectory() 返回 null');
      }
    } on FileSystemException catch (e) {
      debugPrint('[WARN] 镜像导出失败: ${e.osError}');
    }

    debugPrint('[DONE] Saved to ${outDir.path}');
    return outDir.path;
  }

  // —— 工具方法 —— //

  static bool _isFrameJpg(String path) {
    final name = p.basename(path).toLowerCase();
    return name.endsWith('.jpg') || name.endsWith('.jpeg');
  }

  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final c = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, (img) => c.complete(img));
    return c.future;
  }

  Future<File> _copyAssetIfNeeded({
    required String assetPath,
    required File dstFile,
  }) async {
    if (dstFile.existsSync()) return dstFile;
    try {
      final data = await rootBundle.load(assetPath);
      dstFile.createSync(recursive: true);
      await dstFile.writeAsBytes(data.buffer.asUint8List());
      return dstFile;
    } catch (e) {
      throw StateError('Unable to load asset: "$assetPath".');
    }
  }

  static void _printExtractHint({
    required String internalPath,
    required String? externalBasePath,
    required String basename,
    required String videoAbsPath,
  }) {
    debugPrint('[HINT] 未检测到帧目录：');
    debugPrint('  内部：$internalPath');
    if (externalBasePath != null) {
      debugPrint('  外部：$externalBasePath/input/frames/$basename');
    } else {
      debugPrint('  外部：<未能获取 getExternalStorageDirectory()>');
    }
    debugPrint('请先抽帧（30 fps），命名为 frame_00001.jpg, frame_00002.jpg, ...');
    final extHint =
        externalBasePath ??
        '/storage/emulated/0/Android/data/$kDefaultPackageName/files';
    debugPrint('示例命令（电脑端 ffmpeg → adb push 到外部专属目录）：');
    debugPrint(
      '  ffmpeg -y -i "$videoAbsPath" '
      '-vf "fps=30,scale=1280:720:force_original_aspect_ratio=decrease" -qscale:v 2 frame_%05d.jpg',
    );
    debugPrint('  adb push frame_*.jpg "$extHint/input/frames/$basename/"');
  }

  /// 将 ML Kit 的 33 点映射为中立 33 点（按 Google BlazePose 标准顺序），并带 name 字段。
  static List<Map<String, dynamic>> _landmarksToNeutral33(
    Map<ml.PoseLandmarkType, ml.PoseLandmark> lm, {
    required int imgW,
    required int imgH,
    required bool mirror,
  }) {
    const order = <ml.PoseLandmarkType>[
      ml.PoseLandmarkType.nose,
      ml.PoseLandmarkType.leftEyeInner,
      ml.PoseLandmarkType.leftEye,
      ml.PoseLandmarkType.leftEyeOuter,
      ml.PoseLandmarkType.rightEyeInner,
      ml.PoseLandmarkType.rightEye,
      ml.PoseLandmarkType.rightEyeOuter,
      ml.PoseLandmarkType.leftEar,
      ml.PoseLandmarkType.rightEar,
      ml.PoseLandmarkType.leftMouth,
      ml.PoseLandmarkType.rightMouth,
      ml.PoseLandmarkType.leftShoulder,
      ml.PoseLandmarkType.rightShoulder,
      ml.PoseLandmarkType.leftElbow,
      ml.PoseLandmarkType.rightElbow,
      ml.PoseLandmarkType.leftWrist,
      ml.PoseLandmarkType.rightWrist,
      ml.PoseLandmarkType.leftPinky,
      ml.PoseLandmarkType.rightPinky,
      ml.PoseLandmarkType.leftIndex,
      ml.PoseLandmarkType.rightIndex,
      ml.PoseLandmarkType.leftThumb,
      ml.PoseLandmarkType.rightThumb,
      ml.PoseLandmarkType.leftHip,
      ml.PoseLandmarkType.rightHip,
      ml.PoseLandmarkType.leftKnee,
      ml.PoseLandmarkType.rightKnee,
      ml.PoseLandmarkType.leftAnkle,
      ml.PoseLandmarkType.rightAnkle,
      ml.PoseLandmarkType.leftHeel,
      ml.PoseLandmarkType.rightHeel,
      ml.PoseLandmarkType.leftFootIndex,
      ml.PoseLandmarkType.rightFootIndex,
    ];

    const names = <String>[
      'nose',
      'leftEyeInner',
      'leftEye',
      'leftEyeOuter',
      'rightEyeInner',
      'rightEye',
      'rightEyeOuter',
      'leftEar',
      'rightEar',
      'leftMouth',
      'rightMouth',
      'leftShoulder',
      'rightShoulder',
      'leftElbow',
      'rightElbow',
      'leftWrist',
      'rightWrist',
      'leftPinky',
      'rightPinky',
      'leftIndex',
      'rightIndex',
      'leftThumb',
      'rightThumb',
      'leftHip',
      'rightHip',
      'leftKnee',
      'rightKnee',
      'leftAnkle',
      'rightAnkle',
      'leftHeel',
      'rightHeel',
      'leftFootIndex',
      'rightFootIndex',
    ];

    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < order.length; i++) {
      final t = order[i];
      final n = names[i];
      final l = lm[t];
      if (l == null) {
        out.add({'name': n, 'x': 0.0, 'y': 0.0, 'z': 0.0, 'score': 0.0});
        continue;
      }
      var nx = (l.x / imgW).clamp(0.0, 1.0);
      final ny = (l.y / imgH).clamp(0.0, 1.0);
      final score = (l.likelihood).clamp(0.0, 1.0);
      if (mirror) nx = 1.0 - nx;
      out.add({'name': n, 'x': nx, 'y': ny, 'z': 0.0, 'score': score});
    }
    return out;
  }

  static Map<String, dynamic> _emptyFrameJson({
    required int width,
    required int height,
    required int frameIndex,
    required int timestampMs,
    required bool mirrorApplied,
  }) {
    const names = <String>[
      'nose',
      'leftEyeInner',
      'leftEye',
      'leftEyeOuter',
      'rightEyeInner',
      'rightEye',
      'rightEyeOuter',
      'leftEar',
      'rightEar',
      'leftMouth',
      'rightMouth',
      'leftShoulder',
      'rightShoulder',
      'leftElbow',
      'rightElbow',
      'leftWrist',
      'rightWrist',
      'leftPinky',
      'rightPinky',
      'leftIndex',
      'rightIndex',
      'leftThumb',
      'rightThumb',
      'leftHip',
      'rightHip',
      'leftKnee',
      'rightKnee',
      'leftAnkle',
      'rightAnkle',
      'leftHeel',
      'rightHeel',
      'leftFootIndex',
      'rightFootIndex',
    ];

    final kp = [
      for (final n in names)
        {'name': n, 'x': 0.0, 'y': 0.0, 'z': 0.0, 'score': 0.0},
    ];

    return {
      'frameIndex': frameIndex,
      'timestampMs': timestampMs,
      'mirrorApplied': mirrorApplied,
      'lowConfidence': true,
      'keypoints': kp,
    };
  }

  static Map<String, dynamic> _buildPerf(
    List<int> ms, {
    required int totalFramesTried,
    required int usable,
    required int lowConf,
  }) {
    ms.sort();
    final avg = ms.isEmpty ? 0 : ms.reduce((a, b) => a + b) ~/ ms.length;
    final p95 = ms.isEmpty
        ? 0
        : ms[(ms.length * 95 ~/ 100).clamp(0, ms.length - 1)];
    final usableRatio = totalFramesTried == 0 ? 0.0 : usable / totalFramesTried;
    final lowConfRatio = totalFramesTried == 0
        ? 0.0
        : lowConf / totalFramesTried;
    return {
      'avgInferenceMs': avg,
      'p95InferenceMs': p95,
      'totalFramesTried': totalFramesTried,
      'usableFrameRatio': double.parse(usableRatio.toStringAsFixed(4)),
      'lowConfidenceRatio': double.parse(lowConfRatio.toStringAsFixed(4)),
    };
  }
}
