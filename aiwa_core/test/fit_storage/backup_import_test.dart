/// Backup Import Tests（Spec §6）
///
/// 覆盖 5 个必测场景：
///   1️⃣ 正常导入：原数据 + media 可读
///   2️⃣ 结构损坏：缺 manifest → BACKUP_INVALID_STRUCTURE
///   3️⃣ schemaVersion 不匹配 → BACKUP_SCHEMA_MISMATCH
///   4️⃣ 中途失败回滚：原数据库仍可读
///   5️⃣ 空 media 情况：import 成功，media 目录存在
library;

import 'dart:convert';
import 'dart:io';

import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:aiwa_core/fit_storage.dart';
import 'package:archive/archive.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// 创建一个 DriftBackupService 用于导出（带真实 DB + paths）。
DriftBackupService _makeExportService(FitStoragePaths paths, FitDatabase db) =>
    DriftBackupService(
      paths: paths,
      db: db,
      nowUtc: () => DateTime.utc(2026, 1, 1, 10),
    );

/// 保存一个最小 WorkoutLog 到 [db]。
Future<void> _seedLog(FitDatabase db, String id) async {
  final repo = DriftWorkoutLogRepository(db);
  await repo.save(
    domain.WorkoutLog(
      id: id,
      date: domain.DateOnly.parse('2026-01-01'),
      createdAtUtc: DateTime.utc(2026, 1, 1, 9),
      lastEditedAtUtc: DateTime.utc(2026, 1, 1, 9),
      blocks: const <domain.LogBlock>[],
    ),
  );
}

/// 读取 DB 中的 WorkoutLog 数量（直接 SQL，不依赖 repo）。
Future<int> _countLogs(FitDatabase db) async {
  final result = await db
      .customSelect('SELECT COUNT(*) AS c FROM workout_logs')
      .getSingle();
  return result.data['c'] as int;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BackupService.importBackupZip', () {
    late Directory tempDir;
    late FitStoragePaths paths;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fit_backup_import_');
      paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // -----------------------------------------------------------------------
    // 1️⃣ 正常导入
    // -----------------------------------------------------------------------

    test('1: normal import restores data and media (Spec §6-1)', () async {
      // ---- Phase A: 创建原始数据 ----
      final dbA = FitDatabase.openFile(paths.dbFile);
      await _seedLog(dbA, 'log-original');

      // 添加一个 media 文件
      final mediaStore = DriftMediaStore(db: dbA, paths: paths);
      final srcFile =
          File('${tempDir.path}${Platform.pathSeparator}obj.jpg');
      await srcFile.writeAsBytes(<int>[0xFF, 0xD8, 0xFF], flush: true);
      await mediaStore.importFromFile(
        attachmentId: 'ab001',
        mediaType: domain.AttachmentMediaType.image,
        createdAtUtc: DateTime.utc(2026, 1, 1, 10),
        sourceFile: srcFile,
        fileExtension: 'jpg',
      );

      // ---- Phase B: 导出 ----
      final exportDir =
          Directory('${tempDir.path}${Platform.pathSeparator}exports');
      final zipFile = await _makeExportService(paths, dbA).exportBackupZip(
        targetDir: exportDir,
      );
      expect(await zipFile.exists(), isTrue);

      // ---- Phase C: 模拟"清空"（关闭原 DB，删除文件，重建空 DB）----
      await dbA.close();
      if (await paths.dbFile.exists()) await paths.dbFile.delete();
      if (await paths.mediaDir.exists()) {
        await paths.mediaDir.delete(recursive: true);
      }
      await paths.ensureInitialized();
      final dbB = FitDatabase.openFile(paths.dbFile);
      expect(await _countLogs(dbB), 0);

      // ---- Phase D: 导入 ----
      final importService = DriftBackupService(
        paths: paths,
        db: dbB,
        nowUtc: () => DateTime.utc(2026, 1, 1, 12),
      );
      await importService.importBackupZip(
        zipFile,
        mode: ImportMode.overwrite,
      );

      // ---- Phase E: 验证（需重新打开 DB）----
      final dbC = FitDatabase.openFile(paths.dbFile);
      try {
        expect(await _countLogs(dbC), 1,
            reason: 'Imported DB should have the original log');

        // 验证 media 文件存在
        final objFile = File(
          '${paths.mediaObjectsDir.path}${Platform.pathSeparator}ab${Platform.pathSeparator}ab001.jpg',
        );
        expect(
          await objFile.exists(),
          isTrue,
          reason: 'Media object file should be restored after import',
        );
      } finally {
        await dbC.close();
      }
    });

    // -----------------------------------------------------------------------
    // 2️⃣ 结构损坏 — 缺少 manifest.json
    // -----------------------------------------------------------------------

    test('2: missing manifest throws BACKUP_INVALID_STRUCTURE (Spec §6-2)',
        () async {
      // 构造一个缺少 manifest.json 的 zip
      final archive = Archive();
      const dbBytes = <int>[1, 2, 3]; // 不是真正 SQLite，但结构验证只检查存在性
      archive
          .addFile(ArchiveFile('db/fit.sqlite', dbBytes.length, dbBytes));
      _addDirEntry(archive, 'media/objects/');
      _addDirEntry(archive, 'media/thumbs/');
      final zipped = ZipEncoder().encode(archive)!;

      final badZip =
          File('${tempDir.path}${Platform.pathSeparator}bad.zip');
      await badZip.writeAsBytes(zipped, flush: true);

      final db = FitDatabase.openFile(paths.dbFile);
      final service = DriftBackupService(
        paths: paths,
        db: db,
        nowUtc: () => DateTime.utc(2026, 1, 1),
      );

      await expectLater(
        () => service.importBackupZip(badZip, mode: ImportMode.overwrite),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.backupInvalidStructure,
          ),
        ),
      );
      await db.close();
    });

    // -----------------------------------------------------------------------
    // 3️⃣ schemaVersion 不匹配
    // -----------------------------------------------------------------------

    test('3: wrong schemaVersion throws BACKUP_SCHEMA_MISMATCH (Spec §6-3)',
        () async {
      // 构造 manifest schemaVersion = 99
      final manifest = jsonEncode({
        'schemaVersion': 99,
        'exportedAtUtc': '2026-01-01T10:00:00Z',
      });
      final manifestBytes = utf8.encode(manifest);
      const dbBytes = <int>[83, 81, 76]; // dummy

      final archive = Archive();
      archive.addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
      archive.addFile(ArchiveFile('db/fit.sqlite', dbBytes.length, dbBytes));
      _addDirEntry(archive, 'media/objects/');
      _addDirEntry(archive, 'media/thumbs/');
      final zipped = ZipEncoder().encode(archive)!;

      final badZip =
          File('${tempDir.path}${Platform.pathSeparator}bad_schema.zip');
      await badZip.writeAsBytes(zipped, flush: true);

      final db = FitDatabase.openFile(paths.dbFile);
      final service = DriftBackupService(
        paths: paths,
        db: db,
        nowUtc: () => DateTime.utc(2026, 1, 1),
      );

      await expectLater(
        () => service.importBackupZip(badZip, mode: ImportMode.overwrite),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.backupSchemaMismatch,
          ),
        ),
      );
      await db.close();
    });

    // -----------------------------------------------------------------------
    // 4️⃣ 中途失败 → 原数据库仍可读
    // -----------------------------------------------------------------------

    test('4: mid-import failure rolls back original database (Spec §6-4)',
        () async {
      // ---- 创建有数据的 DB ----
      final dbA = FitDatabase.openFile(paths.dbFile);
      await _seedLog(dbA, 'log-kept');

      // ---- 创建有效 zip ----
      final exportDir =
          Directory('${tempDir.path}${Platform.pathSeparator}exports4');
      final zipFile =
          await _makeExportService(paths, dbA).exportBackupZip(
        targetDir: exportDir,
      );

      // ---- 创建带有 testOnlyPreReplaceHook 的服务，令其在 DB copy 前抛异常 ----
      final serviceForImport = DriftBackupService(
        paths: paths,
        db: dbA,
        nowUtc: () => DateTime.utc(2026, 1, 1),
      );
      serviceForImport.testOnlyPreReplaceHook =
          () => throw StateError('simulated_mid_import_failure');

      await expectLater(
        () => serviceForImport.importBackupZip(
          zipFile,
          mode: ImportMode.overwrite,
        ),
        throwsA(isA<StorageException>().having(
          (e) => e.errorCode,
          'errorCode',
          StorageException.backupImportFailed,
        )),
      );

      // ---- 验证：原 DB 文件已还原，数据完整 ----
      expect(await paths.dbFile.exists(), isTrue,
          reason: 'Original DB file must still exist after rollback');

      final dbCheck = FitDatabase.openFile(paths.dbFile);
      try {
        expect(await _countLogs(dbCheck), 1,
            reason: 'Original log should still be present after rollback');
      } finally {
        await dbCheck.close();
      }
    });

    // -----------------------------------------------------------------------
    // 5️⃣ 空 media → import 成功，media 目录存在
    // -----------------------------------------------------------------------

    test('5: empty media import succeeds and media dirs are present (Spec §6-5)',
        () async {
      // ---- 创建有数据但无 media 的原始 DB ----
      final dbA = FitDatabase.openFile(paths.dbFile);
      await _seedLog(dbA, 'log-nomedia');

      // 导出（no media files）
      final exportDir =
          Directory('${tempDir.path}${Platform.pathSeparator}exports5');
      final zipFile =
          await _makeExportService(paths, dbA).exportBackupZip(
        targetDir: exportDir,
      );
      await dbA.close();

      // ---- 清空现有数据 ----
      if (await paths.dbFile.exists()) await paths.dbFile.delete();
      if (await paths.mediaDir.exists()) {
        await paths.mediaDir.delete(recursive: true);
      }
      await paths.ensureInitialized();

      // ---- 导入 ----
      final dbB = FitDatabase.openFile(paths.dbFile);
      final service = DriftBackupService(
        paths: paths,
        db: dbB,
        nowUtc: () => DateTime.utc(2026, 1, 1, 12),
      );
      await service.importBackupZip(zipFile, mode: ImportMode.overwrite);

      // ---- 验证 ----
      final dbC = FitDatabase.openFile(paths.dbFile);
      try {
        expect(await _countLogs(dbC), 1,
            reason: 'Log should be present in imported DB');

        expect(await paths.mediaObjectsDir.exists(), isTrue,
            reason: 'media/objects/ directory must exist even if empty');
        expect(await paths.mediaThumbsDir.exists(), isTrue,
            reason: 'media/thumbs/ directory must exist even if empty');
      } finally {
        await dbC.close();
      }
    });
  });
}

void _addDirEntry(Archive archive, String path) {
  final entry = ArchiveFile(path, 0, <int>[]);
  entry.isFile = false;
  archive.addFile(entry);
}
