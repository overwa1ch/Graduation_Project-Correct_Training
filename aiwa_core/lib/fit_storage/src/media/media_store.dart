import 'dart:io';
import 'dart:math';

import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../db/fit_database.dart';
import '../db/fit_storage_paths.dart';
import '../errors/storage_exception.dart';
import '../utils/db_error_mapper.dart';
import '../utils/json_codec.dart';
import '../utils/utc_codec.dart';

abstract interface class MediaStore {
  Future<void> importFromFile({
    required String attachmentId,
    required domain.AttachmentMediaType mediaType,
    required DateTime createdAtUtc,
    required File sourceFile,
    required String fileExtension,
    File? thumbnailSourceFile,
    int? byteSize,
    String? sha256,
    Map<String, Object?>? meta,
  });

  Future<File> openObjectFile(String attachmentId);

  Future<File> openThumbnailFile(String attachmentId);

  Future<void> deleteAttachment(String attachmentId);
}

class DriftMediaStore implements MediaStore {
  final FitDatabase db;
  final FitStoragePaths paths;

  const DriftMediaStore({required this.db, required this.paths});

  @override
  Future<void> importFromFile({
    required String attachmentId,
    required domain.AttachmentMediaType mediaType,
    required DateTime createdAtUtc,
    required File sourceFile,
    required String fileExtension,
    File? thumbnailSourceFile,
    int? byteSize,
    String? sha256,
    Map<String, Object?>? meta,
  }) async {
    final shard = _shardFor(attachmentId);
    final extension = fileExtension.startsWith('.')
        ? fileExtension.substring(1)
        : fileExtension;

    final objectFile = File(
      p.join(paths.mediaObjectsDir.path, shard, '$attachmentId.$extension'),
    );
    final objectRelativePath = _relativeToRoot(objectFile);

    final thumbnailFile = thumbnailSourceFile == null
        ? null
        : File(p.join(paths.mediaThumbsDir.path, shard, '$attachmentId.jpg'));
    final thumbnailRelativePath =
        thumbnailFile == null ? null : _relativeToRoot(thumbnailFile);

    _assertRelativePath(objectRelativePath, field: 'relative_path');
    if (thumbnailRelativePath != null) {
      _assertRelativePath(
        thumbnailRelativePath,
        field: 'thumbnail_relative_path',
      );
    }

    var objectExistedBefore = false;
    var objectWritten = false;
    var thumbnailExistedBefore = false;
    var thumbnailWritten = false;

    try {
      await objectFile.parent.create(recursive: true);
      objectExistedBefore = await objectFile.exists();
      await _atomicReplace(sourceFile, objectFile);
      objectWritten = true;

      if (thumbnailSourceFile != null && thumbnailFile != null) {
        await thumbnailFile.parent.create(recursive: true);
        thumbnailExistedBefore = await thumbnailFile.exists();
        await _atomicReplace(thumbnailSourceFile, thumbnailFile);
        thumbnailWritten = true;
      }

      final size = byteSize ?? await sourceFile.length();
      final metaJson = meta == null
          ? null
          : encodeJson(meta, fieldName: 'attachments.meta_json');

      await db.into(db.attachments).insertOnConflictUpdate(
            AttachmentsCompanion(
              id: Value<String>(attachmentId),
              mediaType: Value<String>(mediaType.name),
              createdAtUtc: Value<String>(
                encodeUtc(createdAtUtc, fieldName: 'createdAtUtc'),
              ),
              relativePath: Value<String>(objectRelativePath),
              thumbnailRelativePath: Value<String?>(thumbnailRelativePath),
              byteSize: Value<int>(size),
              sha256: Value<String?>(sha256),
              metaJson: Value<String?>(metaJson),
            ),
          );
    } catch (error) {
      await _cleanupImportedFilesOnFailure(
        objectFile: objectFile,
        thumbnailFile: thumbnailFile,
        objectWritten: objectWritten,
        objectExistedBefore: objectExistedBefore,
        thumbnailWritten: thumbnailWritten,
        thumbnailExistedBefore: thumbnailExistedBefore,
      );

      if (error is StorageException) rethrow;
      if (isConstraintViolation(error)) {
        throw StorageException(
          errorCode: StorageException.dbConstraintViolation,
          message: 'SQLite constraint violation',
          context: <String, Object?>{'table': 'attachments'},
        );
      }
      throw StorageException(
        errorCode: StorageException.mediaWriteFailed,
        message: 'Failed to import media file',
        context: <String, Object?>{'attachmentId': attachmentId},
      );
    }
  }

  @override
  Future<File> openObjectFile(String attachmentId) async {
    final row = await _findAttachment(attachmentId);
    final target = File(p.join(paths.rootDir.path, row.relativePath));
    return _openFileOrThrow(target,
        attachmentId: attachmentId, isThumbnail: false);
  }

  @override
  Future<File> openThumbnailFile(String attachmentId) async {
    final row = await _findAttachment(attachmentId);
    final relative = row.thumbnailRelativePath;
    if (relative == null) {
      throw StorageException(
        errorCode: StorageException.mediaNotFound,
        message: 'Thumbnail path is missing for attachment',
        context: <String, Object?>{'attachmentId': attachmentId},
      );
    }

    final target = File(p.join(paths.rootDir.path, relative));
    return _openFileOrThrow(target,
        attachmentId: attachmentId, isThumbnail: true);
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    final row = await (db.select(db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .getSingleOrNull();
    if (row == null) return;

    final objectFile = File(p.join(paths.rootDir.path, row.relativePath));
    final thumbPath = row.thumbnailRelativePath;
    final thumbnailFile =
        thumbPath == null ? null : File(p.join(paths.rootDir.path, thumbPath));

    try {
      if (await objectFile.exists()) {
        await objectFile.delete();
      }
    } catch (_) {
      throw StorageException(
        errorCode: StorageException.mediaWriteFailed,
        message: 'Failed to delete object file',
        context: <String, Object?>{'attachmentId': attachmentId},
      );
    }

    if (thumbnailFile != null) {
      try {
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      } catch (_) {
        // Best-effort by design.
      }
    }

    await (db.delete(db.attachments)..where((t) => t.id.equals(attachmentId)))
        .go();
  }

  String _relativeToRoot(File file) {
    return p
        .relative(file.path, from: paths.rootDir.path)
        .replaceAll('\\', '/');
  }

  void _assertRelativePath(String value, {required String field}) {
    final hasDriveColon = value.contains(':');
    final startsWithRootSlash = value.startsWith('/') || value.startsWith('\\');
    if (p.isAbsolute(value) || hasDriveColon || startsWithRootSlash) {
      throw StorageException(
        errorCode: StorageException.mediaWriteFailed,
        message: 'Absolute paths are forbidden in attachments table',
        context: <String, Object?>{'field': field, 'value': value},
      );
    }
  }

  String _shardFor(String attachmentId) {
    if (attachmentId.length >= 2) {
      return attachmentId.substring(0, 2).toLowerCase();
    }
    return attachmentId.padRight(2, '_').toLowerCase();
  }

  Future<void> _atomicReplace(File source, File target) async {
    final tempName = '${target.path}.tmp_${Random.secure().nextInt(1 << 31)}';
    final tempFile = File(tempName);
    await source.copy(tempFile.path);

    if (await target.exists()) {
      await target.delete();
    }

    await tempFile.rename(target.path);
  }

  Future<Attachment> _findAttachment(String attachmentId) async {
    final row = await (db.select(db.attachments)
          ..where((t) => t.id.equals(attachmentId)))
        .getSingleOrNull();
    if (row == null) {
      throw StorageException(
        errorCode: StorageException.mediaNotFound,
        message: 'Attachment metadata not found',
        context: <String, Object?>{'attachmentId': attachmentId},
      );
    }

    decodeUtc(row.createdAtUtc, fieldName: 'attachments.created_at_utc');

    return row;
  }

  Future<void> _cleanupImportedFilesOnFailure({
    required File objectFile,
    required bool objectWritten,
    required bool objectExistedBefore,
    required File? thumbnailFile,
    required bool thumbnailWritten,
    required bool thumbnailExistedBefore,
  }) async {
    // Best-effort cleanup to avoid file/index inconsistency when DB write fails.
    if (objectWritten && !objectExistedBefore) {
      try {
        if (await objectFile.exists()) {
          await objectFile.delete();
        }
      } catch (_) {}
    }

    if (thumbnailFile != null && thumbnailWritten && !thumbnailExistedBefore) {
      try {
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      } catch (_) {}
    }
  }

  Future<File> _openFileOrThrow(
    File file, {
    required String attachmentId,
    required bool isThumbnail,
  }) async {
    try {
      if (!await file.exists()) {
        throw StorageException(
          errorCode: StorageException.mediaNotFound,
          message: 'Attachment file not found',
          context: <String, Object?>{
            'attachmentId': attachmentId,
            'thumbnail': isThumbnail,
          },
        );
      }
      return file;
    } on StorageException {
      rethrow;
    } catch (_) {
      throw StorageException(
        errorCode: StorageException.mediaReadFailed,
        message: 'Failed to access attachment file',
        context: <String, Object?>{
          'attachmentId': attachmentId,
          'thumbnail': isThumbnail,
        },
      );
    }
  }
}
