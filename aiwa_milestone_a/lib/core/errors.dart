sealed class AiwaError implements Exception {
  final String code;   // RULES_PARSE_ERROR, INPUT_KP_INVALID, MODEL_ADAPTER_MISSING, ...
  final String message;
  const AiwaError(this.code, this.message);
  @override String toString() => '[$code] $message';
}

class RulesParseError extends AiwaError {
  RulesParseError(String m) : super('RULES_PARSE_ERROR', m);
}

class InputKpInvalid extends AiwaError {
  InputKpInvalid(String m) : super('INPUT_KP_INVALID', m);
}

class ModelAdapterMissing extends AiwaError {
  ModelAdapterMissing(String m) : super('MODEL_ADAPTER_MISSING', m);
}

class AngleComputeFailed extends AiwaError {
  AngleComputeFailed(String m) : super('ANGLE_COMPUTE_FAILED', m);
}

class CountingInconsistent extends AiwaError {
  CountingInconsistent(String m) : super('COUNTING_INCONSISTENT', m);
}

class MetricsComputeFailed extends AiwaError {
  MetricsComputeFailed(String m) : super('METRICS_COMPUTE_FAILED', m);
}
