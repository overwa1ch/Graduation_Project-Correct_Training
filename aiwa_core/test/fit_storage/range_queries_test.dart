library;

import 'dart:io';

import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:aiwa_core/fit_storage.dart';
import 'package:test/test.dart';

domain.WorkoutLog _log({
  required String id,
  required String date,
  DateTime? createdAt,
}) {
  return domain.WorkoutLog(
    id: id,
    date: domain.DateOnly.parse(date),
    createdAtUtc: createdAt ?? DateTime.utc(2026, 1, 1, 9),
    lastEditedAtUtc: createdAt ?? DateTime.utc(2026, 1, 1, 9),
    blocks: const <domain.LogBlock>[],
  );
}

domain.MilestoneEvent _milestone({
  required String id,
  required String exerciseId,
  required String logId,
  required DateTime createdAt,
}) {
  return domain.MilestoneEvent.pr(
    id: id,
    exerciseId: exerciseId,
    logId: logId,
    metricValue: 100,
    createdAtUtc: createdAt,
  );
}

void main() {
  group('Range Queries - Storage layer', () {
    late Directory tempDir;
    late FitStoragePaths paths;
    late FitDatabase db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fit_range_queries_');
      paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
      db = FitDatabase.openFile(paths.dbFile);
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('WorkoutLogRepository.findByDateRange', () {
      late DriftWorkoutLogRepository repo;

      setUp(() => repo = DriftWorkoutLogRepository(db));

      test('returns only logs within [from, to] closed interval', () async {
        await repo.save(_log(id: 'l-jan01', date: '2026-01-01'));
        await repo.save(_log(id: 'l-jan15', date: '2026-01-15'));
        await repo.save(_log(id: 'l-jan31', date: '2026-01-31'));
        await repo.save(_log(id: 'l-feb01', date: '2026-02-01'));

        final result = await repo.findByDateRange(
          from: domain.DateOnly.parse('2026-01-01'),
          to: domain.DateOnly.parse('2026-01-31'),
        );

        expect(
          result.map((e) => e.id).toList(),
          containsAll(<String>['l-jan01', 'l-jan15', 'l-jan31']),
        );
        expect(result.map((e) => e.id), isNot(contains('l-feb01')));
      });

      test('boundaries are inclusive', () async {
        await repo.save(_log(id: 'exact', date: '2026-03-10'));
        await repo.save(_log(id: 'before', date: '2026-03-09'));
        await repo.save(_log(id: 'after', date: '2026-03-11'));

        final result = await repo.findByDateRange(
          from: domain.DateOnly.parse('2026-03-10'),
          to: domain.DateOnly.parse('2026-03-10'),
        );

        expect(result.length, 1);
        expect(result.first.id, 'exact');
      });

      test('sort: date DESC, createdAtUtc DESC, id ASC', () async {
        await repo.save(
          _log(
            id: 'l-a',
            date: '2026-02-05',
            createdAt: DateTime.utc(2026, 2, 5, 8),
          ),
        );
        await repo.save(
          _log(
            id: 'l-b',
            date: '2026-02-05',
            createdAt: DateTime.utc(2026, 2, 5, 10),
          ),
        );
        await repo.save(_log(id: 'l-early', date: '2026-02-01'));

        final result = await repo.findByDateRange(
          from: domain.DateOnly.parse('2026-02-01'),
          to: domain.DateOnly.parse('2026-02-05'),
        );

        expect(result[0].id, 'l-b');
        expect(result[1].id, 'l-a');
        expect(result.last.id, 'l-early');
      });

      test('limit and offset work correctly', () async {
        for (var i = 1; i <= 5; i++) {
          await repo.save(
            _log(
              id: 'l-$i',
              date: '2026-04-0$i',
              createdAt: DateTime.utc(2026, 4, i, 9),
            ),
          );
        }

        final page1 = await repo.findByDateRange(
          from: domain.DateOnly.parse('2026-04-01'),
          to: domain.DateOnly.parse('2026-04-05'),
          limit: 2,
        );
        final page2 = await repo.findByDateRange(
          from: domain.DateOnly.parse('2026-04-01'),
          to: domain.DateOnly.parse('2026-04-05'),
          limit: 2,
          offset: 2,
        );

        expect(page1.length, 2);
        expect(page2.length, 2);
        expect(
          page1
              .map((e) => e.id)
              .toSet()
              .intersection(page2.map((e) => e.id).toSet()),
          isEmpty,
        );
      });
    });

    group('MilestoneRepository.findByCreatedAtUtcRange', () {
      late DriftMilestoneRepository repo;

      setUp(() => repo = DriftMilestoneRepository(db));

      test('returns only milestones within [fromUtc, toUtc]', () async {
        await repo.save(
          _milestone(
            id: 'm-jan',
            exerciseId: 'ex-1',
            logId: 'l-1',
            createdAt: DateTime.utc(2026, 1, 15, 10),
          ),
        );
        await repo.save(
          _milestone(
            id: 'm-feb',
            exerciseId: 'ex-2',
            logId: 'l-2',
            createdAt: DateTime.utc(2026, 2, 15, 10),
          ),
        );
        await repo.save(
          _milestone(
            id: 'm-mar',
            exerciseId: 'ex-3',
            logId: 'l-3',
            createdAt: DateTime.utc(2026, 3, 1),
          ),
        );

        final result = await repo.findByCreatedAtUtcRange(
          fromUtc: DateTime.utc(2026, 1, 1),
          toUtc: DateTime.utc(2026, 2, 28, 23, 59, 59),
        );

        expect(
          result.map((e) => e.id).toList(),
          containsAll(<String>['m-jan', 'm-feb']),
        );
        expect(result.map((e) => e.id), isNot(contains('m-mar')));
      });

      test('sort: createdAtUtc DESC, id ASC', () async {
        await repo.save(
          _milestone(
            id: 'm-old',
            exerciseId: 'ex-5',
            logId: 'l-5',
            createdAt: DateTime.utc(2026, 5, 1, 8),
          ),
        );
        await repo.save(
          _milestone(
            id: 'm-new',
            exerciseId: 'ex-6',
            logId: 'l-6',
            createdAt: DateTime.utc(2026, 5, 1, 18),
          ),
        );

        final result = await repo.findByCreatedAtUtcRange(
          fromUtc: DateTime.utc(2026, 5, 1),
          toUtc: DateTime.utc(2026, 5, 2),
        );

        expect(result.first.id, 'm-new');
        expect(result.last.id, 'm-old');
      });
    });
  });
}
