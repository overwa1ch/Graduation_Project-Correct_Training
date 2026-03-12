class DomainException implements Exception {
  final String errorCode;
  final String message;
  final Map<String, dynamic>? context;

  const DomainException(this.errorCode, this.message, [this.context]);

  @override
  String toString() {
    final ctx = context == null ? '' : ' context=$context';
    return 'DomainException($errorCode): $message$ctx';
  }
}

class ValidationException extends DomainException {
  const ValidationException(String errorCode, String message,
      [Map<String, dynamic>? context])
      : super(errorCode, message, context);
}

class NotFoundException extends DomainException {
  const NotFoundException(String errorCode, String message,
      [Map<String, dynamic>? context])
      : super(errorCode, message, context);
}

class InvariantException extends DomainException {
  const InvariantException(String errorCode, String message,
      [Map<String, dynamic>? context])
      : super(errorCode, message, context);
}

void requireNonEmpty(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ValidationException(
      'validation.empty',
      '$fieldName must be non-empty',
      {'field': fieldName},
    );
  }
}

void requireUtc(DateTime value, String fieldName) {
  if (!value.isUtc) {
    throw ValidationException(
      'validation.not_utc',
      '$fieldName must be UTC',
      {'field': fieldName},
    );
  }
}

void requireIndexInRange(int index, int length, String fieldName) {
  if (index < 0 || index >= length) {
    throw ValidationException(
      'validation.index_out_of_range',
      '$fieldName out of range',
      {'field': fieldName, 'index': index, 'length': length},
    );
  }
}

void requireListNotEmpty<T>(List<T> list, String fieldName) {
  if (list.isEmpty) {
    throw ValidationException(
      'validation.empty_list',
      '$fieldName must not be empty',
      {'field': fieldName},
    );
  }
}