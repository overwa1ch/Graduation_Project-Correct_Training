sealed class AiwaError implements Exception {
  final String
      code; // RULES_PARSE_ERROR, ANGLE_COMPUTE_FAILED, METRICS_COMPUTE_FAILED, ...
  final String message;
  const AiwaError(this.code, this.message);
  
  /// Whether this error allows partial data to be saved (degraded mode)
  /// Fatal errors (false) will trigger cleanup and no data storage
  /// Recoverable errors (true) will save keypoints and partial results
  bool get isRecoverable => false; // Default: fatal
  
  @override
  String toString() => '[$code] $message';
}

class RulesParseError extends AiwaError {
  RulesParseError(String m) : super('RULES_PARSE_ERROR', m);
}

class AngleComputeFailed extends AiwaError {
  AngleComputeFailed(String m) : super('ANGLE_COMPUTE_FAILED', m);
  
  @override
  bool get isRecoverable => true; // Keypoints exist, can save partial result
}

class MetricsComputeFailed extends AiwaError {
  MetricsComputeFailed(String m) : super('METRICS_COMPUTE_FAILED', m);
  
  @override
  bool get isRecoverable => true; // Angles exist, can save partial result
}
