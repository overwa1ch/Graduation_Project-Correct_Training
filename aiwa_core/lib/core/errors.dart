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

// ============================================================================
// Core Pipeline Errors
// ============================================================================

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

// ============================================================================
// Video Processing Errors (aiwa_app)
// ============================================================================

class VideoProcessingError extends AiwaError {
  VideoProcessingError(String m) : super('VIDEO_PROCESSING_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Can retry or save partial data
}

class FrameExtractionError extends AiwaError {
  FrameExtractionError(String m) : super('FRAME_EXTRACTION_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Can retry with different settings
}

class VideoEncodingError extends AiwaError {
  VideoEncodingError(String m) : super('VIDEO_ENCODING_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Encoding is optional
}

// ============================================================================
// Configuration & Data Errors
// ============================================================================

class ConfigLoadError extends AiwaError {
  ConfigLoadError(String m) : super('CONFIG_LOAD_ERROR', m);
}

class DataFormatError extends AiwaError {
  DataFormatError(String m) : super('DATA_FORMAT_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Can use default values
}

class SchemaValidationError extends AiwaError {
  SchemaValidationError(String m) : super('SCHEMA_VALIDATION_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Partial data may still be usable
}

// ============================================================================
// Network & API Errors
// ============================================================================

class NetworkError extends AiwaError {
  NetworkError(String m) : super('NETWORK_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Can retry
}

class ApiError extends AiwaError {
  ApiError(String m) : super('API_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Can retry
}

// ============================================================================
// Event & Contract Errors
// ============================================================================

class EventParseError extends AiwaError {
  EventParseError(String m) : super('EVENT_PARSE_ERROR', m);
  
  @override
  bool get isRecoverable => true; // Can skip malformed event
}

class ContractViolationError extends AiwaError {
  ContractViolationError(String m) : super('CONTRACT_VIOLATION_ERROR', m);
}

// ============================================================================
// CLI & Process Errors
// ============================================================================

class CliExecutionError extends AiwaError {
  final int? exitCode;
  
  CliExecutionError(String m, {this.exitCode}) : super('CLI_EXECUTION_ERROR', m);
  
  @override
  String toString() => exitCode != null
      ? '[$code] $message (exit code: $exitCode)'
      : '[$code] $message';
}
