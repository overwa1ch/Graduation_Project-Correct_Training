import 'dart:io';

import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:aiwa_core/fit_storage.dart';
import 'package:test/test.dart';

void main() {
  group('UnitOfWork rollback', () {
    test('DriftUnitOfWork rolls back on exception', () async {
      final tempDir = await Directory.systemTemp.createTemp('fit_storage_uow_');
      final paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
      final db = FitDatabase.openFile(paths.dbFile);
      final uow = DriftUnitOfWork(db);
      final workoutRepo = DriftWorkoutLogRepository(db);
      final tagRepo = DriftTagRepository(db);

      final log = domain.WorkoutLog(
        id: 'log-1',
        date: domain.DateOnly.parse('2025-01-01'),
        createdAtUtc: DateTime.utc(2025, 1, 1, 9),
        lastEditedAtUtc: DateTime.utc(2025, 1, 1, 9),
        blocks: const <domain.LogBlock>[],
      );
      final tag = domain.Tag(id: 'tag-1', name: 'Upper');

      await expectLater(
        () => uow.runInTransaction(() async {
          await workoutRepo.save(log);
          await tagRepo.save(tag);
          throw StateError('force rollback');
        }),
        throwsStateError,
      );

      expect(await workoutRepo.findById(log.id), isNull);
      expect(await tagRepo.findById(tag.id), isNull);

      await db.close();
      await tempDir.delete(recursive: true);
    });

    test('InMemoryUnitOfWork rolls back snapshot resources', () async {
      final resource = _MapResource();
      final uow =
          InMemoryUnitOfWork(resources: <TransactionalResource>[resource]);

      await expectLater(
        () => uow.runInTransaction(() async {
          resource.data['written'] = 1;
          throw StateError('force rollback');
        }),
        throwsStateError,
      );

      expect(resource.data, isEmpty);
    });
  });
}

class _MapResource implements TransactionalResource {
  Map<String, int> data = <String, int>{};

  @override
  Object snapshot() => Map<String, int>.from(data);

  @override
  void restore(Object snapshot) {
    data = Map<String, int>.from(snapshot as Map<String, int>);
  }
}
