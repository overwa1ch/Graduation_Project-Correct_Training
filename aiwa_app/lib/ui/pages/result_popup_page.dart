import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';
import 'package:aiwa_core/aiwa_core.dart' as aiwacore;

/// ResultPopupPage
/// 
/// 结果展示弹窗页面：显示训练结果
/// 基于 Figma 设计：https://www.figma.com/design/q3hgTOdVGt42WkOfDixtsp/Graduation-Project?node-id=40-6
/// 
/// 包含三个板块：
/// 1. 视频/证据占位（顶部）
/// 2. 打分卡片（中部）- 显示 posture/stability/rhythm 分数
/// 3. 评估详情（底部，可滚动）- 显示次数、元信息、质量提示
/// 
/// ⚠️ 本版本实现数据展示：接收 AnalysisResultLite 并映射到 UI

/// 显示结果弹窗的方法
/// 使用方式：showResultPopup(context, result, sessionRoot);
void showResultPopup(
  BuildContext context,
  AnalysisResultLite result,
  String sessionRoot,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ResultPopupPage(
      result: result,
      sessionRoot: sessionRoot,
    ),
  );
}

class ResultPopupPage extends StatefulWidget {
  final AnalysisResultLite result;
  final String sessionRoot;

  const ResultPopupPage({
    super.key,
    required this.result,
    required this.sessionRoot,
  });

  @override
  State<ResultPopupPage> createState() => _ResultPopupPageState();
}

class _ResultPopupPageState extends State<ResultPopupPage> {
  // 证据时间窗（降级策略）
  ({int startMs, int endMs})? _evidenceWindow;
  bool _isLoadingWindow = false;

  // 骨架视频（部分结果时显示）
  String? _overlayVideoPath;
  bool _hasOverlayVideo = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _checkOverlayVideo();
    _loadEvidenceWindow();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  /// 检查骨架视频是否存在
  Future<void> _checkOverlayVideo() async {
    try {
      final overlayPath = p.join(widget.sessionRoot, 'keypoints_overlay.mp4');
      final overlayFile = File(overlayPath);
      
      if (await overlayFile.exists()) {
        final size = await overlayFile.length();
        debugPrint('[ResultPopup] Found overlay video: $overlayPath ($size bytes)');
        
        if (size > 0) {
          setState(() {
            _overlayVideoPath = overlayPath;
            _hasOverlayVideo = true;
          });
        } else {
          debugPrint('[ResultPopup] Overlay video file is empty');
        }
      } else {
        debugPrint('[ResultPopup] No overlay video found at: $overlayPath');
      }
    } catch (e) {
      debugPrint('[ResultPopup] Error checking overlay video: $e');
    }
  }

  /// 加载证据时间窗（用于视频段落提示）
  Future<void> _loadEvidenceWindow() async {
    setState(() => _isLoadingWindow = true);

    try {
      // 读取并验证 result.json（使用 aiwa_core 标准化方法）
      final result = await aiwacore.readResultJson(widget.sessionRoot);
      
      // 解析时间窗（使用 aiwa_core 的证据解析）
      final window = aiwacore.resolveEvidenceWindow(result);
      
      if (mounted) {
        setState(() {
          _evidenceWindow = window;
          _isLoadingWindow = false;
        });
      }
    } catch (e) {
      debugPrint('[ResultPopup] Failed to load evidence window: $e');
      if (mounted) {
        setState(() => _isLoadingWindow = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('dialog.result.backdrop'),
      onTap: () => Navigator.pop(context), // 点击空白处关闭
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        key: const ValueKey('dialog.result.content'),
        onTap: () {}, // 阻止点击内容时关闭
        child: DraggableScrollableSheet(
          initialChildSize: 0.67, // 初始占 2/3 高度
          minChildSize: 0.5,      // 最小 1/2 高度
          maxChildSize: 0.9,      // 最大 9/10 高度
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 拖拽指示器
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutralLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 可滚动内容
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            
                            // 1. 视频占位区域
                            _buildVideoPlaceholder(context),
                            
                            const SizedBox(height: 37),
                            
                            // 2. 打分卡片区域
                            _buildScoreCards(context),
                            
                            const SizedBox(height: 37),
                            
                            // 3. 评估详情区域
                            _buildEvaluationPanel(context),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 视频/证据占位区域（顶部）
  Widget _buildVideoPlaceholder(BuildContext context) {
    // 显示优先级：
    // 1. 骨架视频（部分结果时）
    // 2. 证据时间窗提示
    // 3. 加载中
    // 4. 占位图标

    Widget content;
    
    if (_hasOverlayVideo && _overlayVideoPath != null) {
      // 显示骨架视频
      content = _buildOverlayVideoPlayer();
    } else if (_evidenceWindow != null) {
      content = _buildWindowHint(_evidenceWindow!);
    } else if (_isLoadingWindow) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      content = _buildPlaceholder();
    }

    return Container(
      width: 343,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceSecondary.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: content,
    );
  }

  /// 构建骨架视频播放器
  Widget _buildOverlayVideoPlayer() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => _openFullscreenVideo(context),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FutureBuilder<VideoPlayerController>(
              future: _initializeVideoPlayer(_overlayVideoPath!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData && snapshot.data!.value.isInitialized) {
                    final controller = snapshot.data!;
                    
                    // 自动循环播放
                    controller.setLooping(true);
                    if (!controller.value.isPlaying) {
                      controller.play();
                    }
                    
                    return SizedBox(
                      width: 343,
                      height: 200,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      ),
                    );
                  } else {
                    return _buildPlaceholder();
                  }
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ),
        // 标签：显示这是骨架视频
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.accessibility_new,
                  size: 14,
                  color: AppColors.brandPrimaryVariant,
                ),
                SizedBox(width: 4),
                Text(
                  'Keypoints',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // 放大图标提示
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fullscreen,
              color: AppColors.brandPrimaryVariant,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  /// 打开全屏视频
  void _openFullscreenVideo(BuildContext context) {
    if (_overlayVideoPath == null) return;
    
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => _FullscreenVideoPage(videoPath: _overlayVideoPath!),
      ),
    );
  }

  /// 初始化视频播放器
  Future<VideoPlayerController> _initializeVideoPlayer(String path) async {
    final controller = VideoPlayerController.file(File(path));
    await controller.initialize();
    
    // 保存控制器引用以便清理
    _videoController = controller;
    
    return controller;
  }

  /// 构建播放图标占位
  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            size: 64,
            color: AppColors.textInvert.withOpacity(0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'No video preview',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时间窗提示（降级策略）
  Widget _buildWindowHint(({int startMs, int endMs}) window) {
    // 转换为秒
    final startSec = (window.startMs / 1000).toStringAsFixed(1);
    final endSec = (window.endMs / 1000).toStringAsFixed(1);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.videocam,
            size: 48,
            color: AppColors.brandPrimaryVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Evidence Segment',
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textInvert,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${startSec}s - ${endSec}s',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.brandPrimaryVariant,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review this segment in the video',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 旧版静态快照展示已移除，后续将接入视频播放器

  /// 打分卡片区域（中部）
  Widget _buildScoreCards(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScoreCard('Posture', widget.result.posture),
        const SizedBox(width: 20),
        _buildScoreCard('Stability', widget.result.stability),
        const SizedBox(width: 20),
        _buildScoreCard('Rhythm', widget.result.rhythm),
      ],
    );
  }

  /// 单个打分卡片
  Widget _buildScoreCard(String label, int? score) {
    final isNA = score == null;
    
    // 根据分数选择颜色（参见 ui_contracts.md）
    // <60 灰，60~79 灰，≥80 绿
    final Color scoreColor;
    if (isNA) {
      scoreColor = AppColors.neutralLight.withOpacity(0.5);
    } else if (score < 60) {
      scoreColor = AppColors.neutralLight;
    } else if (score < 80) {
      scoreColor = AppColors.neutralLight;
    } else {
      scoreColor = AppColors.brandPrimaryVariant;
    }

    return Container(
      key: ValueKey('score_card_${label.toLowerCase()}'),
      width: 88,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scoreColor.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceSecondary.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                key: ValueKey('score_label_${label.toLowerCase()}'),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyBold.copyWith(
                  color: AppColors.textInvert,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                isNA ? 'N/A' : score.toString(),
                key: ValueKey('score_value_${label.toLowerCase()}'),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyBold.copyWith(
                  color: scoreColor,
                  fontSize: isNA ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 评估详情区域（底部，包含总分、次数、质量提示、元信息）
  Widget _buildEvaluationPanel(BuildContext context) {
    // 质量提示判断（包括部分结果）
    final showQualityWarning = 
        widget.result.isPartial ||
        (widget.result.lowConfidence == true) || 
        (widget.result.coverage != null && widget.result.coverage! < 0.7);

    return Container(
      width: 343,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.surfaceSecondary.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总分与次数
          _buildSummarySection(),
          
          if (_shouldShowAttemptFeedback())
            const SizedBox(height: 24),

          if (_shouldShowAttemptFeedback())
            _buildAttemptFeedbackSection(context),

          if (_shouldShowAttemptFeedback())
            const SizedBox(height: 24),
          
          const SizedBox(height: 24),
          
          // 质量提示（黄条）
          if (showQualityWarning)
            _buildQualityWarning(),
          
          if (showQualityWarning)
            const SizedBox(height: 24),
          
          // 元信息（可折叠）
          _buildMetaSection(),
        ],
      ),
    );
  }

  /// 构建总分与次数区域
  Widget _buildSummarySection() {
    final isNA = widget.result.total == null;
    // 总分颜色固定为纯白，提升可读性
    final Color totalColor = isNA 
        ? AppColors.textInvert.withOpacity(0.5) 
        : AppColors.textInvert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 总分标题
        Text(
          'Overall Score',
          style: AppTypography.heading.copyWith(
            color: AppColors.textInvert,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        
        // 总分数值
        Text(
          isNA ? 'N/A' : '${widget.result.total}/100',
          key: const ValueKey('overall_score'),
          style: AppTypography.heading.copyWith(
            color: totalColor,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 次数
        Row(
          children: [
            const Icon(
              Icons.repeat,
              color: AppColors.textInvert,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Repetitions: ${widget.result.reps}',
              key: const ValueKey('reps_count'),
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),

        if (widget.result.attempts > widget.result.reps)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: AppColors.textInvert,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Detected Attempts: ${widget.result.attempts}',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textInvert.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool _shouldShowAttemptFeedback() {
    if (widget.result.attemptFeedback != null) {
      return true;
    }
    return widget.result.attempts > widget.result.reps;
  }

  Widget _buildAttemptFeedbackSection(BuildContext context) {
    final feedback = widget.result.attemptFeedback;
    final attemptsTotal = feedback?.total ?? widget.result.attempts;
    final attemptsQualified = feedback?.qualified ?? widget.result.reps;
    final attemptsUnqualified = feedback?.unqualified ??
        math.max(0, attemptsTotal - attemptsQualified);
    final avgAngle = feedback?.avgAngle;
    final targetAngle = feedback?.targetAngle;
    final detectionThreshold = feedback?.detectionThreshold;
    final suggestions = feedback?.suggestions ?? const <String>[];
    debugPrint('[ResultPopup] 🎨 Building feedback badge');
    debugPrint('[ResultPopup] 🎨 feedback?.mode: ${feedback?.mode}');
    debugPrint('[ResultPopup] 🎨 widget.result.strictness: ${widget.result.strictness}');
    final modeLabel = feedback?.mode ?? (widget.result.strictness ?? 'relaxed');
    debugPrint('[ResultPopup] 🎨 Final modeLabel: $modeLabel');

    final bool isRelaxed = modeLabel.toLowerCase() != 'strict';
    final Color accentColor = AppColors.brandPrimaryVariant;
    final Color badgeColor = isRelaxed
        ? AppColors.brandPrimaryVariant.withOpacity(0.22)
        : AppColors.surfaceSecondary.withOpacity(0.45);
    final Color badgeBorder = isRelaxed
        ? AppColors.brandPrimaryVariant.withOpacity(0.55)
        : AppColors.surfaceSecondary.withOpacity(0.7);
    final Color badgeTextColor = isRelaxed
        ? AppColors.brandPrimaryVariant
        : AppColors.textInvert.withOpacity(0.85);
    final String badgeText = isRelaxed
        ? 'Relaxed · Beginner Friendly'
        : 'Strict · Advanced Challenge';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withOpacity(0.6),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: badgeBorder,
                width: 1,
              ),
            ),
            child: Text(
              badgeText,
              style: AppTypography.caption.copyWith(
                color: badgeTextColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.insights, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Attempt Summary',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Detected $attemptsTotal attempts • Qualified $attemptsQualified • Needs work $attemptsUnqualified',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
          if (avgAngle != null && targetAngle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Average depth: ${avgAngle.toStringAsFixed(1)}° (goal < ${targetAngle.toStringAsFixed(1)}°)',
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textInvert.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ),
          if (detectionThreshold != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Detection window: up to ${detectionThreshold.toStringAsFixed(0)}°',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textInvert.withOpacity(0.55),
                ),
              ),
            ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Coaching Tips',
              style: AppTypography.bodyBold.copyWith(
                color: accentColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...suggestions.map((tip) => _buildSuggestionItem(tip)),
          ] else ...[
            const SizedBox(height: 12),
            _buildSuggestionItem('Replay your successful reps and replicate their depth and pacing.'),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert.withOpacity(0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建质量警告提示
  Widget _buildQualityWarning() {
    // 检查是否为部分结果
    if (widget.result.isPartial) {
      return _buildPartialResultWarning();
    }
    
    // 普通质量警告
    String message;
    if (widget.result.lowConfidence == true) {
      message = '⚠️ Low confidence detected. Results may be less accurate.';
    } else if (widget.result.coverage != null && widget.result.coverage! < 0.7) {
      message = '⚠️ Low coverage (${(widget.result.coverage! * 100).toInt()}%). Some frames may be missing.';
    } else {
      message = '⚠️ Quality issue detected.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceSecondary, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.surfaceSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.surfaceSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建部分结果警告（降级模式）
  Widget _buildPartialResultWarning() {
    final partialInfo = widget.result.partialFailure;
    
    String title = 'Partial Analysis Results';
    String message = 'Keypoints detected successfully, but angle calculation failed.';
    String suggestion = '💡 Suggestions: Ensure clear view of knees and hips, improve lighting, or adjust camera angle.';
    
    if (partialInfo != null) {
      switch (partialInfo.code) {
        case 'ANGLE_COMPUTE_FAILED':
          message = 'Keypoints detected successfully, but angle calculation failed.\nReason: ${partialInfo.message}';
          suggestion = '💡 Suggestions: Ensure clear view of knees and hips, improve lighting, or adjust camera angle.';
          break;
        case 'METRICS_COMPUTE_FAILED':
          message = 'Angles computed, but scoring metrics failed.\nReason: ${partialInfo.message}';
          suggestion = '💡 Try recording again with better visibility.';
          break;
        default:
          message = 'Analysis completed with limitations: ${partialInfo.message}';
          suggestion = '💡 Try recording again with better conditions.';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.surfaceSecondary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.surfaceSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            suggestion,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建元信息区域
  Widget _buildMetaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Details',
          style: AppTypography.heading.copyWith(
            color: AppColors.textInvert,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        
        // 模板名称
        if (widget.result.templateName != null)
          _buildMetaRow('Template', widget.result.templateName!),
        
        // 严格度
        if (widget.result.strictness != null)
          _buildMetaRow('Strictness', widget.result.strictness!),
        
        // 推理引擎
        if (widget.result.engine != null)
          _buildMetaRow('Engine', widget.result.engine!),
        
        // 帧率
        if (widget.result.fps != null)
          _buildMetaRow('FPS', '${widget.result.fps}'),
        
        // 覆盖率
        if (widget.result.coverage != null)
          _buildMetaRow('Coverage', '${(widget.result.coverage! * 100).toInt()}%'),
      ],
    );
  }

  /// 构建单行元信息
  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 全屏视频播放页面
// ============================================================================

/// 全屏视频播放页面（私有组件）
class _FullscreenVideoPage extends StatefulWidget {
  final String videoPath;

  const _FullscreenVideoPage({required this.videoPath});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.file(File(widget.videoPath));
    await _controller.initialize();
    _controller.setLooping(true);
    _controller.play();
    
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Skeleton Video',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              backgroundColor: AppColors.brandPrimaryVariant,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}

