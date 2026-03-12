import '../errors/storage_exception.dart';

String encodeUtc(DateTime value, {required String fieldName}) {
  if (!value.isUtc) {
    throw StorageException(
      errorCode: StorageException.dbJsonCorrupted,
      message: 'DateTime is not UTC',
      context: <String, Object?>{'field': fieldName, 'value': value.toString()},
    );
  }
  final encoded = value.toIso8601String();
  if (!encoded.endsWith('Z')) {
    throw StorageException(
      errorCode: StorageException.dbJsonCorrupted,
      message: 'DateTime must be encoded with Z suffix',
      context: <String, Object?>{'field': fieldName, 'value': encoded},
    );
  }
  return encoded;
}

DateTime decodeUtc(String value, {required String fieldName}) {
  try {
    final parsed = DateTime.parse(value);
    if (!parsed.isUtc || !value.endsWith('Z')) {
      throw StorageException(
        errorCode: StorageException.dbJsonCorrupted,
        message: 'Stored DateTime is not UTC with Z suffix',
        context: <String, Object?>{'field': fieldName, 'value': value},
      );
    }
    return parsed.toUtc();
  } on StorageException {
    rethrow;
  } catch (_) {
    throw StorageException(
      errorCode: StorageException.dbJsonCorrupted,
      message: 'Failed to parse stored DateTime',
      context: <String, Object?>{'field': fieldName, 'value': value},
    );
  }
}
