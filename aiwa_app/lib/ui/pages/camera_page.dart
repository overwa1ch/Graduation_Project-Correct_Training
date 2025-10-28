import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/result_popup_page.dart';
import 'package:aiwa_app/services/event_bus.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';
import 'package:aiwa_app/services/config_sync.dart';
import 'package:aiwa_app/services/session_manager.dart';

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

class _CameraPageState extends State<CameraPage> {
  // 状态管理
  CameraState _state = CameraState.idle;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  bool _running = false;
  
  // 进度信息
  double _progress = 0.0;
  int? _etaSec;
  int? _p95Ms;
  String? _currentPhase;
  
  // 会话信息
  String? _sessionRoot;
  
  // 质量提示
  bool _showQualityWarning = false;
  String? _qualityMessage;
  
  // 证据缓存
  Map<String, dynamic>? _firstEvidence;
  
  // 错误信息
  String? _errorCode;
  String? _errorMessage;

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }

  /// 启动分析流程
  Future<void> _startAnalysis() async {
    // 单一运行保护
    if (_running) return;
    
    setState(() {
      _running = true;
      _state = CameraState.idle;
      _progress = 0.0;
      _etaSec = null;
      _p95Ms = null;
      _currentPhase = null;
      _showQualityWarning = false;
      _qualityMessage = null;
      _firstEvidence = null;
      _errorCode = null;
      _errorMessage = null;
    });

    try {
      // 1. 创建会话目录
      _sessionRoot = await SessionManager.createSessionRoot();
      debugPrint('[Camera] Session root: $_sessionRoot');

      // 2. 读取配置并写入会话快照
      final cfg = await readAppRuntimeConfig();
      await writeRuntimeSnapshot(_sessionRoot!, cfg);

      // 3. 构建 CLI 参数（演示模式：使用 JSONL 文件）
      // 真实模式下，pickedInput 应该是用户选择的视频路径
      buildCliArgs(
        pickedInput: 'dev/demo_video.mp4', // TODO: 替换为实际视频选择
        sessionRoot: _sessionRoot!,
      );

      // 4. 启动事件流（演示模式：从 JSONL 文件读取）
      // 真实模式下，使用 analysisEventsFromCli
      final stream = analysisEventsFromJsonlFile(
        'dev/stdout_demo.jsonl',
        debugLog: (msg) => debugPrint('[EventBus] $msg'),
      );

      // 真实 CLI 模式示例：
      // final stream = analysisEventsFromCli(
      //   dartBin: 'dart',
      //   args: [
      //     'run', 'aiwa_cli/bin/aiwa_cli.dart',
      //     '--input', args.inputPath,
      //     '--out', args.sessionRoot,
      //     '--config', args.configPath,
      //   ],
      //   debugLog: (msg) => debugPrint('[EventBus] $msg'),
      // );

      // 5. 监听事件并更新 UI 状态
      _eventSubscription = stream.listen(
        _handleEvent,
        onError: (Object err, StackTrace st) {
          debugPrint('[Camera] Stream error: $err');
          _setError('500_INTERNAL', 'Stream error: $err');
        },
        onDone: () {
          debugPrint('[Camera] Stream closed');
          setState(() => _running = false);
        },
      );
    } catch (e, st) {
      debugPrint('[Camera] Failed to start analysis: $e\n$st');
      _setError('500_INTERNAL', 'Failed to start analysis: $e');
      setState(() => _running = false);
    }
  }

  /// 处理事件
  void _handleEvent(Map<String, dynamic> event) {
    final eventName = event['event'] as String?;
    if (eventName == null) return;

    debugPrint('[Camera] Event: $eventName');

    switch (eventName) {
      case 'START':
        setState(() {
          _state = CameraState.preparing;
          _currentPhase = 'Starting...';
        });
        break;

      case 'PHASE':
        final phase = event['phase'] as String?;
        setState(() {
          _currentPhase = phase ?? 'Processing...';
        });
        break;

      case 'PROGRESS':
        final processed = (event['processed'] ?? 0) as num;
        final total = (event['total'] ?? 0) as num;
        final progress = (total > 0) ? (processed / total).clamp(0.0, 1.0) : 0.0;
        final etaSec = (event['etaSec'] as num?)?.toInt();
        final p95Ms = (event['p95MsPerFrame'] as num?)?.toInt();

        setState(() {
          _state = CameraState.running;
          _progress = progress.toDouble();
          _etaSec = etaSec;
          _p95Ms = p95Ms;
        });
        break;

      case 'METRIC':
        _updateQualityHint(event);
        break;

      case 'EVIDENCE':
        _cacheEvidence(event);
        break;

      case 'DONE':
        setState(() {
          _state = CameraState.parsing;
          _currentPhase = 'Parsing results...';
        });
        _onDone();
        break;

      case 'ERROR':
        final code = event['code'] as String? ?? 'UNKNOWN';
        final message = event['message'] as String? ?? 'Unknown error';
        _setError(code, message);
        break;
    }
  }

  /// 更新质量提示
  void _updateQualityHint(Map<String, dynamic> event) {
    final lowConfidenceRatio = (event['lowConfidenceRatio'] as num?)?.toDouble();
    final usableFrameRatio = (event['usableFrameRatio'] as num?)?.toDouble();

    if (lowConfidenceRatio != null && lowConfidenceRatio > 0.3) {
      setState(() {
        _showQualityWarning = true;
        _qualityMessage = 'Low confidence detected (${(lowConfidenceRatio * 100).toInt()}%)';
      });
    } else if (usableFrameRatio != null && usableFrameRatio < 0.7) {
      setState(() {
        _showQualityWarning = true;
        _qualityMessage = 'Low coverage (${(usableFrameRatio * 100).toInt()}%)';
      });
    }
  }

  /// 缓存证据
  void _cacheEvidence(Map<String, dynamic> event) {
    if (_firstEvidence == null) {
      _firstEvidence = event;
      debugPrint('[Camera] Cached first evidence');
    }
  }

  /// 处理 DONE 事件
  Future<void> _onDone() async {
    if (_sessionRoot == null) {
      _setError('500_INTERNAL', 'Session root is null');
      return;
    }

    try {
      // 解析 result.json
      final raw = await readResultJson(_sessionRoot!);
      assertResultContract(raw);
      final lite = mapToLite(raw);

      debugPrint('[Camera] Result parsed: $lite');

      // 弹出结果页面
      if (mounted) {
        setState(() => _state = CameraState.success);
        showResultPopup(context, lite, _sessionRoot!);
      }
    } on SchemaMismatch catch (e) {
      debugPrint('[Camera] Schema mismatch: $e');
      _setError('422_SCHEMA_MISMATCH', 'Schema mismatch: ${e.message}');
    } on ResultReadException catch (e) {
      debugPrint('[Camera] Result read error: $e');
      _setError('500_RESULT_READ', 'Failed to read result: ${e.message}');
    } catch (e) {
      debugPrint('[Camera] Unexpected error: $e');
      _setError('500_INTERNAL', 'Unexpected error: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  /// 设置错误状态
  void _setError(String code, String message) {
    setState(() {
      _state = CameraState.error;
      _errorCode = code;
      _errorMessage = message;
      _running = false;
    });
  }

  /// 重试
  void _retry() {
    _startAnalysis();
  }

  /// 取消分析
  void _cancel() {
    _eventSubscription?.cancel();
    setState(() {
      _state = CameraState.idle;
      _running = false;
      _progress = 0.0;
    });
  }

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // 主要内容区域
                Column(
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
                
                const Spacer(),
                
                // 状态显示区域（根据状态切换）
                _buildStateSection(context),
                
                const SizedBox(height: 30),
              ],
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
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  /// Record New Video 按钮（绿色大按钮）
  Widget _buildRecordButton(BuildContext context) {
    // 按钮禁用条件：正在运行中
    final isDisabled = _running;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        width: 250,
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.brandPrimary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : _startAnalysis,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 视频图标
                  Icon(
                    Icons.videocam,
                    color: AppColors.textInvert,
                    size: 30,
                  ),
                  const SizedBox(width: 8),
                  // 文本
                  SizedBox(
                    width: 200,
                    child: Text(
                      'Record New Video',
                      style: AppTypography.button.copyWith(
                        color: AppColors.textInvert,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.25),
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
    // 按钮禁用条件：正在运行中
    final isDisabled = _running;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        width: 200,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled ? null : _startAnalysis,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 上传图标
                Icon(
                  Icons.upload,
                  color: AppColors.textInvert,
                  size: 24,
                ),
                const SizedBox(width: 8),
                // 文本
                Text(
                  'Import Videos',
                  style: AppTypography.button.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
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
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _qualityMessage!,
                    style: AppTypography.bodyBase.copyWith(
                      color: Colors.orange,
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
                      color: Colors.black.withOpacity(0.25),
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
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Text(
                'Error: $_errorCode',
                style: AppTypography.bodyBold.copyWith(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: AppTypography.bodyBase.copyWith(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: AppColors.textInvert,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// 构建进度文本
  String _buildProgressText() {
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

