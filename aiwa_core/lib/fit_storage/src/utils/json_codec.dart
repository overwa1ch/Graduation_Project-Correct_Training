import 'dart:convert';

import '../errors/storage_exception.dart';

String encodeJson(Map<String, Object?> value, {required String fieldName}) {
  try {
    return jsonEncode(value);
  } catch (_) {
    throw StorageException(
      errorCode: StorageException.dbJsonCorrupted,
      message: 'Failed to encode JSON for storage',
      context: <String, Object?>{'field': fieldName},
    );
  }
}

Map<String, dynamic> decodeJsonObject(
  String value, {
  required String fieldName,
}) {
  try {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON is not an object');
    }
    return decoded;
  } catch (_) {
    throw StorageException(
      errorCode: StorageException.dbJsonCorrupted,
      message: 'Failed to decode JSON from storage',
      context: <String, Object?>{'field': fieldName},
    );
  }
}
