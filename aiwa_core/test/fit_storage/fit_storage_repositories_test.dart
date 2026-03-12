import 'dart:io';

import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:aiwa_core/fit_storage.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:test/test.dart';

void main() {
  group('FitStorage schema and repositories', () {
    late Directory tempDir;
    late FitStoragePaths paths;
    late FitDatabase db;

    late DriftWorkoutLogRepository workoutRepo;
    late DriftExerciseRepository exerciseRepo;
    late DriftTagRepository tagRepo;
    late DriftTaskTemplateRepository taskTemplateRepo;
    late DriftTaskActivationRepository taskActivationRepo;
    late DriftTaskOccurrenceRepository taskOccurrenceRepo;
    late DriftMilestoneRepository milestoneRepo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fit_storage_repo_');
      paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
      db = FitDatabase.openFile(paths.dbFile);
      await db.customSelect('SELECT 1').get();

      workoutRepo = DriftWorkoutLogRepository(db);
      exerciseRepo = DriftExerciseRepository(db);
      tagRepo = DriftTagRepository(db);
      taskTemplateRepo = DriftTaskTemplateRepository(db);
      taskActivationRepo = DriftTaskActivationRepository(db);
      taskOccurrenceRepo = DriftTaskOccurrenceRepository(db);
      milestoneRepo = DriftMilestoneRepository(db);
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('schemaVersion=3 and required tables exist', () async {
      expect(db.schemaVersion, 3);
      final rows = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final names = rows.map((r) => r.data['name'] as String).toSet();

      expect(
        names,
        containsAll(<String>{
          'workout_logs',
          'exercises',
          'tags',
          'task_templates',
          'task_activations',
          'task_occurrences',
          'milestones',
          'attachments',
        }),
      );
      expect(names, isNot(contains('plan_templates')));
      expect(names, isNot(contains('plan_instances')));
      expect(names, isNot(contains('plan_entries')));
    });

    test('repository JSON round-trip save -> load', () async {
      final log = _log(
        id: 'log-1',
        date: '2025-01-01',
        createdAtUtc: DateTime.utc(2025, 1, 1, 8),
        lastEditedAtUtc: DateTime.utc(2025, 1, 1, 9),
        metadata: <String, dynamic>{
          'actionProgressions': <Map<String, dynamic>>[
            <String, dynamic>{
              'exerciseId': 'ex-1',
              'targetWeightKg': 100,
              'openingPercent': 65,
              'endingPercent': 95,
              'incrementWeightKg': 2.5,
            },
          ],
        },
      );
      await workoutRepo.save(log);
      final loadedLog = await workoutRepo.findById(log.id);
      expect(loadedLog, isNotNull);
      expect(loadedLog!.toJson(), log.toJson());

      final exercise = domain.Exercise(
        id: 'ex-1',
        name: 'Bench Press',
        tagIds: <String>['tag-1'],
      );
      await exerciseRepo.save(exercise);
      final loadedExercise = await exerciseRepo.findById(exercise.id);
      expect(loadedExercise, isNotNull);
      expect(loadedExercise!.toJson(), exercise.toJson());

      final tag = domain.Tag(id: 'tag-1', name: 'Upper Body');
      await tagRepo.save(tag);
      final loadedTag = await tagRepo.findById(tag.id);
      expect(loadedTag, isNotNull);
      expect(loadedTag!.toJson(), tag.toJson());

      final template = _template();
      await taskTemplateRepo.save(template);
      final loadedTemplate = await taskTemplateRepo.findById(template.id);
      expect(loadedTemplate, isNotNull);
      expect(loadedTemplate!.toJson(), template.toJson());

      final activation = _activation(templateId: template.id);
      await taskActivationRepo.save(activation);
      final loadedActivation = await taskActivationRepo.findById(activation.id);
      expect(loadedActivation, isNotNull);
      expect(loadedActivation!.toJson(), activation.toJson());

      final occurrenceUpdate =
          activation.occurrences.first.copyWith(boundLogId: log.id);
      await taskOccurrenceRepo.save(occurrenceUpdate);
      final loadedOccurrence =
          await taskOccurrenceRepo.findById(occurrenceUpdate.id);
      expect(loadedOccurrence, isNotNull);
      expect(loadedOccurrence!.toJson(), occurrenceUpdate.toJson());

      final milestone = domain.MilestoneEvent.pr(
        id: 'ms-1',
        exerciseId: 'ex-1',
        logId: log.id,
        metricValue: 100,
        createdAtUtc: DateTime.utc(2025, 1, 1, 10),
      );
      await milestoneRepo.save(milestone);
      final loadedMilestone =
          await milestoneRepo.findByDedupKey(milestone.dedupKey);
      expect(loadedMilestone, isNotNull);
      expect(loadedMilestone!.toJson(), milestone.toJson());
    });

    test('UTC columns are stored as ISO8601 with Z suffix', () async {
      final log = _log(
        id: 'log-z',
        date: '2025-02-01',
        createdAtUtc: DateTime.utc(2025, 2, 1, 8, 30),
        lastEditedAtUtc: DateTime.utc(2025, 2, 1, 9, 45),
      );
      await workoutRepo.save(log);

      final activation = domain.TaskActivation(
        id: 'activation-z',
        templateId: 'tpl-z',
        startDate: domain.DateOnly.parse('2025-02-01'),
        createdAtUtc: DateTime.utc(2025, 2, 1, 7, 15),
        occurrences: <domain.TaskOccurrence>[
          domain.TaskOccurrence(
            id: 'task-occ-z-1',
            date: domain.DateOnly.parse('2025-02-01'),
          ),
        ],
      );
      await taskActivationRepo.save(activation);

      final milestone = domain.MilestoneEvent.pr(
        id: 'ms-z',
        exerciseId: 'ex-z',
        logId: 'log-z',
        metricValue: 110,
        createdAtUtc: DateTime.utc(2025, 2, 1, 10, 0),
      );
      await milestoneRepo.save(milestone);

      final deletedMilestone = domain.MilestoneEvent.pr(
        id: 'ms-z-del',
        exerciseId: 'ex-z-del',
        logId: 'log-z',
        metricValue: 90,
        createdAtUtc: DateTime.utc(2025, 2, 1, 11, 0),
      ).copyWith(deletedAtUtc: DateTime.utc(2025, 2, 1, 12, 0));
      await milestoneRepo.save(deletedMilestone);

      final workoutRows = await db.customSelect(
        'SELECT created_at_utc, last_edited_at_utc FROM workout_logs WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>('log-z')],
      ).getSingle();
      expect(
          (workoutRows.data['created_at_utc'] as String).endsWith('Z'), isTrue);
      expect(
        (workoutRows.data['last_edited_at_utc'] as String).endsWith('Z'),
        isTrue,
      );

      final instanceRows = await db.customSelect(
        'SELECT created_at_utc FROM task_activations WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>('activation-z')],
      ).getSingle();
      expect((instanceRows.data['created_at_utc'] as String).endsWith('Z'),
          isTrue);

      final milestoneRows = await db.customSelect(
        'SELECT created_at_utc, deleted_at_utc FROM milestones WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>('ms-z')],
      ).getSingle();
      expect((milestoneRows.data['created_at_utc'] as String).endsWith('Z'),
          isTrue);

      final deletedMilestoneRows = await db.customSelect(
        'SELECT created_at_utc, deleted_at_utc FROM milestones WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>('ms-z-del')],
      ).getSingle();
      expect(
        (deletedMilestoneRows.data['created_at_utc'] as String).endsWith('Z'),
        isTrue,
      );
      expect(
        (deletedMilestoneRows.data['deleted_at_utc'] as String).endsWith('Z'),
        isTrue,
      );
    });

    test('WorkoutLog findByDate stable order: created_at_utc ASC, id ASC',
        () async {
      final date = '2025-01-01';
      await workoutRepo.save(
        _log(
          id: 'log-2',
          date: date,
          createdAtUtc: DateTime.utc(2025, 1, 1, 10),
          lastEditedAtUtc: DateTime.utc(2025, 1, 1, 10),
        ),
      );
      await workoutRepo.save(
        _log(
          id: 'log-1',
          date: date,
          createdAtUtc: DateTime.utc(2025, 1, 1, 9),
          lastEditedAtUtc: DateTime.utc(2025, 1, 1, 9),
        ),
      );
      await workoutRepo.save(
        _log(
          id: 'log-0',
          date: date,
          createdAtUtc: DateTime.utc(2025, 1, 1, 9),
          lastEditedAtUtc: DateTime.utc(2025, 1, 1, 9),
        ),
      );

      final logs = await workoutRepo.findByDate(domain.DateOnly.parse(date));
      expect(
          logs.map((e) => e.id).toList(), <String>['log-0', 'log-1', 'log-2']);
    });

    test(
        'WorkoutLog findAll stable order: date DESC, created_at_utc DESC, id ASC',
        () async {
      await workoutRepo.save(
        _log(
          id: 'a',
          date: '2025-01-01',
          createdAtUtc: DateTime.utc(2025, 1, 1, 10),
          lastEditedAtUtc: DateTime.utc(2025, 1, 1, 10),
        ),
      );
      await workoutRepo.save(
        _log(
          id: 'b',
          date: '2025-01-02',
          createdAtUtc: DateTime.utc(2025, 1, 2, 10),
          lastEditedAtUtc: DateTime.utc(2025, 1, 2, 10),
        ),
      );
      await workoutRepo.save(
        _log(
          id: 'c',
          date: '2025-01-02',
          createdAtUtc: DateTime.utc(2025, 1, 2, 10),
          lastEditedAtUtc: DateTime.utc(2025, 1, 2, 10),
        ),
      );

      final logs = await workoutRepo.findAll();
      expect(logs.map((e) => e.id).toList(), <String>['b', 'c', 'a']);
    });

    test('Milestone dedupKey UNIQUE violation -> DB_CONSTRAINT_VIOLATION',
        () async {
      final first = domain.MilestoneEvent.pr(
        id: 'ms-1',
        exerciseId: 'ex-1',
        logId: 'log-1',
        metricValue: 120,
        createdAtUtc: DateTime.utc(2025, 1, 3, 9),
      );
      final second = first.copyWith(id: 'ms-2');

      await milestoneRepo.save(first);

      await expectLater(
        () => milestoneRepo.save(second),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.dbConstraintViolation,
          ),
        ),
      );
    });

    test(
        'TaskActivation save is atomic and rolls back when occurrences insert fails',
        () async {
      final badActivation = domain.TaskActivation(
        id: 'activation-rollback',
        templateId: 'tpl-rollback',
        startDate: domain.DateOnly.parse('2025-03-01'),
        createdAtUtc: DateTime.utc(2025, 3, 1, 7),
        occurrences: <domain.TaskOccurrence>[
          domain.TaskOccurrence(
            id: 'task-occ-rollback-1',
            date: domain.DateOnly.parse('2025-03-01'),
          ),
          domain.TaskOccurrence(
            id: 'task-occ-rollback-2',
            date: domain.DateOnly.parse('2025-03-01'),
          ),
        ],
      );

      await expectLater(
        () => taskActivationRepo.save(badActivation),
        throwsA(
          predicate(
            (e) =>
                e is StorageException &&
                e.errorCode == StorageException.dbConstraintViolation,
          ),
        ),
      );

      final loaded = await taskActivationRepo.findById('activation-rollback');
      expect(loaded, isNull);

      final occurrenceCountRow = await db.customSelect(
        'SELECT COUNT(*) AS c FROM task_occurrences WHERE activation_id = ?',
        variables: <Variable<Object>>[Variable<String>('activation-rollback')],
      ).getSingle();
      expect(occurrenceCountRow.data['c'], 0);
    });
  });
}

domain.WorkoutLog _log({
  required String id,
  required String date,
  required DateTime createdAtUtc,
  required DateTime lastEditedAtUtc,
  Map<String, dynamic>? metadata,
}) {
  return domain.WorkoutLog(
    id: id,
    date: domain.DateOnly.parse(date),
    createdAtUtc: createdAtUtc,
    lastEditedAtUtc: lastEditedAtUtc,
    metadata: metadata,
    blocks: <domain.LogBlock>[
      domain.LogBlock.textBlock(id: 'text-$id', text: 'note $id'),
    ],
  );
}

domain.TaskTemplate _template() {
  return domain.TaskTemplate(
    id: 'tpl-1',
    title: '5x5',
    description: '{"version":2}',
  );
}

domain.TaskActivation _activation({required String templateId}) {
  return domain.TaskActivation(
    id: 'activation-1',
    templateId: templateId,
    startDate: domain.DateOnly.parse('2025-01-01'),
    createdAtUtc: DateTime.utc(2025, 1, 1, 7),
    occurrences: <domain.TaskOccurrence>[
      domain.TaskOccurrence(
        id: 'task-occ-1',
        date: domain.DateOnly.parse('2025-01-01'),
      ),
      domain.TaskOccurrence(
        id: 'task-occ-2',
        date: domain.DateOnly.parse('2025-01-02'),
      ),
    ],
  );
}
