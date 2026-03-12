/// Storage Integrity Tests（Maintenance/Integrity V1.1+）
///
/// 覆盖场景：
///   1. checkIntegrity() 检测 missingFiles
///   2. checkIntegrity() 检测 relativePathViolations
///   3. repair(dryRun) 不修改数据库
///   4. repair(deleteBrokenIndexRows) 删除缺失文件的索引行
library;

import 'dart:io';

import 'package:aiwa_core/fit_storage.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  group('StorageMaintenanceService', () {
    late Directory tempDir;
    late FitStoragePaths paths;
    late FitDatabase db;
    late StorageMaintenanceService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fit_integrity_');
      paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
      db = FitDatabase.openFile(paths.dbFile);
      service = StorageMaintenanceService(db: db, paths: paths);
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('checkIntegrity detects missing files', () async {
      // Create an attachment row pointing to a non-existent file
      final attachmentId = 'missing-attachment';
      await db.into(db.attachments).insert(
            AttachmentsCompanion(
              id: Value<String>(attachmentId),
              mediaType: Value<String>('image'),
              createdAtUtc: Value<String>('2026-01-01T00:00:00.000Z'),
              relativePath: Value<String>('media/objects/xx/nonexistent.jpg'),
              byteSize: Value<int>(0),
            ),
          );

      final report = await service.checkIntegrity();

      expect(report.missingFiles, contains(attachmentId));
    });

    test('checkIntegrity detects relativePath violations', () async {
      // Create an attachment row with invalid relative_path (absolute path)
      final attachmentId = 'invalid-path';
      await db.into(db.attachments).insert(
            AttachmentsCompanion(
              id: Value<String>(attachmentId),
              mediaType: Value<String>('image'),
              createdAtUtc: Value<String>('2026-01-01T00:00:00.000Z'),
              relativePath: Value<String>('/absolute/path/image.jpg'),
              byteSize: Value<int>(0),
            ),
          );

      final report = await service.checkIntegrity();

      expect(report.relativePathViolations, contains(attachmentId));
    });

    test('repair(dryRun) does not modify database', () async {
      // Create an attachment row pointing to a non-existent file
      final attachmentId = 'dry-run-test';
      await db.into(db.attachments).insert(
            AttachmentsCompanion(
              id: Value<String>(attachmentId),
              mediaType: Value<String>('image'),
              createdAtUtc: Value<String>('2026-01-01T00:00:00.000Z'),
              relativePath: Value<String>('media/objects/xx/missing.jpg'),
              byteSize: Value<int>(0),
            ),
          );

      // Verify it exists
      final before = await (db.select(db.attachments)
            ..where((t) => t.id.equals(attachmentId)))
          .getSingleOrNull();
      expect(before, isNotNull);

      // Run dryRun repair
      final repairReport = await service.repair(mode: RepairMode.dryRun);

      expect(repairReport.mode, RepairMode.dryRun);
      expect(repairReport.deletedIndexRows, isEmpty);

      // Verify row still exists
      final after = await (db.select(db.attachments)
            ..where((t) => t.id.equals(attachmentId)))
          .getSingleOrNull();
      expect(after, isNotNull);
    });

    test('repair(deleteBrokenIndexRows) deletes missing file rows', () async {
      // Create an attachment row pointing to a non-existent file
      final attachmentId = 'broken-index';
      await db.into(db.attachments).insert(
            AttachmentsCompanion(
              id: Value<String>(attachmentId),
              mediaType: Value<String>('image'),
              createdAtUtc: Value<String>('2026-01-01T00:00:00.000Z'),
              relativePath: Value<String>('media/objects/xx/missing.jpg'),
              byteSize: Value<int>(0),
            ),
          );

      // Verify it exists
      final before = await (db.select(db.attachments)
            ..where((t) => t.id.equals(attachmentId)))
          .getSingleOrNull();
      expect(before, isNotNull);

      // Run repair
      final repairReport = await service.repair(
        mode: RepairMode.deleteBrokenIndexRows,
      );

      expect(repairReport.mode, RepairMode.deleteBrokenIndexRows);
      expect(repairReport.deletedIndexRows, contains(attachmentId));

      // Verify row is deleted
      final after = await (db.select(db.attachments)
            ..where((t) => t.id.equals(attachmentId)))
          .getSingleOrNull();
      expect(after, isNull);
    });

    test('repair is idempotent', () async {
      // Create an attachment row pointing to a non-existent file
      final attachmentId = 'idempotent-test';
      await db.into(db.attachments).insert(
            AttachmentsCompanion(
              id: Value<String>(attachmentId),
              mediaType: Value<String>('image'),
              createdAtUtc: Value<String>('2026-01-01T00:00:00.000Z'),
              relativePath: Value<String>('media/objects/xx/missing.jpg'),
              byteSize: Value<int>(0),
            ),
          );

      // First repair
      final report1 = await service.repair(
        mode: RepairMode.deleteBrokenIndexRows,
      );
      expect(report1.deletedIndexRows, contains(attachmentId));

      // Second repair (should be no-op)
      final report2 = await service.repair(
        mode: RepairMode.deleteBrokenIndexRows,
      );
      expect(report2.deletedIndexRows, isEmpty);
    });

    test('checkIntegrity returns empty lists when all files exist', () async {
      // Create a valid attachment with actual file
      final attachmentId = 'valid-attachment';
      final testFile = File(p.join(tempDir.path, 'test.jpg'));
      await testFile.writeAsString('test content');

      await db.into(db.attachments).insert(
            AttachmentsCompanion(
              id: Value<String>(attachmentId),
              mediaType: Value<String>('image'),
              createdAtUtc: Value<String>('2026-01-01T00:00:00.000Z'),
              relativePath: Value<String>(
                p.relative(testFile.path, from: paths.rootDir.path)
                    .replaceAll('\\', '/'),
              ),
              byteSize: Value<int>(await testFile.length()),
            ),
          );

      final report = await service.checkIntegrity();

      expect(report.missingFiles, isEmpty);
      expect(report.relativePathViolations, isEmpty);
    });
  });
}
