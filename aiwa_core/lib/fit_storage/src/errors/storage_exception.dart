class StorageException implements Exception {
  static const String dbOpenFailed = 'DB_OPEN_FAILED';
  static const String dbMigrationFailed = 'DB_MIGRATION_FAILED';
  static const String dbJsonCorrupted = 'DB_JSON_CORRUPTED';
  static const String dbConstraintViolation = 'DB_CONSTRAINT_VIOLATION';
  static const String mediaWriteFailed = 'MEDIA_WRITE_FAILED';
  static const String mediaReadFailed = 'MEDIA_READ_FAILED';
  static const String mediaNotFound = 'MEDIA_NOT_FOUND';
  static const String backupExportFailed = 'BACKUP_EXPORT_FAILED';
  static const String backupImportFailed = 'BACKUP_IMPORT_FAILED';
  static const String backupInvalidStructure = 'BACKUP_INVALID_STRUCTURE';
  static const String backupSchemaMismatch = 'BACKUP_SCHEMA_MISMATCH';

  final String errorCode;
  final String message;
  final Map<String, Object?> context;

  const StorageException({
    required this.errorCode,
    required this.message,
    Map<String, Object?>? context,
  }) : context = context ?? const <String, Object?>{};

  @override
  String toString() {
    if (context.isEmpty) {
      return 'StorageException($errorCode): $message';
    }
    return 'StorageException($errorCode): $message context=$context';
  }
}
