import 'dart:convert';
import 'dart:io';

import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:aiwa_core/fit_storage.dart';
import 'package:archive/archive.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

void main() {
  group('MediaStore and BackupService', () {
    late Directory tempDir;
    late FitStoragePaths paths;
    late FitDatabase db;
    late DriftMediaStore mediaStore;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fit_storage_media_');
      paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
      db = FitDatabase.openFile(paths.dbFile);
      mediaStore = DriftMediaStore(db: db, paths: paths);
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('MediaStore import/open/delete and MEDIA_NOT_FOUND', () async {
      final source = File('${tempDir.path}${Platform.pathSeparator}source.jpg');
      await source.writeAsBytes(<int>[1, 2, 3, 4], flush: true);
      final thumb = File('${tempDir.path}${Platform.pathSeparator}thumb.jpg');
      await thumb.writeAsBytes(<int>[9, 8, 7], flush: true);

      await mediaStore.importFromFile(
        attachmentId: 'ab123',
        mediaType: domain.AttachmentMediaType.image,
        createdAtUtc: DateTime.utc(2025, 1, 1, 12),
        sourceFile: source,
        fileExtension: 'jpg',
        thumbnailSourceFile: thumb,
      );

      final attachmentRow = await db.customSelect(
        'SELECT relative_path, created_at_utc FROM attachments WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>('ab123')],
      ).getSingle();
      final relativePath = attachmentRow.data['relative_path'] as String;
      expect(relativePath.contains(':'), isFalse);
      expect(relativePath.startsWith('/'), isFalse);
      expect(relativePath.startsWith('\\'), isFalse);
      expect((attachmentRow.data['created_at_utc'] as String).endsWith('Z'),
          isTrue);

      final objectFile = await mediaStore.openObjectFile('ab123');
      expect(await objectFile.exists(), isTrue);
      expect(
        objectFile.path
            .replaceAll('\\', '/')
            .contains('media/objects/ab/ab123.jpg'),
        isTrue,
      );

      final thumbnailFile = await mediaStore.openThumbnailFile('ab123');
      expect(await thumbnailFile.exists(), isTrue);
      expect(
        thumbnailFile.path
            .replaceAll('\\', '/')
            .contains('media/thumbs/ab/ab123.jpg'),
        isTrue,
      );

      await mediaStore.deleteAttachment('ab123');

      await expectLater(
        () => mediaStore.openObjectFile('ab123'),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.mediaNotFound,
          ),
        ),
      );

      await expectLater(
        () => mediaStore.openObjectFile('missing'),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.mediaNotFound,
          ),
        ),
      );
    });

    test('Backup export zip contains manifest/db/media entries', () async {
      final source = File('${tempDir.path}${Platform.pathSeparator}obj.jpg');
      await source.writeAsBytes(<int>[1, 2, 3], flush: true);
      final thumb =
          File('${tempDir.path}${Platform.pathSeparator}obj_thumb.jpg');
      await thumb.writeAsBytes(<int>[4, 5], flush: true);

      await mediaStore.importFromFile(
        attachmentId: 'ab001',
        mediaType: domain.AttachmentMediaType.image,
        createdAtUtc: DateTime.utc(2025, 1, 2, 9),
        sourceFile: source,
        fileExtension: 'jpg',
        thumbnailSourceFile: thumb,
      );

      final workoutRepo = DriftWorkoutLogRepository(db);
      await workoutRepo.save(
        domain.WorkoutLog(
          id: 'log-1',
          date: domain.DateOnly.parse('2025-01-02'),
          createdAtUtc: DateTime.utc(2025, 1, 2, 9),
          lastEditedAtUtc: DateTime.utc(2025, 1, 2, 9),
          blocks: const <domain.LogBlock>[],
        ),
      );

      final backupService = DriftBackupService(
        paths: paths,
        db: db,
        nowUtc: () => DateTime.utc(2025, 1, 3, 10, 30),
      );

      final exportDir =
          Directory('${tempDir.path}${Platform.pathSeparator}exports');
      final zipFile = await backupService.exportBackupZip(
        targetDir: exportDir,
        appBuild: '1.0.0',
        note: 'test',
      );

      expect(await zipFile.exists(), isTrue);

      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      final names = archive.files.map((e) => e.name).toSet();

      expect(names, contains('manifest.json'));
      expect(names, contains('db/fit.sqlite'));
      expect(names, contains('media/objects/'));
      expect(names, contains('media/thumbs/'));
      expect(names, contains('media/objects/ab/ab001.jpg'));
      expect(names, contains('media/thumbs/ab/ab001.jpg'));

      final manifestFile = archive.findFile('manifest.json');
      expect(manifestFile, isNotNull);
      final manifest = jsonDecode(
        utf8.decode((manifestFile!.content as List<int>)),
      ) as Map<String, dynamic>;

      expect(manifest['schemaVersion'], 3);
      expect((manifest['exportedAtUtc'] as String).endsWith('Z'), isTrue);
    });

    test('Backup export keeps media directories when media is empty', () async {
      final workoutRepo = DriftWorkoutLogRepository(db);
      await workoutRepo.save(
        domain.WorkoutLog(
          id: 'log-empty',
          date: domain.DateOnly.parse('2025-02-01'),
          createdAtUtc: DateTime.utc(2025, 2, 1, 12),
          lastEditedAtUtc: DateTime.utc(2025, 2, 1, 12),
          blocks: const <domain.LogBlock>[],
        ),
      );

      final backupService = DriftBackupService(
        paths: paths,
        db: db,
        nowUtc: () => DateTime.utc(2025, 2, 1, 12, 0),
      );

      final exportDir =
          Directory('${tempDir.path}${Platform.pathSeparator}exports_empty');
      final zipFile = await backupService.exportBackupZip(
        targetDir: exportDir,
      );

      expect(await zipFile.exists(), isTrue);
      final archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());
      final names = archive.files.map((e) => e.name).toSet();

      expect(names, contains('manifest.json'));
      expect(names, contains('db/fit.sqlite'));
      expect(names, contains('media/objects/'));
      expect(names, contains('media/thumbs/'));
    });

    test('Attachment created_at_utc stored with Z and validated on read',
        () async {
      final source = File('${tempDir.path}${Platform.pathSeparator}utc.jpg');
      await source.writeAsBytes(<int>[1, 3, 5], flush: true);

      await mediaStore.importFromFile(
        attachmentId: 'ab900',
        mediaType: domain.AttachmentMediaType.image,
        createdAtUtc: DateTime.utc(2025, 1, 4, 11, 20),
        sourceFile: source,
        fileExtension: 'jpg',
      );

      final row = await db.customSelect(
        'SELECT created_at_utc FROM attachments WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>('ab900')],
      ).getSingle();
      expect((row.data['created_at_utc'] as String).endsWith('Z'), isTrue);

      await db.customStatement(
        "UPDATE attachments SET created_at_utc = '2025-01-04T11:20:00' WHERE id = 'ab900'",
      );

      await expectLater(
        () => mediaStore.openObjectFile('ab900'),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.dbJsonCorrupted,
          ),
        ),
      );
    });

    test('importFromFile cleans up written files if index write fails',
        () async {
      final source =
          File('${tempDir.path}${Platform.pathSeparator}cleanup.jpg');
      await source.writeAsBytes(<int>[1, 2, 9], flush: true);

      await expectLater(
        () => mediaStore.importFromFile(
          attachmentId: 'ab777',
          mediaType: domain.AttachmentMediaType.image,
          createdAtUtc: DateTime.utc(2025, 1, 5, 10),
          sourceFile: source,
          fileExtension: 'jpg',
          // jsonEncode cannot serialize raw Object().
          meta: <String, Object?>{'bad': Object()},
        ),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.dbJsonCorrupted,
          ),
        ),
      );

      final objectPath = File(
        '${paths.mediaObjectsDir.path}${Platform.pathSeparator}ab${Platform.pathSeparator}ab777.jpg',
      );
      expect(await objectPath.exists(), isFalse);

      final countRow = await db.customSelect(
        'SELECT COUNT(*) AS c FROM attachments WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>('ab777')],
      ).getSingle();
      expect(countRow.data['c'], 0);
    });
  });
}
