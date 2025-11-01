// error_code_mapper.dart
// Version: v1.0
// Purpose: 错误码归一化映射 - 统一不同来源的错误码格式
//
// 契约依据：
// - docs/protocols/ERROR_TO_ACTION.md v1.1 (标准错误码与兼容映射)
//
// 职责：
// 1. 将代码中使用的错误码归一化为文档标准格式
// 2. 提供错误码到 UI 行为的映射
//
// 使用示例：
// ```dart
// final normalized = normalizeErrorCode('400_PARSE');  // => '400_PARSE'
// final normalized2 = normalizeErrorCode('ERROR_PARSE');  // => '400_PARSE'
// 
// final action = getErrorAction('422_CONTRACT');
// // => ErrorAction(uiResponse: 'toast', recoveryHint: '...')
// ```

/// 错误码归一化
/// 
/// 将历史错误码或变体映射为标准错误码
/// 
/// 参数:
/// - [rawCode]: 原始错误码
/// 
/// 返回: 标准错误码
String normalizeErrorCode(String rawCode) {
  // 兼容映射表（基于 ERROR_TO_ACTION.md v1.1）
  const compatibilityMap = {
    // 历史格式 → 标准格式
    'ERROR_PARSE': '400_PARSE',
    '408_TIMEOUT': '408_WARMUP_TIMEOUT',
    '500_INFER_FAIL': '500_INTERNAL',
    '500_IO_FAIL': '500_INTERNAL',
    
    // 同义词归一
    '422_SCHEMA_MISMATCH': '422_CONTRACT',  // 统一为 422_CONTRACT
  };

  return compatibilityMap[rawCode] ?? rawCode;
}

/// 错误行为描述
class ErrorAction {
  final String uiResponse;
  final String recoveryHint;
  final bool showRetry;
  final bool showLogs;
  final bool showCleanup;

  const ErrorAction({
    required this.uiResponse,
    required this.recoveryHint,
    this.showRetry = true,
    this.showLogs = false,
    this.showCleanup = false,
  });
}

/// 获取错误码对应的 UI 行为
/// 
/// 基于 ERROR_TO_ACTION.md v1.1 的映射表
/// 
/// 参数:
/// - [code]: 错误码（已归一化或原始）
/// 
/// 返回: ErrorAction 描述 UI 行为
ErrorAction getErrorAction(String code) {
  // 先归一化
  final normalized = normalizeErrorCode(code);

  // 标准错误码映射
  switch (normalized) {
    case '400_PARSE':
      return const ErrorAction(
        uiResponse: 'error_dialog',
        recoveryHint: '查看 run.log 片段',
        showRetry: true,
        showLogs: true,
      );

    case '404_FILE_NOT_FOUND':
      return const ErrorAction(
        uiResponse: 'error_dialog',
        recoveryHint: '检查文件路径/权限',
        showRetry: true,
      );

    case '408_WARMUP_TIMEOUT':
      return const ErrorAction(
        uiResponse: 'retry_dialog',
        recoveryHint: '提供"降分辨率重试"',
        showRetry: true,
      );

    case '422_CONTRACT':
      return const ErrorAction(
        uiResponse: 'warning_toast',
        recoveryHint: '指引对齐 App/CLI 版本',
        showRetry: false,
      );

    case '500_INTERNAL':
      return const ErrorAction(
        uiResponse: 'error_dialog',
        recoveryHint: '查看日志 + 重试',
        showRetry: true,
        showLogs: true,
      );

    case '500_RESULT_READ':
      return const ErrorAction(
        uiResponse: 'error_dialog',
        recoveryHint: '检查文件权限/路径',
        showRetry: true,
      );

    case '501_NOT_IMPLEMENTED':
      return const ErrorAction(
        uiResponse: 'info_toast',
        recoveryHint: '等待功能更新',
        showRetry: false,
      );

    // 扩展错误码
    case 'ERROR_NO_EVIDENCE':
      return const ErrorAction(
        uiResponse: 'warning_banner',
        recoveryHint: '回退到 window 片段',
        showRetry: false,
      );

    case 'ERROR_LOW_STORAGE':
      return const ErrorAction(
        uiResponse: 'warning_banner',
        recoveryHint: '触发"一键清理"',
        showRetry: false,
        showCleanup: true,
      );

    // CLI 异常退出（动态错误码）
    default:
      if (normalized.startsWith('500_CLI_EXIT_')) {
        return const ErrorAction(
          uiResponse: 'error_dialog',
          recoveryHint: '"报告问题"/附 stderr 片段',
          showRetry: true,
          showLogs: true,
        );
      }

      // 未知错误码 - 默认行为
      return const ErrorAction(
        uiResponse: 'error_dialog',
        recoveryHint: '"分析失败"通用提示 + 查看日志 + 重试',
        showRetry: true,
        showLogs: true,
      );
  }
}

/// 获取用户友好的错误消息
/// 
/// 参数:
/// - [code]: 错误码
/// - [originalMessage]: 原始错误消息（可选）
/// 
/// 返回: 用户友好的错误消息
String getUserFriendlyErrorMessage(String code, {String? originalMessage}) {
  final normalized = normalizeErrorCode(code);

  const messages = {
    '400_PARSE': 'JSON 解析失败',
    '404_FILE_NOT_FOUND': '文件不存在',
    '408_WARMUP_TIMEOUT': 'CLI 启动超时',
    '422_CONTRACT': '版本不匹配，请更新',
    '500_INTERNAL': '内部错误',
    '500_RESULT_READ': '读取结果失败',
    '501_NOT_IMPLEMENTED': '功能未实现',
    'ERROR_NO_EVIDENCE': '无证据帧',
    'ERROR_LOW_STORAGE': '空间不足',
  };

  if (normalized.startsWith('500_CLI_EXIT_')) {
    return 'CLI 异常退出';
  }

  final friendlyMsg = messages[normalized] ?? '分析失败';
  
  // 如果有原始消息，追加详情
  if (originalMessage != null && originalMessage.isNotEmpty) {
    return '$friendlyMsg: $originalMessage';
  }

  return friendlyMsg;
}

