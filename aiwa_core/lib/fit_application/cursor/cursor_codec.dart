import 'dart:convert';

import '../services/application_exception.dart';
import '../services/error_codes.dart';
import 'cursor_models.dart';

class CursorCodec {
  static const int _version = 1;

  static String encode(String h, Map<String, dynamic> k) {
    final payload = <String, dynamic>{'v': _version, 'h': h, 'k': k};
    final jsonStr = jsonEncode(payload);
    return base64Url.encode(utf8.encode(jsonStr)).replaceAll('=', '');
  }

  static Map<String, dynamic> _decodeRaw(
    String cursor,
    String expectedNamespace,
  ) {
    late Map<String, dynamic> payload;
    try {
      final padded = _addPadding(cursor);
      final jsonStr = utf8.decode(base64Url.decode(padded));
      payload = (jsonDecode(jsonStr) as Map<dynamic, dynamic>)
          .cast<String, dynamic>();
    } catch (_) {
      throw const ApplicationException(
        AppErrorCodes.invalidCursor,
        'Cursor decode failed',
      );
    }

    final v = payload['v'];
    if (v is! int || v != _version) {
      throw ApplicationException(
        AppErrorCodes.invalidCursorVersion,
        'Unsupported cursor version: $v',
      );
    }

    final h = payload['h'];
    if (h != expectedNamespace) {
      throw ApplicationException(
        AppErrorCodes.cursorMismatch,
        'Cursor namespace mismatch: expected $expectedNamespace, got $h',
      );
    }

    final k = payload['k'];
    if (k is! Map) {
      throw const ApplicationException(
        AppErrorCodes.invalidCursor,
        'Cursor key missing or not an object',
      );
    }

    return k.cast<String, dynamic>();
  }

  static String encodeWorkoutLog(WorkoutLogCursorKey key) =>
      encode(WorkoutLogCursorKey.namespace, key.toJson());

  static WorkoutLogCursorKey decodeWorkoutLog(String cursor) {
    final k = _decodeRaw(cursor, WorkoutLogCursorKey.namespace);
    try {
      return WorkoutLogCursorKey.fromJson(k);
    } catch (_) {
      throw const ApplicationException(
        AppErrorCodes.invalidCursor,
        'WorkoutLog cursor key fields invalid',
      );
    }
  }

  static String encodeMilestone(MilestoneCursorKey key) =>
      encode(MilestoneCursorKey.namespace, key.toJson());

  static MilestoneCursorKey decodeMilestone(String cursor) {
    final k = _decodeRaw(cursor, MilestoneCursorKey.namespace);
    try {
      return MilestoneCursorKey.fromJson(k);
    } catch (_) {
      throw const ApplicationException(
        AppErrorCodes.invalidCursor,
        'Milestone cursor key fields invalid',
      );
    }
  }

  static String encodeExerciseCatalog(ExerciseCatalogCursorKey key) =>
      encode(ExerciseCatalogCursorKey.namespace, key.toJson());

  static ExerciseCatalogCursorKey decodeExerciseCatalog(String cursor) {
    final k = _decodeRaw(cursor, ExerciseCatalogCursorKey.namespace);
    try {
      return ExerciseCatalogCursorKey.fromJson(k);
    } catch (_) {
      throw const ApplicationException(
        AppErrorCodes.invalidCursor,
        'ExerciseCatalog cursor key fields invalid',
      );
    }
  }

  static String encodeTagCatalog(TagCatalogCursorKey key) =>
      encode(TagCatalogCursorKey.namespace, key.toJson());

  static TagCatalogCursorKey decodeTagCatalog(String cursor) {
    final k = _decodeRaw(cursor, TagCatalogCursorKey.namespace);
    try {
      return TagCatalogCursorKey.fromJson(k);
    } catch (_) {
      throw const ApplicationException(
        AppErrorCodes.invalidCursor,
        'TagCatalog cursor key fields invalid',
      );
    }
  }

  static String _addPadding(String base64url) {
    final rem = base64url.length % 4;
    return rem == 0 ? base64url : base64url + '=' * (4 - rem);
  }
}
