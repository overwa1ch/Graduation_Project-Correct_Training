// analysis_session_manager.dart
// Version: v2.0
// Purpose: 全局会话管理器 - 确保同一时间只有一个分析任务运行
//
// 职责：
// 1. 管理当前活跃的分析会话
// 2. 防止并发分析任务
// 3. 提供取消分析的能力
// 4. 广播分析状态变化
//
// 使用示例：
// ```dart
// final manager = AnalysisSessionManager();
// final success = await manager.startAnalysis(
//   videoPath: '/path/to/video.mp4',
//   sessionRoot: '/path/to/session',
// );
//
// // 监听状态变化
// manager.stateStream.listen((state) {
//   if (state is AnalysisStateRunning) {
//     print('Progress: ${state.progress}');
//   }
// });
//
// // 取消分析
// manager.cancelCurrentAnalysis();
// ```

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:aiwa_app/services/video_analysis_service.dart';
import 'package:aiwa_app/services/cancellation_token.dart';
import 'package:aiwa_app/services/config_sync.dart';
import 'package:aiwa_core/spec/rule_models.dart';

// ============================================================================
// 状态类型定义（sealed class hierarchy）
// ============================================================================

/// 分析状态基类（sealed class - 所有状态必须继承此类）
sealed class AnalysisState {
  const AnalysisState();
}

/// 空闲状态
class AnalysisStateIdle extends AnalysisState {
  const AnalysisStateIdle();
}

/// 准备中状态
class AnalysisStatePreparing extends AnalysisState {
  final String? currentPhase;
  const AnalysisStatePreparing({this.currentPhase});
}

/// 运行中状态
class AnalysisStateRunning extends AnalysisState {
  final double progress;
  final String? phase;
  final int? etaSec;
  final int? p95Ms;
  final bool showQualityWarning;
  final String? qualityMessage;

  const AnalysisStateRunning({
    required this.progress,
    this.phase,
    this.etaSec,
    this.p95Ms,
    this.showQualityWarning = false,
    this.qualityMessage,
  });
}

/// 解析中状态
class AnalysisStateParsing extends AnalysisState {
  final String? message;
  const AnalysisStateParsing({this.message});
}

/// 成功状态
class AnalysisStateSuccess extends AnalysisState {
  final String sessionRoot;
  const AnalysisStateSuccess({required this.sessionRoot});
}

/// 错误状态
class AnalysisStateError extends AnalysisState {
  final String errorCode;
  final String errorMessage;
  const AnalysisStateError({
    required this.errorCode,
    required this.errorMessage,
  });
}

/// 取消中状态
class AnalysisStateCancelling extends AnalysisState {
  final String? message;
  const AnalysisStateCancelling({this.message});
}

// ============================================================================
// 分析会话管理器（全局单例）
// ============================================================================

/// 分析会话管理器 - 确保同一时间只有一个分析任务运行
class AnalysisSessionManager {
  // 单例模式
  static final AnalysisSessionManager _instance = AnalysisSessionManager._internal();
  factory AnalysisSessionManager() => _instance;
  AnalysisSessionManager._internal();

  // 当前活跃的会话
  AnalysisSession? _currentSession;

  // 全局状态流控制器（用于广播状态变化）
  final StreamController<AnalysisState> _stateController = StreamController<AnalysisState>.broadcast();

  /// 状态流（供外部监听）
  Stream<AnalysisState> get stateStream => _stateController.stream;

  /// 是否有正在运行的会话
  bool get hasRunningSession => _currentSession != null && !_currentSession!.isCompleted;

  /// 开始新的分析会话
  ///
  /// 返回: true 表示成功启动，false 表示已有会话正在运行
  Future<bool> startAnalysis({
    required String videoPath,
    required String sessionRoot,
  }) async {
    debugPrint('[SessionManager] ========================================');
    debugPrint('[SessionManager] 🚀 startAnalysis() called');
    debugPrint('[SessionManager] videoPath: $videoPath');
    debugPrint('[SessionManager] sessionRoot: $sessionRoot');
    debugPrint('[SessionManager] Current session: $_currentSession');
    debugPrint('[SessionManager] hasRunningSession: $hasRunningSession');

    // 如果已有会话正在运行，拒绝新会话
    if (hasRunningSession) {
      debugPrint('[SessionManager] ⚠️ Rejected: already has running session');
      debugPrint('[SessionManager] ========================================');
      return false;
    }

    // 创建新会话
    final baseDir = await getApplicationSupportDirectory();
    final configPath = '${baseDir.path}/aiwa/configs/app_runtime.json';
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomSuffix()}';
    
    debugPrint('[SessionManager] 📝 Creating new session: $sessionId');
    _currentSession = AnalysisSession(
      videoPath: videoPath,
      sessionRoot: sessionRoot,
      configPath: configPath,
      sessionId: sessionId,
      onStateChange: (state) {
        debugPrint('[SessionManager] 📡 Broadcasting state: ${state.runtimeType}');
        if (!_stateController.isClosed) {
          _stateController.add(state);
        }
      },
      onDone: () {
        debugPrint('[SessionManager] ✅ Session done, clearing current session');
        _currentSession = null;
      },
      onError: (errorCode, errorMessage) {
        debugPrint('[SessionManager] ❌ Session error: $errorCode - $errorMessage');
        _currentSession = null;
        if (!_stateController.isClosed) {
          _stateController.add(AnalysisStateError(
            errorCode: errorCode,
            errorMessage: errorMessage,
          ));
        }
      },
    );

    debugPrint('[SessionManager] ✅ Session created successfully');
    debugPrint('[SessionManager] ========================================');
    return true;
  }

  /// 取消当前分析并等待任务真正完成
  /// 
  /// 此方法会阻塞，直到分析任务完全停止（包括资源清理）
  /// 在等待期间，hasRunningSession 返回 true，阻止新任务启动
  Future<void> cancelCurrentAnalysis() async {
    debugPrint('[SessionManager] 🛑 cancelCurrentAnalysis() called');
    if (_currentSession != null) {
      debugPrint('[SessionManager] Cancelling session: ${_currentSession!.sessionId}');
      
      // 立即发出取消中状态
      if (!_stateController.isClosed) {
        _stateController.add(const AnalysisStateCancelling(message: 'Cancelling analysis...'));
      }
      
      // ✅ 关键修复：等待 cancel() 完成，确保任务真正停止
      await _currentSession!.cancel();
      debugPrint('[SessionManager] ✅ Session cancelled and confirmed stopped');
      
      // ✅ 确认停止后才清理会话引用
      // 注意：cancel() 方法已经发送了 Idle 状态，这里不需要重复发送
      _currentSession = null;
    } else {
      debugPrint('[SessionManager] ⚠️ No current session to cancel');
    }
    debugPrint('[SessionManager] ========================================');
  }

  /// 生成随机后缀（4位16进制）
  String _generateRandomSuffix() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return (timestamp % 65536).toRadixString(16).padLeft(4, '0');
  }

  /// 释放资源（仅在应用关闭时调用）
  void dispose() {
    _currentSession?.cancel();
    _currentSession = null;
    _stateController.close();
  }
}

// ============================================================================
// 分析会话（内部类）
// ============================================================================

/// 单个分析会话 - 封装 VideoAnalysisService 的事件流
class AnalysisSession {
  final String videoPath;
  final String sessionRoot;
  final String configPath;
  final String sessionId;
  final void Function(AnalysisState) onStateChange;
  final void Function() onDone;
  final void Function(String errorCode, String errorMessage) onError;

  /// 取消令牌 - 用于统一取消机制
  final CancellationToken _token;
  
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  bool _isCompleted = false;
  Future<void>? _analysisFuture;  // ✅ 保存分析任务的 Future

  AnalysisSession({
    required this.videoPath,
    required this.sessionRoot,
    required this.configPath,
    required this.sessionId,
    required this.onStateChange,
    required this.onDone,
    required this.onError,
  }) : _token = CancellationToken(
          id: sessionId,
          sessionId: sessionId,
        ) {
    _start();
  }

  bool get isCompleted => _isCompleted;

  void _start() {
    debugPrint('[AnalysisSession] Starting analysis (session: $sessionId)');
    
    // 发出准备中状态
    onStateChange(const AnalysisStatePreparing(currentPhase: 'Initializing...'));

    // 异步启动分析（读取配置）
    _startAsync();
  }

  /// 异步启动分析（读取配置并创建事件流）
  Future<void> _startAsync() async {
    try {
      // 从配置服务读取 strictness
      Strictness strictness = Strictness.relaxed; // 默认值
      try {
        final config = await readAppRuntimeConfig();
        final strictnessStr = config['strictness'] as String?;
        if (strictnessStr == 'strict') {
          strictness = Strictness.strict;
        }
        debugPrint('[AnalysisSession] Using strictness: ${strictness.value}');
      } catch (e) {
        debugPrint('[AnalysisSession] Failed to read strictness config, using default: $e');
      }

      // 创建事件流和任务 Future
      final result = VideoAnalysisService.analyzeVideo(
        token: _token,
        strictness: strictness,
        videoPath: videoPath,
        sessionRoot: sessionRoot,
        configPath: configPath,
        sessionId: sessionId,
      );
      
      // ✅ 保存任务 Future
      _analysisFuture = result.task;

      // 订阅事件流
      _eventSubscription = result.stream.listen(
        _handleEvent,
        onError: (Object err) {
          debugPrint('[AnalysisSession] Stream error: $err');
          onError('500_INTERNAL', 'Stream error: $err');
          _complete();
        },
        onDone: () {
          debugPrint('[AnalysisSession] Stream done');
          if (!_isCompleted) {
            onDone();
            _complete();
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('[AnalysisSession] Failed to start analysis: $e');
      onError('500_INTERNAL', 'Failed to start analysis: $e');
      _complete();
    }
  }

  void _handleEvent(Map<String, dynamic> event) {
    if (_isCompleted) {
      debugPrint('[AnalysisSession] Ignoring event after completion: ${event['event']}');
      return;
    }

    final eventType = event['event'] as String?;
    debugPrint('[AnalysisSession] Event: $eventType');

    switch (eventType) {
      case 'START':
        onStateChange(const AnalysisStatePreparing(currentPhase: 'Starting analysis...'));
        break;

      case 'PHASE':
        final phase = event['phase'] as String?;
        onStateChange(AnalysisStatePreparing(currentPhase: _formatPhase(phase)));
        break;

      case 'PROGRESS':
        final phase = event['phase'] as String?;
        final processed = event['processed'] as int? ?? 0;
        final total = event['total'] as int? ?? 1;
        final progress = (processed / total).clamp(0.0, 1.0);
        final etaSec = event['etaSec'] as int? ?? event['eta_sec'] as int?;
        final p95Ms = event['p95MsPerFrame'] as int? ?? event['p95_ms'] as int?;

        onStateChange(AnalysisStateRunning(
          progress: progress,
          phase: _formatPhase(phase),
          etaSec: etaSec,
          p95Ms: p95Ms,
        ));
        break;

      case 'METRIC':
        final lowConfidenceRatio = event['lowConfidenceRatio'] as double? ?? 0.0;
        if (lowConfidenceRatio > 0.3) {
          onStateChange(const AnalysisStateRunning(
            progress: 0.5,
            showQualityWarning: true,
            qualityMessage: 'Low confidence detected - please check lighting and camera angle',
          ));
        }
        break;

      case 'EVIDENCE':
        // 证据帧事件可以忽略或记录
        break;

      case 'DONE':
        debugPrint('[AnalysisSession] Analysis complete');
        onStateChange(AnalysisStateSuccess(sessionRoot: sessionRoot));
        _complete();
        break;

      case 'ERROR':
        final errorCode = event['code'] as String? ?? '500_UNKNOWN';
        final errorMessage = event['message'] as String? ?? 'Unknown error';
        debugPrint('[AnalysisSession] Error: $errorCode - $errorMessage');
        onError(errorCode, errorMessage);
        _complete();
        break;

      default:
        debugPrint('[AnalysisSession] Unknown event: $eventType');
    }
  }

  String _formatPhase(String? phase) {
    switch (phase) {
      case 'decode':
        return 'Extracting frames...';
      case 'infer':
        return 'Detecting poses...';
      case 'analyze':
        return 'Analyzing movement...';
      default:
        return phase ?? 'Processing...';
    }
  }

  /// 取消分析任务并等待其真正完成
  /// 
  /// 此方法会阻塞，直到底层分析任务完全停止（包括资源清理）
  Future<void> cancel() async {
    debugPrint('[AnalysisSession] Cancelling analysis (session: $sessionId)');
    
    if (_isCompleted) {
      debugPrint('[AnalysisSession] Already completed, nothing to cancel');
      return;
    }
    
    // 1. 标记令牌为取消状态（统一取消信号）
    _token.cancel();
    debugPrint('[AnalysisSession] Cancellation token marked as cancelling');
    
    // 2. 取消订阅（停止接收事件）
    _eventSubscription?.cancel();
    _eventSubscription = null;
    
    // 3. ✅ 等待底层任务真正完成
    if (_analysisFuture != null) {
      debugPrint('[AnalysisSession] Waiting for analysis task to complete...');
      try {
        await _analysisFuture;
        debugPrint('[AnalysisSession] Analysis task confirmed stopped ✓');
      } catch (e) {
        // 即使任务出错，我们也认为它已经停止
        debugPrint('[AnalysisSession] Analysis task stopped with error: $e');
      }
    }
    
    // 4. 标记为完成
    _isCompleted = true;
    
    // 5. 发送 Idle 状态
    onStateChange(const AnalysisStateIdle());
  }

  void _complete() {
    if (_isCompleted) return;
    
    _isCompleted = true;
    _eventSubscription?.cancel();
    _eventSubscription = null;

    // 延迟发送 Idle 状态，以便 UI 有时间显示完成状态
    Future.delayed(const Duration(milliseconds: 200), () {
      onStateChange(const AnalysisStateIdle());
    });
  }
}

