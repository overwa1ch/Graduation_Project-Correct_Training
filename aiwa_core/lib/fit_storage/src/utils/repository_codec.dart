import '../errors/storage_exception.dart';
import 'db_error_mapper.dart';
import 'json_codec.dart';

Map<String, Object?> encodeDomainJson(Map<String, dynamic> value) {
  return value.map<String, Object?>((String key, dynamic data) {
    return MapEntry<String, Object?>(key, data as Object?);
  });
}

T decodeDomainJson<T>(
  String raw,
  T Function(Map<String, dynamic> value) decoder, {
  required String entity,
}) {
  try {
    final json = decodeJsonObject(raw, fieldName: '$entity.json');
    return decoder(json);
  } catch (error) {
    if (error is StorageException &&
        error.errorCode == StorageException.dbJsonCorrupted) {
      rethrow;
    }
    throw StorageException(
      errorCode: StorageException.dbJsonCorrupted,
      message: 'Failed to deserialize $entity JSON payload',
      context: <String, Object?>{'entity': entity},
    );
  }
}

Never throwIfConstraint(Object error, {Map<String, Object?>? context}) {
  if (isConstraintViolation(error)) {
    throw StorageException(
      errorCode: StorageException.dbConstraintViolation,
      message: 'SQLite constraint violation',
      context: context,
    );
  }
  throw error;
}
