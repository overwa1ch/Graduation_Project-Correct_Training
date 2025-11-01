import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/result_popup_page.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';
import 'package:aiwa_app/services/config_sync.dart';
import 'package:aiwa_app/services/session_manager.dart';
import 'package:aiwa_app/services/analysis_history.dart';
import 'package:aiwa_app/services/analysis_session_manager.dart';

/// CameraPage
/// 
/// 相机页面：实时姿态检测与训练
/// 基于 Figma 设计：https://www.figma.com/design/q3hgTOdVGt42WkOfDixtsp/Graduation-Project?node-id=14-8
/// 
/// ⚠️ 本版本实现状态机接线：连接事件流与结果解析
/// 状态机：idle → preparing → running → parsing → success/error

/// 状态枚举
enum CameraState { idle, preparing, running, parsing, success, error }

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  // ✅ 使用全局 AnalysisSessionManager 替代本地状态管理
  final _sessionManager = AnalysisSessionManager();
  StreamSubscription<AnalysisState>? _stateSubscription;
  
  // UI 状态（从 AnalysisState 映射）
  CameraState _state = CameraState.idle;
  double _progress = 0.0;
  int? _etaSec;
  int? _p95Ms;
  String? _currentPhase;
  bool _showQualityWarning = false;
  String? _qualityMessage;
  String? _errorCode;
  String? _errorMessage;
  
  // 会话信息（仅用于结果处理）
  String? _sessionRoot;
  // 注意：DiagnosticsLogger、sessionId、firstEvidence 等诊断功能暂时移除
  // 这些功能可以在未来由 AnalysisSessionManager 统一管理

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // ✅ 监听全局状态变化
    _stateSubscription = _sessionManager.stateStream.listen(_handleSessionState);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stateSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[Camera] App lifecycle state changed: $state');
    
    // 只在应用真正关闭时取消分析
    if (state == AppLifecycleState.detached) {
      debugPrint('[Camera] App is closing, cancelling analysis');
      _sessionManager.cancelCurrentAnalysis();
    }
  }
  
  /// ✅ 处理全局状态变化
  void _handleSessionState(AnalysisState state) {
    if (!mounted) return;
    
    debugPrint('[Camera] _handleSessionState: ${state.runtimeType}');
    
    setState(() {
      switch (state) {
        case AnalysisStateIdle():
          _state = CameraState.idle;
          _progress = 0.0;
          _currentPhase = null;
          _etaSec = null;
          _p95Ms = null;
          _showQualityWarning = false;
          _qualityMessage = null;
          
        case AnalysisStatePreparing(:final currentPhase):
          _state = CameraState.preparing;
          _currentPhase = currentPhase;
          
        case AnalysisStateRunning(:final progress, :final phase, :final etaSec, :final p95Ms, :final showQualityWarning, :final qualityMessage):
          _state = CameraState.running;
          _progress = progress;
          _currentPhase = phase;
          _etaSec = etaSec;
          _p95Ms = p95Ms;
          if (showQualityWarning) {
            _showQualityWarning = true;
            _qualityMessage = qualityMessage;
          }
          
        case AnalysisStateCancelling(:final message):
          _currentPhase = message ?? 'Cancelling...';
          
        case AnalysisStateParsing(:final message):
          _state = CameraState.parsing;
          _currentPhase = message ?? 'Parsing results...';
          _progress = 1.0;
          
        case AnalysisStateSuccess(:final sessionRoot):
          _state = CameraState.success;
          _sessionRoot = sessionRoot;
          // 延迟处理结果，避免阻塞状态更新
          Future.delayed(const Duration(milliseconds: 200), _onDone);
          
        case AnalysisStateError(:final errorCode, :final errorMessage):
          _setError(errorCode, errorMessage);
      }
    });
  }

  /// 启动分析流程
  /// 
  /// 参数:
  /// - [videoPath]: 视频文件路径（必需）
  Future<void> _startAnalysis({required String videoPath}) async {
    debugPrint('[Camera] ========================================');
    debugPrint('[Camera] _startAnalysis called with videoPath: $videoPath');
    
    // ✅ 使用 Manager 检查是否有正在运行的会话
    if (_sessionManager.hasRunningSession) {
      debugPrint('[Camera] ⚠️ Already has running session, ignoring request');
      debugPrint('[Camera] ========================================');
      return;
    }
    
    if (!mounted) return;

    try {
      // 1. 创建会话目录
      _sessionRoot = await SessionManager.createSessionRoot();
      debugPrint('[Camera] Session root: $_sessionRoot');

      // 2. 读取配置并写入会话快照
      final cfg = await readAppRuntimeConfig();
      await writeRuntimeSnapshot(_sessionRoot!, cfg);

      // 3. ✅ 使用 AnalysisSessionManager 启动分析
      debugPrint('[Camera] Starting analysis via SessionManager');
      final success = await _sessionManager.startAnalysis(
        videoPath: videoPath,
        sessionRoot: _sessionRoot!,
      );
      
      if (!success) {
        debugPrint('[Camera] ⚠️ SessionManager rejected analysis (already running)');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Analysis already in progress'),
              backgroundColor: AppColors.surfaceSecondary,
            ),
          );
        }
      } else {
        debugPrint('[Camera] ✅ Analysis started successfully');
      }
    } catch (e, st) {
      debugPrint('[Camera] Failed to start analysis: $e\n$st');
      _setError('500_INTERNAL', 'Failed to start analysis: $e');
    }
    
    debugPrint('[Camera] ========================================');
  }

  // ✅ 旧的事件处理逻辑已删除
  // 现在由 AnalysisSessionManager 处理事件
  // 通过 _handleSessionState 接收状态更新

  /// 处理 DONE 事件
  Future<void> _onDone() async {
    debugPrint('[Camera] ========== _onDone 开始 ==========');
    debugPrint('[Camera] sessionRoot: $_sessionRoot');
    
    if (_sessionRoot == null) {
      debugPrint('[Camera] ✗ sessionRoot 为 null');
      _setError('500_INTERNAL', 'Session root is null');
      return;
    }

    try {
      // ===== 步骤 1: 读取 result.json =====
      debugPrint('[Camera] [步骤1] 开始读取 result.json');
      debugPrint('[Camera] [步骤1] 文件路径: $_sessionRoot/result.json');
      final raw = await readResultJson(_sessionRoot!);
      debugPrint('[Camera] [步骤1] ✓ 读取成功');
      debugPrint('[Camera] [步骤1] JSON keys: ${raw.keys.join(", ")}');
      
      // 打印完整 JSON（用于诊断）
      debugPrint('[Camera] ========== result.json 完整内容 ==========');
      try {
        debugPrint(const JsonEncoder.withIndent('  ').convert(raw));
      } catch (e) {
        debugPrint('[Camera] JSON 格式化失败: $e');
        debugPrint('[Camera] 原始内容: $raw');
      }
      debugPrint('[Camera] ========== result.json 结束 ==========');
      
      // ===== 步骤 2: 验证 Schema =====
      debugPrint('[Camera] [步骤2] 开始验证 Schema');
      assertResultContract(raw);
      debugPrint('[Camera] [步骤2] ✓ Schema 验证通过');
      
      // ===== 步骤 3: 映射到 AnalysisResultLite =====
      debugPrint('[Camera] [步骤3] 开始映射到 AnalysisResultLite');
      final lite = mapToLite(raw);
      debugPrint('[Camera] [步骤3] ✓ 映射成功');
      debugPrint('[Camera] [步骤3] 结果: total=${lite.total}, reps=${lite.reps}, posture=${lite.posture}, stability=${lite.stability}, rhythm=${lite.rhythm}');

      if (mounted) {
        setState(() => _state = CameraState.success);
        
        // ===== 步骤 4: 保存历史记录 =====
        debugPrint('[Camera] [步骤4] 开始保存历史记录');
        try {
          await AnalysisHistoryService().saveRecord(
            result: lite,
            sessionRoot: _sessionRoot!,
          );
          debugPrint('[Camera] [步骤4] ✓ 历史记录保存成功');
        } catch (historyError, historyStack) {
          debugPrint('[Camera] [步骤4] ✗ 历史记录保存失败');
          debugPrint('[Camera] [步骤4] 错误类型: ${historyError.runtimeType}');
          debugPrint('[Camera] [步骤4] 错误信息: $historyError');
          debugPrint('[Camera] [步骤4] 堆栈:\n$historyStack');
          // 不抛出异常，继续显示结果
        }
        
        // ===== 步骤 5: 显示结果弹窗 =====
        debugPrint('[Camera] [步骤5] 开始显示结果弹窗');
        try {
          showResultPopup(context, lite, _sessionRoot!);
          debugPrint('[Camera] [步骤5] ✓ 弹窗已调用');
        } catch (popupError, popupStack) {
          debugPrint('[Camera] [步骤5] ✗ 弹窗显示失败');
          debugPrint('[Camera] [步骤5] 错误: $popupError');
          debugPrint('[Camera] [步骤5] 堆栈:\n$popupStack');
          rethrow; // 重新抛出，因为这是关键步骤
        }
      } else {
        debugPrint('[Camera] ✗ Widget 未 mounted，跳过后续步骤');
      }
      
      debugPrint('[Camera] ========== _onDone 成功完成 ==========');
      
    } on SchemaMismatch catch (e, stackTrace) {
      debugPrint('[Camera] ✗ Schema mismatch: $e');
      debugPrint('[Camera] 详细堆栈:\n$stackTrace');
      _setError('422_SCHEMA_MISMATCH', 'Schema mismatch: ${e.message}');
    } on ResultReadException catch (e, stackTrace) {
      debugPrint('[Camera] ✗ Result read error: $e');
      debugPrint('[Camera] 详细堆栈:\n$stackTrace');
      _setError('500_RESULT_READ', 'Failed to read result: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('[Camera] ✗ Unexpected error');
      debugPrint('[Camera] 错误类型: ${e.runtimeType}');
      debugPrint('[Camera] 错误信息: $e');
      debugPrint('[Camera] 详细堆栈:\n$stackTrace');
      _setError('500_INTERNAL', 'Unexpected error: $e');
    }
    
    debugPrint('[Camera] ========== _onDone 结束 ==========');
  }

  /// 设置错误状态
  void _setError(String code, String message) {
    debugPrint('[Camera] ========== _setError ==========');
    debugPrint('[Camera] 设置错误状态: Code=$code, Message=$message');
    debugPrint('[Camera] 当前状态: $_state');
    debugPrint('[Camera] SessionRoot: $_sessionRoot');
    debugPrint('[Camera] ========== 结束 ==========');
    
    if (!mounted) return;
    
    setState(() {
      _state = CameraState.error;
      _errorCode = code;
      _errorMessage = message;
    });
  }

  /// ✅ 取消分析 - 使用 AnalysisSessionManager
  void _cancel() {
    debugPrint('[Camera] User cancelled analysis');
    if (!mounted) return;
    
    // ✅ 直接调用 Manager 取消
    // 状态更新会通过 _handleSessionState 自动处理
    _sessionManager.cancelCurrentAnalysis();
  }

  /// 计算状态区域的预留高度，避免点击前后布局跳动
  double _computeReservedHeight(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    // 约占屏幕高度的 28%，并限制在 140..240 之间，兼顾小屏与大屏
    final double suggested = screenHeight * 0.28;
    if (suggested < 140) return 140;
    if (suggested > 240) return 240;
    return suggested;
  }

  /// 确保视频路径为文件路径（处理 content:// URI）
  /// Android 录制的视频可能返回 content:// URI，需要转换为文件路径
  Future<String> _ensureFilePath(XFile video) async {
    final path = video.path;
    
    // 如果是 content:// URI（Android），需要复制到临时文件
    if (path.startsWith('content://')) {
      debugPrint('[Camera] Content URI detected, copying to temp file: $path');
      
      try {
        // 使用 path_provider 获取临时目录
        final appDir = await getApplicationDocumentsDirectory();
        final tempDir = Directory('${appDir.path}/temp_videos');
        await tempDir.create(recursive: true);
        
        // 生成唯一文件名
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempPath = '${tempDir.path}/video_$timestamp.mp4';
        
        // 复制文件
        await video.saveTo(tempPath);
        
        debugPrint('[Camera] Video copied to: $tempPath');
        return tempPath;
      } catch (e) {
        debugPrint('[Camera] Failed to copy content URI: $e');
        throw Exception('Failed to process video file: $e');
      }
    }
    
    // 如果已经是文件路径，直接返回
    debugPrint('[Camera] File path detected: $path');
    return path;
  }

  /// 录制视频
  /// 打开系统相机录制视频，返回视频文件路径
  Future<String?> _recordVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2), // 限制视频时长
      );
      
      if (video != null) {
        debugPrint('[Camera] Video recorded: ${video.path}');
        // 确保返回文件路径而非 content:// URI
        final filePath = await _ensureFilePath(video);
        debugPrint('[Camera] Final video path: $filePath');
        return filePath;
      }
      
      debugPrint('[Camera] Video recording cancelled');
      return null;
    } catch (e) {
      debugPrint('[Camera] Failed to record video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record video: $e'),
            backgroundColor: AppColors.surfaceSecondary,
          ),
        );
      }
      return null;
    }
  }

  /// 选择视频
  /// 从相册/文件选择器选择视频，返回视频文件路径
  Future<String?> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
      );
      
      if (video != null) {
        debugPrint('[Camera] Video selected: ${video.path}');
        // 确保返回文件路径而非 content:// URI
        final filePath = await _ensureFilePath(video);
        debugPrint('[Camera] Final video path: $filePath');
        return filePath;
      }
      
      debugPrint('[Camera] Video selection cancelled');
      return null;
    } catch (e) {
      debugPrint('[Camera] Failed to pick video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select video: $e'),
            backgroundColor: AppColors.surfaceSecondary,
          ),
        );
      }
      return null;
    }
  }

  // ✅ Mock 事件流已删除
  // 现在所有分析都通过 AnalysisSessionManager 处理真实视频

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showAppBar: false,
      currentNavIndex: 1,
      child: Container(
        color: AppColors.surfacePrimary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final double reservedHeight = _computeReservedHeight(context);

                final Widget content = Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // 主要内容区域（严格水平居中，不改内部组件）
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 标题区域
                            _buildTitle(context),

                            const SizedBox(height: 32),

                            // Record New Video 按钮（演示模式：触发分析）
                            _buildRecordButton(context),

                            const SizedBox(height: 30),

                            // Import Videos 按钮（演示模式：触发分析）
                            _buildImportButton(context),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 预留固定高度的状态区域，避免点击前后跳动
                    SizedBox(
                      height: reservedHeight,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _buildStateSection(context),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                );

                // 在小高度场景下允许整体滚动以避免溢出
                return constraints.maxHeight < 640
                    ? SingleChildScrollView(child: content)
                    : content;
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 标题区域："Welcome to MoveAnalyzer!"
  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome to',
          style: AppTypography.h2.copyWith(
            color: AppColors.textInvert,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 0.875,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'MoveAnalyzer!',
          style: AppTypography.h2.copyWith(
            color: AppColors.textInvert,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 0.875,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Record New Video 按钮（绿色大按钮）
  Widget _buildRecordButton(BuildContext context) {
    // ✅ 按钮禁用条件：全局会话管理器有正在运行的任务
    final isDisabled = _sessionManager.hasRunningSession;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        key: const ValueKey('action.record_video'),
        width: 250,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.brandPrimaryVariant,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.surfaceSecondary.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : () async {
              final videoPath = await _recordVideo();
              if (videoPath != null && mounted) {
                await _startAnalysis(videoPath: videoPath);
              } else if (mounted && videoPath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video recording cancelled'),
                    backgroundColor: AppColors.surfaceSecondary,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.videocam,
                    color: AppColors.textInvert,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Record New Video',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.button.copyWith(
                        color: AppColors.textInvert,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: AppColors.surfaceSecondary.withOpacity(0.25),
                            offset: const Offset(0, 4),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Import Videos 按钮（深灰色按钮）
  Widget _buildImportButton(BuildContext context) {
    // ✅ 按钮禁用条件：全局会话管理器有正在运行的任务
    final isDisabled = _sessionManager.hasRunningSession;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        key: const ValueKey('action.import_video'),
        width: 200,
        height: 48,
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : () async {
              final videoPath = await _pickVideo();
              if (videoPath != null && mounted) {
                await _startAnalysis(videoPath: videoPath);
              } else if (mounted && videoPath == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No video selected'),
                    backgroundColor: AppColors.surfaceSecondary,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload,
                  color: AppColors.textInvert,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Import Videos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.button.copyWith(
                      color: AppColors.textInvert,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 状态显示区域（根据状态切换）
  Widget _buildStateSection(BuildContext context) {
    switch (_state) {
      case CameraState.idle:
        return const SizedBox.shrink();

      case CameraState.preparing:
      case CameraState.running:
      case CameraState.parsing:
        return _buildProgressSection(context);

      case CameraState.error:
        return _buildErrorSection(context);

      case CameraState.success:
        return const SizedBox.shrink();
    }
  }

  /// 进度条区域（动态 UI）
  Widget _buildProgressSection(BuildContext context) {
    // 获取屏幕宽度以计算进度条宽度
    final screenWidth = MediaQuery.of(context).size.width;
    final progressBarWidth = screenWidth - 32; // 减去左右 padding
    final progressWidth = progressBarWidth * _progress;

    return Column(
      children: [
        // 质量警告提示（黄条）
        if (_showQualityWarning && _qualityMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    _qualityMessage!,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.surfaceSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 进度条容器
        SizedBox(
          height: 40,
          width: progressBarWidth,
          child: Stack(
            children: [
              // 背景进度条（灰色）
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.surfaceSecondary.withOpacity(0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                      spreadRadius: 0,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
              ),
              
              // 前景进度条（绿色，动态宽度）
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: progressWidth.clamp(0, progressBarWidth),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryVariant,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.surfaceSecondary.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 进度文本
        Text(
          _buildProgressText(),
          style: AppTypography.bodyBold.copyWith(
            color: AppColors.textInvert,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        // ETA 和性能信息
        if (_etaSec != null || _p95Ms != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _buildMetricsText(),
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert.withOpacity(0.7),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // 取消按钮
        if (_state == CameraState.running)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TextButton(
              key: const ValueKey('action.cancel_analysis'),
              onPressed: _cancel,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textInvert,
              ),
              child: const Text('Cancel'),
            ),
          ),
      ],
    );
  }

  /// 错误显示区域
  Widget _buildErrorSection(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceSecondary, width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: AppColors.surfaceSecondary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error: $_errorCode',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.surfaceSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.surfaceSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('action.dismiss_error'),
              onPressed: () {
                setState(() {
                  _state = CameraState.idle;
                  _errorCode = null;
                  _errorMessage = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimaryVariant,
                foregroundColor: AppColors.textInvert,
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建进度文本
  String _buildProgressText() {
    // ✅ 取消状态现在通过 _currentPhase 显示（由 _handleSessionState 设置）
    switch (_state) {
      case CameraState.preparing:
        return _currentPhase ?? 'Preparing...';
      case CameraState.running:
        final percent = (_progress * 100).toInt();
        return '${_currentPhase ?? 'Analyzing'}... $percent%';
      case CameraState.parsing:
        return 'Parsing results...';
      default:
        return '';
    }
  }

  /// 构建性能指标文本
  String _buildMetricsText() {
    final parts = <String>[];
    if (_etaSec != null) {
      parts.add('ETA: ${_etaSec}s');
    }
    if (_p95Ms != null) {
      parts.add('${_p95Ms}ms/frame');
    }
    return parts.join(' • ');
  }
}

