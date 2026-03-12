import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';

enum TrackState {
  idle,
  selectingPoint,
  processing,
  playback,
  error,
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const _uuid = Uuid();

  final ImagePicker _picker = ImagePicker();

  TrackState _state = TrackState.idle;
  String? _sourceVideoPath;
  String? _processedVideoPath;
  String? _errorMessage;
  ui.Image? _firstFrame;
  Size _frameSize = Size.zero;
  Offset? _anchorNorm;
  VideoPlayerController? _playerCtrl;
  final List<Offset> _trajectory = <Offset>[];

  double _progress = 0;
  String _progressMessage = '';
  Color _trajectoryColor = Colors.cyanAccent;
  int _tailLength = 90;

  @override
  void dispose() {
    _disposePreviewImage();
    _disposePlayer();
    super.dispose();
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );
    if (video != null) {
      await _loadVideo(video.path);
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      await _loadVideo(video.path);
    }
  }

  Future<void> _loadVideo(String path) async {
    _disposePlayer();
    _disposePreviewImage();
    await _deleteProcessedVideoIfExists();

    setState(() {
      _state = TrackState.selectingPoint;
      _sourceVideoPath = path;
      _processedVideoPath = null;
      _errorMessage = null;
      _firstFrame = null;
      _frameSize = Size.zero;
      _anchorNorm = null;
      _trajectory.clear();
      _progress = 0;
      _progressMessage = '正在提取首帧...';
    });

    cv.VideoCapture? capture;
    try {
      capture = cv.VideoCapture.fromFile(path, apiPreference: cv.CAP_ANY);
      if (!capture.isOpened) {
        throw Exception('无法打开所选视频。');
      }

      final (ok, frame) = capture.read();
      if (!ok || frame.isEmpty) {
        throw Exception('无法读取首帧。');
      }

      final rgba = await cv.cvtColorAsync(frame, cv.COLOR_BGR2RGBA);
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        Uint8List.fromList(rgba.data),
        rgba.cols,
        rgba.rows,
        ui.PixelFormat.rgba8888,
        completer.complete,
      );
      final image = await completer.future;

      if (!mounted) {
        image.dispose();
        return;
      }

      setState(() {
        _firstFrame = image;
        _frameSize = Size(rgba.cols.toDouble(), rgba.rows.toDouble());
        _progressMessage = '';
      });
    } catch (error) {
      _setError('视频准备失败：$error');
    } finally {
      capture?.release();
      capture?.dispose();
    }
  }

  void _onFrameTap(Offset localPosition, Size renderSize) {
    if (renderSize.width <= 0 || renderSize.height <= 0) {
      return;
    }
    final normalized = Offset(
      (localPosition.dx / renderSize.width).clamp(0.0, 1.0),
      (localPosition.dy / renderSize.height).clamp(0.0, 1.0),
    );
    setState(() => _anchorNorm = normalized);
  }

  Future<void> _startTracking() async {
    final sourceVideoPath = _sourceVideoPath;
    final anchorNorm = _anchorNorm;
    if (sourceVideoPath == null ||
        anchorNorm == null ||
        _frameSize == Size.zero) {
      return;
    }

    _disposePlayer();
    await _deleteProcessedVideoIfExists();

    setState(() {
      _state = TrackState.processing;
      _errorMessage = null;
      _progress = 0;
      _progressMessage = '正在初始化追踪...';
      _trajectory.clear();
      _processedVideoPath = null;
    });

    cv.VideoCapture? capture;
    cv.VideoWriter? writer;
    cv.TrackerMIL? tracker;
    cv.Rect? initialRect;
    File? outputFile;

    try {
      capture = cv.VideoCapture.fromFile(
        sourceVideoPath,
        apiPreference: cv.CAP_ANY,
      );
      if (!capture.isOpened) {
        throw Exception('无法重新打开原视频。');
      }

      final totalFrames = capture.get(cv.CAP_PROP_FRAME_COUNT).round();
      final rawFps = capture.get(cv.CAP_PROP_FPS);
      final fps = rawFps > 0 ? rawFps : 30.0;

      final (ok, firstMat) = capture.read();
      if (!ok || firstMat.isEmpty) {
        throw Exception('无法读取起始帧。');
      }

      initialRect = _buildInitialRect(anchorNorm);
      tracker = cv.TrackerMIL.create();
      tracker.init(firstMat, initialRect);

      final output = await _tryCreateWriter(
        frameSize: (firstMat.cols, firstMat.rows),
        fps: fps,
      );
      if (output != null) {
        outputFile = output.file;
        writer = output.writer;
      }

      final trajectoryPixels = <cv.Point>[];
      final normalizedTrajectory = <Offset>[];
      final anchorPoint = _toPixelPoint(anchorNorm);
      trajectoryPixels.add(anchorPoint);
      normalizedTrajectory.add(anchorNorm);

      if (writer != null) {
        _drawTrajectoryOnFrame(firstMat, trajectoryPixels);
        writer.write(firstMat);
      }

      var processedFrames = 1;
      while (true) {
        final (frameOk, frame) = capture.read();
        if (!frameOk || frame.isEmpty) {
          break;
        }

        final (tracked, bbox) = tracker.update(frame);
        if (tracked) {
          final point = _pointFromRect(bbox);
          trajectoryPixels.add(point);
          normalizedTrajectory.add(_toNormalizedOffset(point));
        } else if (trajectoryPixels.isNotEmpty) {
          trajectoryPixels.add(trajectoryPixels.last);
          normalizedTrajectory.add(normalizedTrajectory.last);
        }

        if (writer != null) {
          _drawTrajectoryOnFrame(frame, trajectoryPixels);
          writer.write(frame);
        }

        processedFrames += 1;
        if (mounted && processedFrames % 8 == 0) {
          setState(() {
            _progress = totalFrames > 0
                ? (processedFrames / totalFrames).clamp(0.0, 1.0)
                : 0;
            _progressMessage =
                '正在追踪帧 $processedFrames${totalFrames > 0 ? ' / $totalFrames' : ''}';
          });
          await Future<void>.delayed(Duration.zero);
        }
      }

      if (writer != null) {
        writer.release();
        writer.dispose();
        writer = null;
      }

      VideoPlayerController? controller;
      if (outputFile != null) {
        final exists = await outputFile.exists();
        final fileLength = exists ? await outputFile.length() : 0;
        if (exists && fileLength > 0) {
          try {
            controller = VideoPlayerController.file(outputFile);
            await controller.initialize();
            await controller.setLooping(true);
          } catch (error) {
            debugPrint('Baked playback unavailable, falling back: $error');
            await controller?.dispose();
            controller = null;
            await _deleteProcessedVideoIfExists(outputFile.path);
            outputFile = null;
          }
        } else {
          await _deleteProcessedVideoIfExists(outputFile.path);
          outputFile = null;
        }
      }

      if (controller == null) {
        controller = VideoPlayerController.file(File(sourceVideoPath));
        await controller.initialize();
        await controller.setLooping(true);
      }

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _processedVideoPath = outputFile?.path;
        _playerCtrl = controller;
        _trajectory
          ..clear()
          ..addAll(normalizedTrajectory);
        _state = TrackState.playback;
        _progress = 1;
        _progressMessage = '';
      });

      if (outputFile == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '当前设备暂不支持导出带轨迹视频，已切换为实时叠加预览。',
            ),
          ),
        );
      }

      unawaited(controller.play());
    } catch (error) {
      _setError('追踪失败：$error');
    } finally {
      initialRect?.dispose();
      capture?.release();
      capture?.dispose();
      writer?.release();
      writer?.dispose();
      tracker?.dispose();
    }
  }

  cv.Rect _buildInitialRect(Offset anchorNorm) {
    final boxSize = math.max(28, (_frameSize.shortestSide * 0.08).round());
    final maxLeft = math.max(0, _frameSize.width.round() - boxSize);
    final maxTop = math.max(0, _frameSize.height.round() - boxSize);
    final left = _clampInt(
      (anchorNorm.dx * _frameSize.width - boxSize / 2).round(),
      0,
      maxLeft,
    );
    final top = _clampInt(
      (anchorNorm.dy * _frameSize.height - boxSize / 2).round(),
      0,
      maxTop,
    );
    return cv.Rect(left, top, boxSize, boxSize);
  }

  cv.Point _toPixelPoint(Offset normalizedPoint) {
    final x = _clampInt(
      (normalizedPoint.dx * _frameSize.width).round(),
      0,
      math.max(0, _frameSize.width.round() - 1),
    );
    final y = _clampInt(
      (normalizedPoint.dy * _frameSize.height).round(),
      0,
      math.max(0, _frameSize.height.round() - 1),
    );
    return cv.Point(x, y);
  }

  cv.Point _pointFromRect(cv.Rect rect) {
    final centerX = rect.x + (rect.width / 2).round();
    final centerY = rect.y + (rect.height / 2).round();
    return cv.Point(
      _clampInt(centerX, 0, math.max(0, _frameSize.width.round() - 1)),
      _clampInt(centerY, 0, math.max(0, _frameSize.height.round() - 1)),
    );
  }

  Offset _toNormalizedOffset(cv.Point point) {
    if (_frameSize.width <= 0 || _frameSize.height <= 0) {
      return Offset.zero;
    }
    return Offset(
      (point.x / _frameSize.width).clamp(0.0, 1.0),
      (point.y / _frameSize.height).clamp(0.0, 1.0),
    );
  }

  void _drawTrajectoryOnFrame(cv.Mat frame, List<cv.Point> trajectory) {
    if (trajectory.isEmpty) {
      return;
    }

    final startIndex = math.max(0, trajectory.length - _tailLength);
    final segmentCount = math.max(1, trajectory.length - startIndex - 1);
    for (var index = startIndex; index < trajectory.length - 1; index += 1) {
      final progress = (index - startIndex + 1) / segmentCount;
      cv.line(
        frame,
        trajectory[index],
        trajectory[index + 1],
        _toCvScalar(_trajectoryColor, alpha: 0.3 + (0.7 * progress)),
        thickness: 2 + (progress * 3).round(),
        lineType: cv.LINE_AA,
      );
    }

    final head = trajectory.last;
    cv.circle(
      frame,
      head,
      6,
      _toCvScalar(_trajectoryColor),
      thickness: -1,
    );
    cv.circle(
      frame,
      head,
      12,
      _toCvScalar(Colors.white, alpha: 0.5),
      thickness: 2,
    );
  }

  cv.Scalar _toCvScalar(Color color, {double alpha = 1.0}) {
    final argb = color.toARGB32();
    final red = ((argb >> 16) & 0xFF).toDouble();
    final green = ((argb >> 8) & 0xFF).toDouble();
    final blue = (argb & 0xFF).toDouble();
    return cv.Scalar(
      blue,
      green,
      red,
      (alpha.clamp(0.0, 1.0) * 255).toDouble(),
    );
  }

  Future<_TrackingWriterOutput?> _tryCreateWriter({
    required (int, int) frameSize,
    required double fps,
  }) async {
    final outputFile = await _createOutputFile(extension: 'mp4');
    final writer = cv.VideoWriter.fromFile(
      outputFile.path,
      'mp4v',
      fps,
      frameSize,
      isColor: true,
    );
    if (writer.isOpened) {
      return _TrackingWriterOutput(file: outputFile, writer: writer);
    }

    writer.release();
    writer.dispose();
    await _deleteProcessedVideoIfExists(outputFile.path);
    return null;
  }

  Future<File> _createOutputFile({String extension = 'mp4'}) async {
    final tempDir = await getTemporaryDirectory();
    return File(p.join(tempDir.path, 'tracked_${_uuid.v4()}.$extension'));
  }

  Future<void> _deleteProcessedVideoIfExists([String? overridePath]) async {
    final processedVideoPath = overridePath ?? _processedVideoPath;
    if (processedVideoPath == null) {
      return;
    }

    try {
      final file = File(processedVideoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore temp-file cleanup failures and keep the tracking flow moving.
    }
  }

  Future<void> _saveVideoToGallery() async {
    final processedVideoPath = _processedVideoPath;
    if (processedVideoPath == null) {
      return;
    }

    try {
      final granted = await _ensureGalleryAccess();
      if (!granted) {
        throw Exception('未获得相册权限。');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在保存视频...')),
        );
      }

      await Gal.putVideo(processedVideoPath);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('视频已保存到相册。'),
          backgroundColor: AppColors.brandPrimaryVariant,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存视频失败：$error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<bool> _ensureGalleryAccess() async {
    final hasAccess = await Gal.hasAccess();
    if (hasAccess) {
      return true;
    }
    await Gal.requestAccess();
    return Gal.hasAccess();
  }

  Future<void> _showVideoExportUnavailable() async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '当前设备暂不支持导出视频，请改用“保存轨迹图”。',
        ),
      ),
    );
  }

  Future<void> _saveTrajectoryImage() async {
    if (_trajectory.isEmpty) {
      return;
    }

    try {
      final granted = await _ensureGalleryAccess();
      if (!granted) {
        throw Exception('未获得相册权限。');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在保存轨迹图...')),
        );
      }

      final bytes = await _renderTrajectoryImageBytes();
      await Gal.putImageBytes(
        bytes,
        name: 'trajectory_${_uuid.v4()}',
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('轨迹图已保存到相册。'),
          backgroundColor: AppColors.brandPrimaryVariant,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存轨迹图失败：$error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<Uint8List> _renderTrajectoryImageBytes() async {
    final canvasSize =
        _frameSize == Size.zero ? const Size(1080, 1080) : _frameSize;
    final width = math.max(1, canvasSize.width.round());
    final height = math.max(1, canvasSize.height.round());

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );

    final backgroundPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(width.toDouble(), height.toDouble()),
        <Color>[
          const Color(0xFF10151C),
          const Color(0xFF1B2430),
        ],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      backgroundPaint,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const gridDivisions = 6;
    for (var i = 1; i < gridDivisions; i += 1) {
      final dx = (width / gridDivisions) * i;
      final dy = (height / gridDivisions) * i;
      canvas.drawLine(
        Offset(dx.toDouble(), 0),
        Offset(dx.toDouble(), height.toDouble()),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, dy.toDouble()),
        Offset(width.toDouble(), dy.toDouble()),
        gridPaint,
      );
    }

    _paintTrajectory(
      canvas,
      size: Size(width.toDouble(), height.toDouble()),
      trajectory: _trajectory,
      trajectoryColor: _trajectoryColor,
      startIndex: 0,
      endIndex: _trajectory.length - 1,
    );

    final image = await recorder.endRecording().toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw Exception('轨迹图编码失败。');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _showSettingsSheet() async {
    final result = await showModalBottomSheet<_TrackingSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfacePrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: _TrackingSettingsSheet(
            color: _trajectoryColor,
            tailLength: _tailLength,
            canReprocess: _sourceVideoPath != null &&
                _anchorNorm != null &&
                _state == TrackState.playback,
          ),
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _trajectoryColor = result.color;
      _tailLength = result.tailLength;
    });

    if (result.reprocess) {
      await _startTracking();
    }
  }

  void _reselectAnchor() {
    final processedVideoPath = _processedVideoPath;
    _disposePlayer();
    unawaited(_deleteProcessedVideoIfExists(processedVideoPath));
    setState(() {
      _state = TrackState.selectingPoint;
      _processedVideoPath = null;
      _anchorNorm = null;
      _trajectory.clear();
      _progress = 0;
      _progressMessage = '';
      _errorMessage = null;
    });
  }

  void _reset() {
    final processedVideoPath = _processedVideoPath;
    _disposePlayer();
    _disposePreviewImage();
    unawaited(_deleteProcessedVideoIfExists(processedVideoPath));
    setState(() {
      _state = TrackState.idle;
      _sourceVideoPath = null;
      _processedVideoPath = null;
      _errorMessage = null;
      _frameSize = Size.zero;
      _anchorNorm = null;
      _trajectory.clear();
      _progress = 0;
      _progressMessage = '';
    });
  }

  void _setError(String message) {
    _disposePlayer();
    if (!mounted) {
      return;
    }
    setState(() {
      _state = TrackState.error;
      _errorMessage = message;
      _progressMessage = '';
    });
  }

  void _disposePlayer() {
    _playerCtrl?.dispose();
    _playerCtrl = null;
  }

  void _disposePreviewImage() {
    _firstFrame?.dispose();
    _firstFrame = null;
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '轨迹追踪',
      currentNavIndex: 0,
      showAppBar: true,
      showBottomNav: false,
      automaticallyImplyLeading: true,
      actions: <Widget>[
        IconButton(
          key: const ValueKey('action.tracking_settings'),
          tooltip: '追踪设置',
          onPressed: _showSettingsSheet,
          icon: const Icon(Icons.tune, color: AppColors.textInvert),
        ),
        if (_state != TrackState.idle)
          IconButton(
            key: const ValueKey('action.reset_tracking'),
            tooltip: '重新开始',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt, color: AppColors.textInvert),
          ),
      ],
      child: ColoredBox(
        color: AppColors.surfacePrimary,
        child: SafeArea(child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case TrackState.idle:
        return _IdleView(
          onImport: _pickVideo,
          onRecord: _recordVideo,
        );
      case TrackState.selectingPoint:
        return _PointSelectionView(
          firstFrame: _firstFrame,
          anchorNorm: _anchorNorm,
          frameSize: _frameSize,
          onTap: _onFrameTap,
          onCancel: _reset,
          onConfirm: _anchorNorm == null ? null : _startTracking,
        );
      case TrackState.processing:
        return _ProcessingView(
          progress: _progress,
          message: _progressMessage,
        );
      case TrackState.playback:
        final controller = _playerCtrl;
        if (controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _PlaybackView(
          controller: controller,
          tailLength: _tailLength,
          trajectory: _trajectory,
          trajectoryColor: _trajectoryColor,
          onSaveVideo: _processedVideoPath == null
              ? _showVideoExportUnavailable
              : _saveVideoToGallery,
          onSaveTrajectoryImage: _saveTrajectoryImage,
          onRetapAnchor: _reselectAnchor,
          pointCount: _trajectory.length,
          usesBakedOutput: _processedVideoPath != null,
        );
      case TrackState.error:
        return _ErrorView(
          message: _errorMessage ?? '未知追踪错误。',
          onDismiss: _reset,
        );
    }
  }
}

int _clampInt(int value, int minValue, int maxValue) {
  if (value < minValue) {
    return minValue;
  }
  if (value > maxValue) {
    return maxValue;
  }
  return value;
}

class _IdleView extends StatelessWidget {
  const _IdleView({
    required this.onRecord,
    required this.onImport,
  });

  final VoidCallback onRecord;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 48),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimaryVariant.withValues(
                          alpha: 0.18,
                        ),
                        border: Border.all(
                          color: AppColors.brandPrimaryVariant.withValues(
                            alpha: 0.36,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.track_changes,
                        size: 40,
                        color: AppColors.brandPrimaryVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '选一点\n看清轨迹',
                      textAlign: TextAlign.center,
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textInvert,
                        fontSize: 34,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '导入视频后点选目标，应用会生成轨迹预览。',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyBase.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _ActionCard(
                      key: const ValueKey('action.record_video'),
                      icon: Icons.videocam_rounded,
                      title: '拍摄视频',
                      subtitle: '直接调用相机拍摄。',
                      accentColor: AppColors.brandPrimaryVariant,
                      onTap: onRecord,
                    ),
                    const SizedBox(height: 14),
                    _ActionCard(
                      key: const ValueKey('action.import_video'),
                      icon: Icons.video_library_rounded,
                      title: '从相册导入',
                      subtitle: '选择已有视频并手动标记目标。',
                      accentColor: Colors.cyanAccent,
                      onTap: onImport,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '提示：尽量选择目标点全程清晰可见的视频。',
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.textInvert,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textPrimary.withValues(alpha: 0.42),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointSelectionView extends StatelessWidget {
  const _PointSelectionView({
    required this.firstFrame,
    required this.anchorNorm,
    required this.frameSize,
    required this.onTap,
    required this.onCancel,
    required this.onConfirm,
  });

  final ui.Image? firstFrame;
  final Offset? anchorNorm;
  final Size frameSize;
  final void Function(Offset localPosition, Size renderSize) onTap;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    if (firstFrame == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: <Widget>[
        const _InstructionBanner(
          text: '在首帧点选要追踪的固定点。',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _MetricTile(
                  label: '分辨率',
                  value:
                      '${frameSize.width.round()} × ${frameSize.height.round()}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: '目标点',
                  value: anchorNorm == null
                      ? '点击设置'
                      : '${(anchorNorm!.dx * 100).round()}%, ${(anchorNorm!.dy * 100).round()}%',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.surfaceSecondary,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boxSize = constraints.biggest;
                  final frameAspect = frameSize.width / frameSize.height;
                  final boxAspect = boxSize.width / boxSize.height;

                  double renderWidth;
                  double renderHeight;
                  if (boxAspect > frameAspect) {
                    renderHeight = boxSize.height;
                    renderWidth = renderHeight * frameAspect;
                  } else {
                    renderWidth = boxSize.width;
                    renderHeight = renderWidth / frameAspect;
                  }

                  final renderSize = Size(renderWidth, renderHeight);
                  return Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => onTap(
                        details.localPosition,
                        renderSize,
                      ),
                      child: SizedBox(
                        width: renderWidth,
                        height: renderHeight,
                        child: CustomPaint(
                          painter: _FirstFramePainter(
                            image: firstFrame!,
                            anchorNorm: anchorNorm,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
          child: Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(
                      color: AppColors.textPrimary.withValues(alpha: 0.24),
                    ),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('action.start_tracking'),
                  onPressed: onConfirm,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('开始追踪'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimaryVariant,
                    foregroundColor: AppColors.textInvert,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.56),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textInvert,
            ),
          ),
        ],
      ),
    );
  }
}

class _FirstFramePainter extends CustomPainter {
  const _FirstFramePainter({
    required this.image,
    required this.anchorNorm,
  });

  final ui.Image image;
  final Offset? anchorNorm;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    if (anchorNorm == null) {
      return;
    }

    final point = Offset(
      anchorNorm!.dx * size.width,
      anchorNorm!.dy * size.height,
    );
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(point, 18, paint);
    canvas.drawLine(
      Offset(point.dx - 18, point.dy),
      Offset(point.dx + 18, point.dy),
      paint,
    );
    canvas.drawLine(
      Offset(point.dx, point.dy - 18),
      Offset(point.dx, point.dy + 18),
      paint,
    );
    canvas.drawCircle(
      point,
      4,
      Paint()..color = Colors.cyanAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _FirstFramePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.anchorNorm != anchorNorm;
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({
    required this.progress,
    required this.message,
  });

  final double progress;
  final String message;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandPrimaryVariant.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  size: 34,
                  color: AppColors.brandPrimaryVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '正在追踪',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textInvert,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message.isEmpty ? '正在处理帧...' : message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.74),
                ),
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  key: const ValueKey('tracking.progress'),
                  value: normalizedProgress == 0 ? null : normalizedProgress,
                  minHeight: 10,
                  backgroundColor:
                      AppColors.surfacePrimary.withValues(alpha: 0.9),
                  color: AppColors.brandPrimaryVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                normalizedProgress == 0
                    ? '准备中'
                    : '${(normalizedProgress * 100).round()}%',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaybackView extends StatefulWidget {
  const _PlaybackView({
    required this.controller,
    required this.tailLength,
    required this.trajectory,
    required this.trajectoryColor,
    required this.onSaveVideo,
    required this.onSaveTrajectoryImage,
    required this.onRetapAnchor,
    required this.pointCount,
    required this.usesBakedOutput,
  });

  final VideoPlayerController controller;
  final int tailLength;
  final List<Offset> trajectory;
  final Color trajectoryColor;
  final Future<void> Function()? onSaveVideo;
  final Future<void> Function() onSaveTrajectoryImage;
  final VoidCallback onRetapAnchor;
  final int pointCount;
  final bool usesBakedOutput;

  @override
  State<_PlaybackView> createState() => _PlaybackViewState();
}

class _PlaybackViewState extends State<_PlaybackView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerUpdated);
  }

  @override
  void didUpdateWidget(covariant _PlaybackView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_onControllerUpdated);
    widget.controller.addListener(_onControllerUpdated);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdated);
    super.dispose();
  }

  void _onControllerUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  int _currentFrameIndex(VideoPlayerValue value) {
    final totalPoints = widget.trajectory.length;
    if (totalPoints <= 1) {
      return 0;
    }

    final durationMs = value.duration.inMilliseconds;
    if (durationMs <= 0) {
      return 0;
    }

    final positionMs = value.position.inMilliseconds.clamp(0, durationMs);
    return ((positionMs / durationMs) * (totalPoints - 1))
        .round()
        .clamp(0, totalPoints - 1);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final value = controller.value;
    final isPlaying = value.isPlaying;
    final currentFrameIndex = _currentFrameIndex(value);

    return Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.surfaceSecondary),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio == 0 ? 1 : value.aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        VideoPlayer(controller),
                        if (!widget.usesBakedOutput &&
                            widget.trajectory.isNotEmpty)
                          IgnorePointer(
                            child: CustomPaint(
                              painter: _TrajectoryPainter(
                                trajectory: widget.trajectory,
                                trajectoryColor: widget.trajectoryColor,
                                tailLength: widget.tailLength,
                                currentFrameIndex: currentFrameIndex,
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.56),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  widget.usesBakedOutput ? '已生成轨迹视频' : '实时轨迹预览',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textInvert,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _MetricTile(
                  label: '轨迹点',
                  value: '${widget.pointCount}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: '尾迹长度',
                  value: '${widget.tailLength} 帧',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: '从头播放',
                  onPressed: () => controller.seekTo(Duration.zero),
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    color: AppColors.textInvert,
                  ),
                ),
                IconButton(
                  tooltip: isPlaying ? '暂停' : '播放',
                  onPressed: () {
                    if (isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                  },
                  iconSize: 42,
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.brandPrimaryVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: AppColors.brandPrimaryVariant,
                      bufferedColor:
                          AppColors.textPrimary.withValues(alpha: 0.24),
                      backgroundColor:
                          AppColors.surfacePrimary.withValues(alpha: 0.86),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _PlaybackActionButton(
                key: const ValueKey('action.reselect_anchor'),
                icon: Icons.ads_click_rounded,
                tooltip: '重选目标',
                onPressed: widget.onRetapAnchor,
              ),
              const SizedBox(width: 14),
              _PlaybackActionButton(
                key: const ValueKey('action.save_trajectory_image'),
                icon: Icons.image_outlined,
                tooltip: '保存图片',
                onPressed: widget.onSaveTrajectoryImage,
              ),
              const SizedBox(width: 14),
              _PlaybackActionButton(
                key: const ValueKey('action.save_to_gallery'),
                icon: widget.usesBakedOutput
                    ? Icons.download_rounded
                    : Icons.videocam_off_rounded,
                tooltip: widget.usesBakedOutput ? '保存视频' : '无法导出',
                onPressed: widget.onSaveVideo,
                highlighted: widget.usesBakedOutput,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlaybackActionButton extends StatelessWidget {
  const _PlaybackActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String tooltip;
  final FutureOr<void> Function()? onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: highlighted
            ? AppColors.brandPrimaryVariant
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed == null ? null : () => onPressed!.call(),
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              color: AppColors.textInvert,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  const _TrajectoryPainter({
    required this.trajectory,
    required this.trajectoryColor,
    required this.tailLength,
    required this.currentFrameIndex,
  });

  final List<Offset> trajectory;
  final Color trajectoryColor;
  final int tailLength;
  final int currentFrameIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (trajectory.isEmpty || size.isEmpty) {
      return;
    }

    final endIndex = currentFrameIndex.clamp(0, trajectory.length - 1);
    final startIndex = math.max(0, endIndex - tailLength + 1);
    _paintTrajectory(
      canvas,
      size: size,
      trajectory: trajectory,
      trajectoryColor: trajectoryColor,
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter oldDelegate) {
    return oldDelegate.trajectory != trajectory ||
        oldDelegate.trajectoryColor != trajectoryColor ||
        oldDelegate.tailLength != tailLength ||
        oldDelegate.currentFrameIndex != currentFrameIndex;
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 18),
              Text(
                '追踪已停止',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textInvert,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('重新开始'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brandPrimaryVariant,
                  foregroundColor: AppColors.textInvert,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      color: AppColors.brandPrimaryVariant.withValues(alpha: 0.14),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.touch_app_rounded,
            size: 20,
            color: AppColors.brandPrimaryVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.caption.copyWith(
                color: AppColors.brandPrimaryVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingSheetResult {
  const _TrackingSheetResult({
    required this.color,
    required this.tailLength,
    required this.reprocess,
  });

  final Color color;
  final int tailLength;
  final bool reprocess;
}

class _TrackingSettingsSheet extends StatefulWidget {
  const _TrackingSettingsSheet({
    required this.color,
    required this.tailLength,
    required this.canReprocess,
  });

  final Color color;
  final int tailLength;
  final bool canReprocess;

  @override
  State<_TrackingSettingsSheet> createState() => _TrackingSettingsSheetState();
}

class _TrackingSettingsSheetState extends State<_TrackingSettingsSheet> {
  static const List<Color> _palette = <Color>[
    Colors.cyanAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.yellowAccent,
    Colors.white,
  ];

  late Color _color;
  late int _tailLength;

  @override
  void initState() {
    super.initState();
    _color = widget.color;
    _tailLength = widget.tailLength;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 18, 24, math.max(28, bottomInset + 24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.36),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '追踪设置',
            style: AppTypography.h2.copyWith(
              color: AppColors.textInvert,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '调整轨迹显示效果。当前版本使用 MIL 追踪器。',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '轨迹颜色',
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textInvert,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _palette.map((color) {
              final selected = color == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = color),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected ? AppColors.textInvert : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 26),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '尾迹长度',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textInvert,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_tailLength 帧',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.66),
                  ),
                ),
                Slider(
                  value: _tailLength.toDouble(),
                  min: 20,
                  max: 220,
                  divisions: 20,
                  activeColor: AppColors.brandPrimaryVariant,
                  inactiveColor:
                      AppColors.surfacePrimary.withValues(alpha: 0.8),
                  label: '$_tailLength',
                  onChanged: (value) {
                    setState(() => _tailLength = value.round());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.memory_rounded,
                  color: AppColors.brandPrimaryVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '追踪引擎：MIL（当前 OpenCV 构建支持）',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.76),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final stackActions = constraints.maxWidth < 360;
              if (stackActions) {
                return Column(
                  children: <Widget>[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _TrackingSheetResult(
                              color: _color,
                              tailLength: _tailLength,
                              reprocess: false,
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: BorderSide(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.24),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('保存'),
                      ),
                    ),
                    if (widget.canReprocess) ...<Widget>[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                              _TrackingSheetResult(
                                color: _color,
                                tailLength: _tailLength,
                                reprocess: true,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimaryVariant,
                            foregroundColor: AppColors.textInvert,
                            minimumSize: const Size.fromHeight(50),
                          ),
                          child: const Text('保存并重跑'),
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _TrackingSheetResult(
                            color: _color,
                            tailLength: _tailLength,
                            reprocess: false,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.textPrimary.withValues(alpha: 0.24),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('保存'),
                    ),
                  ),
                  if (widget.canReprocess) ...<Widget>[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            _TrackingSheetResult(
                              color: _color,
                              tailLength: _tailLength,
                              reprocess: true,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPrimaryVariant,
                          foregroundColor: AppColors.textInvert,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('保存并重跑'),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrackingWriterOutput {
  const _TrackingWriterOutput({
    required this.file,
    required this.writer,
  });

  final File file;
  final cv.VideoWriter writer;
}

void _paintTrajectory(
  Canvas canvas, {
  required Size size,
  required List<Offset> trajectory,
  required Color trajectoryColor,
  required int startIndex,
  required int endIndex,
}) {
  if (trajectory.isEmpty || size.isEmpty) {
    return;
  }

  final clampedStart = startIndex.clamp(0, trajectory.length - 1);
  final clampedEnd = endIndex.clamp(clampedStart, trajectory.length - 1);
  final segmentCount = math.max(1, clampedEnd - clampedStart);

  Offset scale(Offset point) =>
      Offset(point.dx * size.width, point.dy * size.height);

  for (var index = clampedStart; index < clampedEnd; index += 1) {
    final progress = (index - clampedStart + 1) / segmentCount;
    final paint = Paint()
      ..color = trajectoryColor.withValues(alpha: 0.3 + (0.7 * progress))
      ..strokeWidth = 2 + (progress * 3)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawLine(
      scale(trajectory[index]),
      scale(trajectory[index + 1]),
      paint,
    );
  }

  final head = scale(trajectory[clampedEnd]);
  canvas.drawCircle(
    head,
    12,
    Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..isAntiAlias = true,
  );
  canvas.drawCircle(
    head,
    6,
    Paint()
      ..color = trajectoryColor
      ..isAntiAlias = true,
  );
}
