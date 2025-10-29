import 'dart:io';
import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';
import 'package:aiwa_app/adapters/evidence_resolver.dart';

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

  @override
  void initState() {
    super.initState();
    _loadEvidenceWindow();
  }

  /// 加载证据时间窗（若快照路径不存在）
  Future<void> _loadEvidenceWindow() async {
    // 如果已有证据路径，不需要加载时间窗
    if (widget.result.evidencePath != null && widget.result.evidencePath!.isNotEmpty) {
      return;
    }

    setState(() => _isLoadingWindow = true);

    try {
      // 读取原始 result.json
      final raw = await readResultJson(widget.sessionRoot);
      
      // 解析时间窗
      final window = resolveEvidenceWindow(raw);
      
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
      onTap: () => Navigator.pop(context), // 点击空白处关闭
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onTap: () {}, // 阻止点击内容时关闭
        child: DraggableScrollableSheet(
          initialChildSize: 0.67, // 初始占 2/3 高度
          minChildSize: 0.5,      // 最小 1/2 高度
          maxChildSize: 0.9,      // 最大 9/10 高度
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: const BorderRadius.vertical(
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
    // 证据降级策略：
    // 1. 优先显示快照图片（evidencePath）
    // 2. 次选显示时间窗提示（window）
    // 3. 最后显示播放图标占位
    
    final evidencePath = widget.result.evidencePath;
    final hasEvidence = evidencePath != null && evidencePath.isNotEmpty;

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
      child: hasEvidence
          ? _buildEvidenceImage(evidencePath)
          : (_evidenceWindow != null
              ? _buildWindowHint(_evidenceWindow!)
              : (_isLoadingWindow
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPlaceholder())),
    );
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
            'No evidence snapshot',
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
          Icon(
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

  /// 构建证据图片
  Widget _buildEvidenceImage(String relativePath) {
    final fullPath = '${widget.sessionRoot}/$relativePath';
    final file = File(fullPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: file.existsSync()
          ? Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: AppColors.textInvert.withOpacity(0.4),
                  ),
                );
              },
            )
          : Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.textInvert.withOpacity(0.4),
              ),
            ),
    );
  }

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
  Widget _buildScoreCard(String label, int score) {
    // 根据分数选择颜色（参见 ui_contracts.md）
    // <60 灰，60~79 灰，≥80 绿
    final Color scoreColor;
    if (score < 60) {
      scoreColor = AppColors.surfaceSecondary;
    } else if (score < 80) {
      scoreColor = AppColors.surfaceSecondary;
    } else {
      scoreColor = AppColors.brandPrimaryVariant;
    }

    return Container(
      width: 100,
      height: 80,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textInvert,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            score.toString(),
            style: AppTypography.bodyBold.copyWith(
              color: scoreColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 评估详情区域（底部，包含总分、次数、质量提示、元信息）
  Widget _buildEvaluationPanel(BuildContext context) {
    // 质量提示判断
    final showQualityWarning = 
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 总分与次数
          _buildSummarySection(),
          
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
    // 总分颜色
    final Color totalColor;
    if (widget.result.total < 60) {
      totalColor = AppColors.surfaceSecondary;
    } else if (widget.result.total < 80) {
      totalColor = AppColors.surfaceSecondary;
    } else {
      totalColor = AppColors.brandPrimaryVariant;
    }

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
          '${widget.result.total}/100',
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
            Icon(
              Icons.repeat,
              color: AppColors.textInvert,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Repetitions: ${widget.result.reps}',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建质量警告提示
  Widget _buildQualityWarning() {
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
          Icon(Icons.warning, color: AppColors.surfaceSecondary, size: 20),
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

