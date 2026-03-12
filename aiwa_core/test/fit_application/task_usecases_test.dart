import 'dart:convert';

import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

import 'support/fake_clock.dart';
import 'support/fake_unit_of_work.dart';
import 'support/fixed_id_generator.dart';
import 'support/in_memory_repositories.dart';
import 'support/transactional_resource.dart';

void main() {
  group('EnsureTaskActivationUseCase', () {
    test('creates activation once and reuses existing activation', () async {
      final repo = _InMemoryTaskActivationRepository();
      final useCase = EnsureTaskActivationUseCase(
        taskActivationRepository: repo,
        clock: FakeClock(DateTime.utc(2026, 3, 10, 8)),
        idGenerator: FixedIdGenerator(prefix: 'task'),
      );

      final first = await useCase.execute(
        EnsureTaskActivationInput(
          templateId: 'task_tpl_1',
          startDate: DateOnly(2026, 3, 10),
        ),
      );
      final second = await useCase.execute(
        EnsureTaskActivationInput(
          templateId: 'task_tpl_1',
          startDate: DateOnly(2026, 3, 10),
        ),
      );

      expect(first.id, 'task_activation_task-1');
      expect(second.id, first.id);
      expect((await repo.findAll()).length, 1);
    });
  });

  group('DeleteTaskLogUseCase', () {
    test('suppresses occurrence and deletes log atomically', () async {
      final logRepo = InMemoryWorkoutLogRepository();
      final occurrenceRepo = _InMemoryTaskOccurrenceRepository();
      final uow = FakeUnitOfWork(resources: [logRepo, occurrenceRepo]);

      await logRepo.save(
        WorkoutLog(
          id: 'log_1',
          date: DateOnly(2026, 3, 10),
          boundTaskOccurrenceId: 'task_occ_1',
          createdAtUtc: DateTime.utc(2026, 3, 10, 8),
          lastEditedAtUtc: DateTime.utc(2026, 3, 10, 8),
          blocks: const <LogBlock>[],
        ),
      );
      await occurrenceRepo.save(
        TaskOccurrence(
          id: 'task_occ_1',
          date: DateOnly(2026, 3, 10),
          boundLogId: 'log_1',
        ),
      );

      final useCase = DeleteTaskLogUseCase(
        workoutLogRepository: logRepo,
        taskOccurrenceRepository: occurrenceRepo,
        unitOfWork: uow,
      );

      await useCase.execute(
        const DeleteTaskLogInput(
          logId: 'log_1',
          taskOccurrenceId: 'task_occ_1',
        ),
      );

      expect(await logRepo.findById('log_1'), isNull);
      final occurrence = await occurrenceRepo.findById('task_occ_1');
      expect(occurrence, isNotNull);
      expect(occurrence!.suppressed, isTrue);
      expect(occurrence.boundLogId, isNull);
    });

    test('rolls back when occurrence save fails', () async {
      final logRepo = InMemoryWorkoutLogRepository();
      final occurrenceRepo = _InMemoryTaskOccurrenceRepository()
        ..failOnSave = true;
      final uow = FakeUnitOfWork(resources: [logRepo, occurrenceRepo]);

      await logRepo.save(
        WorkoutLog(
          id: 'log_1',
          date: DateOnly(2026, 3, 10),
          boundTaskOccurrenceId: 'task_occ_1',
          createdAtUtc: DateTime.utc(2026, 3, 10, 8),
          lastEditedAtUtc: DateTime.utc(2026, 3, 10, 8),
          blocks: const <LogBlock>[],
        ),
      );
      occurrenceRepo.failOnSave = false;
      await occurrenceRepo.save(
        TaskOccurrence(
          id: 'task_occ_1',
          date: DateOnly(2026, 3, 10),
          boundLogId: 'log_1',
        ),
      );
      occurrenceRepo.failOnSave = true;

      final useCase = DeleteTaskLogUseCase(
        workoutLogRepository: logRepo,
        taskOccurrenceRepository: occurrenceRepo,
        unitOfWork: uow,
      );

      await expectLater(
        () => useCase.execute(
          const DeleteTaskLogInput(
            logId: 'log_1',
            taskOccurrenceId: 'task_occ_1',
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(await logRepo.findById('log_1'), isNotNull);
      final occurrence = await occurrenceRepo.findById('task_occ_1');
      expect(occurrence, isNotNull);
      expect(occurrence!.suppressed, isFalse);
      expect(occurrence.boundLogId, 'log_1');
    });
  });
}

class _InMemoryTaskActivationRepository implements TaskActivationRepository {
  Map<String, Map<String, dynamic>> _store = <String, Map<String, dynamic>>{};

  @override
  Future<void> delete(TaskActivationId id) async {
    _store.remove(id);
  }

  @override
  Future<List<TaskActivation>> findAll() async {
    return _store.values
        .map((raw) => TaskActivation.fromJson(_cloneMap(raw)))
        .toList(growable: false);
  }

  @override
  Future<TaskActivation?> findById(TaskActivationId id) async {
    final raw = _store[id];
    return raw == null ? null : TaskActivation.fromJson(_cloneMap(raw));
  }

  @override
  Future<void> save(TaskActivation activation) async {
    _store[activation.id] = _cloneMap(activation.toJson());
  }
}

class _InMemoryTaskOccurrenceRepository
    implements TaskOccurrenceRepository, TransactionalResource {
  Map<String, Map<String, dynamic>> _store = <String, Map<String, dynamic>>{};
  bool failOnSave = false;

  @override
  Future<TaskOccurrence?> findById(TaskOccurrenceId id) async {
    final raw = _store[id];
    return raw == null ? null : TaskOccurrence.fromJson(_cloneMap(raw));
  }

  @override
  Future<void> save(TaskOccurrence occurrence) async {
    if (failOnSave) {
      throw StateError('task_occurrence_save_failed');
    }
    _store[occurrence.id] = _cloneMap(occurrence.toJson());
  }

  @override
  Object snapshot() => _cloneStore(_store);

  @override
  void restore(Object snapshot) {
    _store = _cloneStore(snapshot as Map<String, Map<String, dynamic>>);
  }
}

Map<String, dynamic> _cloneMap(Map<String, dynamic> value) =>
    (jsonDecode(jsonEncode(value)) as Map<dynamic, dynamic>)
        .cast<String, dynamic>();

Map<String, Map<String, dynamic>> _cloneStore(
  Map<String, Map<String, dynamic>> store,
) {
  return (jsonDecode(jsonEncode(store)) as Map<dynamic, dynamic>).map(
    (key, value) => MapEntry(
      key as String,
      (value as Map<dynamic, dynamic>).cast<String, dynamic>(),
    ),
  );
}
