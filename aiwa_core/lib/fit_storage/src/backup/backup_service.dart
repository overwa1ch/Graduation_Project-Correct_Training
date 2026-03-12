import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import '../db/fit_database.dart';
import '../db/fit_storage_paths.dart';
import '../errors/storage_exception.dart';
import '../utils/utc_codec.dart';

// ---------------------------------------------------------------------------
// Public contracts
// ---------------------------------------------------------------------------

enum ImportMode {
  /// 覆盖式恢复：将备份数据完整替换当前数据。
  overwrite,
}

abstract interface class BackupService {
  /// 导出备份 zip。
  Future<File> exportBackupZip({
    required Directory targetDir,
    String? fileName,
    String? appBuild,
    String? note,
  });

  /// 从备份 zip 恢复（Spec §3）。
  ///
  /// 成功时：
  ///   - 当前 DB 连接已关闭（调用方需重新打开）
  ///   - `paths.dbFile` 已替换为 zip 中的 db
  ///   - `paths.mediaDir` 已替换为 zip 中的 media
  ///
  /// 失败时：
  ///   - 原 DB 文件已还原（不丢数据）
  ///   - 抛出 [StorageException]
  Future<void> importBackupZip(
    File zipFile, {
    required ImportMode mode,
  });
}

// ---------------------------------------------------------------------------
// DriftBackupService
// ---------------------------------------------------------------------------

class DriftBackupService implements BackupService {
  final FitStoragePaths paths;
  final FitDatabase db;
  final DateTime Function() nowUtc;

  /// 仅供测试：在 DB 文件拷贝之前注入失败钩子，以模拟中途异常。
  @visibleForTesting
  void Function()? testOnlyPreReplaceHook;

  DriftBackupService({
    required this.paths,
    required this.db,
    required this.nowUtc,
  });

  // =========================================================================
  // Export
  // =========================================================================

  @override
  Future<File> exportBackupZip({
    required Directory targetDir,
    String? fileName,
    String? appBuild,
    String? note,
  }) async {
    final now = nowUtc();
    final exportedAtUtc = encodeUtc(now, fieldName: 'exportedAtUtc');

    final name = fileName == null || fileName.isEmpty ? 'backup.zip' : fileName;
    final outFile = File('${targetDir.path}${Platform.pathSeparator}$name');
    File? snapshotDbFile;

    try {
      await targetDir.create(recursive: true);

      final archive = Archive();
      final manifest = <String, Object?>{
        'schemaVersion': db.schemaVersion,
        'exportedAtUtc': exportedAtUtc,
      };
      if (appBuild != null && appBuild.isNotEmpty) {
        manifest['appBuild'] = appBuild;
      }
      if (note != null && note.isNotEmpty) {
        manifest['note'] = note;
      }

      final manifestBytes = utf8.encode(jsonEncode(manifest));
      archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );

      if (!await paths.dbFile.exists()) {
        throw StorageException(
          errorCode: StorageException.backupExportFailed,
          message: 'fit.sqlite not found',
          context: <String, Object?>{'path': paths.dbFile.path},
        );
      }

      // Export from a consistent snapshot to avoid WAL / partial-state issues.
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      snapshotDbFile = File(
        p.join(
          targetDir.path,
          '.fit_backup_snapshot_${Random.secure().nextInt(1 << 31)}.sqlite',
        ),
      );
      final escapedSnapshotPath = snapshotDbFile.path.replaceAll("'", "''");
      await db.customStatement("VACUUM INTO '$escapedSnapshotPath'");
      if (!await snapshotDbFile.exists()) {
        throw StorageException(
          errorCode: StorageException.backupExportFailed,
          message: 'Failed to build database snapshot for backup',
        );
      }

      final dbBytes = await snapshotDbFile.readAsBytes();
      archive.addFile(ArchiveFile('db/fit.sqlite', dbBytes.length, dbBytes));

      await _appendDirectory(
        archive,
        paths.mediaObjectsDir,
        'media/objects',
      );
      await _appendDirectory(archive, paths.mediaThumbsDir, 'media/thumbs');

      final zipped = ZipEncoder().encode(archive);
      if (zipped == null) {
        throw const StorageException(
          errorCode: StorageException.backupExportFailed,
          message: 'Failed to encode backup zip',
        );
      }

      await outFile.writeAsBytes(zipped, flush: true);
      return outFile;
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        errorCode: StorageException.backupExportFailed,
        message: 'Failed to export backup zip',
        context: <String, Object?>{'error': error.toString()},
      );
    } finally {
      if (snapshotDbFile != null && await snapshotDbFile.exists()) {
        try {
          await snapshotDbFile.delete();
        } catch (_) {
          // Best-effort cleanup of temporary snapshot file.
        }
      }
    }
  }

  // =========================================================================
  // Import（Spec §4）
  // =========================================================================

  @override
  Future<void> importBackupZip(
    File zipFile, {
    required ImportMode mode,
  }) async {
    // ------------------------------------------------------------------
    // Step 0: 预校验 zip 文件存在（Spec §4 Step 0）
    // ------------------------------------------------------------------
    if (!await zipFile.exists()) {
      throw StorageException(
        errorCode: StorageException.backupImportFailed,
        message: 'Backup zip file does not exist',
        context: <String, Object?>{'path': zipFile.path},
      );
    }

    // ------------------------------------------------------------------
    // Step 1: 解压到独立临时目录（Spec §4 Step 1）
    // ------------------------------------------------------------------
    final tmpDir = Directory(
      p.join(
        paths.rootDir.path,
        'tmp_import_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );

    try {
      await tmpDir.create(recursive: true);

      // 解压
      final zipBytes = await zipFile.readAsBytes();
      Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(zipBytes);
      } catch (e) {
        throw StorageException(
          errorCode: StorageException.backupInvalidStructure,
          message: 'Failed to decode backup zip',
          context: <String, Object?>{'error': e.toString()},
        );
      }

      for (final entry in archive.files) {
        // Normalize path separators for the current OS
        final localRelPath = entry.name.replaceAll('/', Platform.pathSeparator);
        final fullPath = p.join(tmpDir.path, localRelPath);
        if (entry.isFile) {
          final outFile = File(fullPath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(entry.content as List<int>, flush: true);
        }
      }

      // ------------------------------------------------------------------
      // Step 2: 校验结构（Spec §4 Step 2）
      // ------------------------------------------------------------------
      final tmpManifest = File(p.join(tmpDir.path, 'manifest.json'));
      final tmpDb = File(p.join(tmpDir.path, 'db', 'fit.sqlite'));

      if (!await tmpManifest.exists() || !await tmpDb.exists()) {
        throw StorageException(
          errorCode: StorageException.backupInvalidStructure,
          message:
              'Backup is missing required files (manifest.json or db/fit.sqlite)',
        );
      }

      // media/objects and media/thumbs 允许为空，确保目录存在即可
      final tmpMediaObjects =
          Directory(p.join(tmpDir.path, 'media', 'objects'));
      final tmpMediaThumbs = Directory(p.join(tmpDir.path, 'media', 'thumbs'));
      await tmpMediaObjects.create(recursive: true);
      await tmpMediaThumbs.create(recursive: true);

      // ------------------------------------------------------------------
      // Step 3: 解析 manifest 并校验 schemaVersion（Spec §4 Step 3）
      // ------------------------------------------------------------------
      Map<String, dynamic> manifest;
      try {
        final content = await tmpManifest.readAsString();
        manifest = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        throw StorageException(
          errorCode: StorageException.backupInvalidStructure,
          message: 'Failed to parse manifest.json',
          context: <String, Object?>{'error': e.toString()},
        );
      }

      final manifestSchemaVersion = manifest['schemaVersion'];
      if (manifestSchemaVersion is! int ||
          manifestSchemaVersion != db.schemaVersion) {
        throw StorageException(
          errorCode: StorageException.backupSchemaMismatch,
          message: 'Backup schemaVersion does not match current schema',
          context: <String, Object?>{
            'expected': db.schemaVersion,
            'got': manifestSchemaVersion,
          },
        );
      }

      // ------------------------------------------------------------------
      // Step 4: 一致性替换（Spec §4 Step 4）
      //
      // 必须先关闭 DB 连接，否则 Windows 下文件被锁定无法操作。
      // ------------------------------------------------------------------
      await db.close();

      File? bakFile;
      bool newDbWritten = false;

      try {
        // 4a. 将当前 db 重命名为 .bak
        if (await paths.dbFile.exists()) {
          final bakPath =
              '${paths.dbFile.path}.bak_${DateTime.now().millisecondsSinceEpoch}';
          bakFile = await paths.dbFile.rename(bakPath);
        }

        // 测试钩子：在 DB 拷贝之前注入失败（Spec §4 Step 5 回滚验证）
        testOnlyPreReplaceHook?.call();

        // 4b. 拷贝新 db 文件到正式路径
        await paths.dbFile.parent.create(recursive: true);
        await tmpDb.copy(paths.dbFile.path);
        newDbWritten = true;

        // 4c. 替换 media 目录
        if (await paths.mediaDir.exists()) {
          await paths.mediaDir.delete(recursive: true);
        }
        final tmpMedia = Directory(p.join(tmpDir.path, 'media'));
        await _moveDirectory(tmpMedia, paths.mediaDir);

        // 4d. 成功：删除 .bak
        if (bakFile != null && await bakFile.exists()) {
          try {
            await bakFile.delete();
          } catch (_) {
            // best-effort，不影响结果
          }
        }
      } catch (replaceError) {
        // ------------------------------------------------------------------
        // Step 5: 回滚（Spec §4 Step 5）
        // ------------------------------------------------------------------
        try {
          if (newDbWritten && await paths.dbFile.exists()) {
            await paths.dbFile.delete();
          }
          if (bakFile != null && await bakFile.exists()) {
            await bakFile.rename(paths.dbFile.path);
          }
        } catch (_) {
          // best-effort
        }

        if (replaceError is StorageException) rethrow;
        throw StorageException(
          errorCode: StorageException.backupImportFailed,
          message: 'Atomic replacement failed; original database restored',
          context: <String, Object?>{'error': replaceError.toString()},
        );
      }
    } on StorageException {
      rethrow;
    } catch (e) {
      throw StorageException(
        errorCode: StorageException.backupImportFailed,
        message: 'Import failed unexpectedly',
        context: <String, Object?>{'error': e.toString()},
      );
    } finally {
      // 始终清理临时目录
      try {
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      } catch (_) {
        // best-effort
      }
    }
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  /// 跨卷移动目录：先尝试 rename，若跨卷则 copy + delete。
  Future<void> _moveDirectory(Directory src, Directory dst) async {
    try {
      await src.rename(dst.path);
    } on FileSystemException {
      // rename 跨卷失败时退回 copy + delete
      await _copyDirectory(src, dst);
      await src.delete(recursive: true);
    }
  }

  Future<void> _copyDirectory(Directory src, Directory dst) async {
    await dst.create(recursive: true);
    await for (final entity in src.list(recursive: false)) {
      if (entity is File) {
        final relativePath =
            entity.path.substring(src.path.length + 1);
        final target = File(p.join(dst.path, relativePath));
        await target.parent.create(recursive: true);
        await entity.copy(target.path);
      } else if (entity is Directory) {
        final relativePath =
            entity.path.substring(src.path.length + 1);
        await _copyDirectory(entity, Directory(p.join(dst.path, relativePath)));
      }
    }
  }

  Future<void> _appendDirectory(
    Archive archive,
    Directory directory,
    String zipRoot,
  ) async {
    _addDirectoryEntry(archive, zipRoot);

    if (!await directory.exists()) {
      return;
    }

    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relativePath = entity.path
          .substring(directory.path.length)
          .replaceAll('\\', '/')
          .replaceFirst(RegExp('^/+'), '');
      final zipPath = '$zipRoot/$relativePath';
      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
    }
  }

  void _addDirectoryEntry(Archive archive, String zipRoot) {
    final normalized = zipRoot.endsWith('/') ? zipRoot : '$zipRoot/';
    final dirEntry = ArchiveFile(normalized, 0, <int>[]);
    dirEntry.isFile = false;
    archive.addFile(dirEntry);
  }
}
