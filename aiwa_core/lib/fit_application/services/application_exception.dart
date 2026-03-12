/// Application 层自定义异常（Spec §5.3）
///
/// 用于 Application 层内部逻辑错误，例如 UTC 断言失败。
class ApplicationException implements Exception {
  final String errorCode;
  final String message;
  final Map<String, dynamic>? context;

  const ApplicationException(this.errorCode, this.message, [this.context]);

  @override
  String toString() {
    final ctx = context == null ? '' : ' context=$context';
    return 'ApplicationException($errorCode): $message$ctx';
  }
}

/// 断言 nowUtc 必须是 UTC（Spec §5.1 强制校验）
///
/// 所有写用例在执行时必须调用此方法；否则抛出 [ApplicationException]。
void requireClockUtc(DateTime nowUtc) {
  if (!nowUtc.isUtc) {
    throw ApplicationException(
      'application.clock.not_utc',
      'clock.nowUtc() must return a UTC DateTime (isUtc == true)',
      {'value': nowUtc.toIso8601String()},
    );
  }
}
