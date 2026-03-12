import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

import 'support/in_memory_repositories.dart';

void main() {
  group('GetCalendarSnapshotUseCase', () {
    test('builds year and expanded-month log markers', () async {
      final logRepo = InMemoryWorkoutLogRepository();

      await logRepo.save(_log(id: 'log-a', date: '2026-03-10'));
      await logRepo.save(_log(id: 'log-b', date: '2026-03-10'));
      await logRepo.save(_log(id: 'log-c', date: '2026-03-11'));
      await logRepo.save(_log(id: 'log-d', date: '2026-01-05'));

      final useCase = GetCalendarSnapshotUseCase(
        workoutLogRepository: logRepo,
      );

      final result = await useCase.execute(
        CalendarSnapshotQuery(
          yearFrom: DateOnly(2026, 1, 1),
          yearTo: DateOnly(2026, 12, 31),
          monthFrom: DateOnly(2026, 3, 1),
          monthTo: DateOnly(2026, 3, 31),
        ),
      );

      expect(result.yearLogs.length, 4);
      expect(result.monthLogs.length, 3);
      expect(
        result.yearLogDays,
        containsAll(<String>[
          '2026-01-05',
          '2026-03-10',
          '2026-03-11',
        ]),
      );
      expect(result.yearLogCountByDay['2026-01-05'], 1);
      expect(result.yearLogCountByDay['2026-03-10'], 2);
      expect(result.yearLogCountByDay['2026-03-11'], 1);
      expect(result.monthLogCountByDay['2026-03-10'], 2);
      expect(result.monthLogCountByDay['2026-03-11'], 1);
    });

    test('keeps markers even if log list decoding fails', () async {
      final logRepo = _FailingRangeWorkoutLogRepository();

      await logRepo.save(_log(id: 'log-a', date: '2026-03-10'));
      await logRepo.save(_log(id: 'log-b', date: '2026-03-11'));

      final useCase = GetCalendarSnapshotUseCase(
        workoutLogRepository: logRepo,
      );

      final result = await useCase.execute(
        CalendarSnapshotQuery(
          yearFrom: DateOnly(2026, 1, 1),
          yearTo: DateOnly(2026, 12, 31),
          monthFrom: DateOnly(2026, 3, 1),
          monthTo: DateOnly(2026, 3, 31),
        ),
      );

      expect(result.yearLogs, isEmpty);
      expect(result.monthLogs, isEmpty);
      expect(result.yearLogDays,
          containsAll(<String>['2026-03-10', '2026-03-11']));
      expect(result.yearLogCountByDay['2026-03-10'], 1);
      expect(result.monthLogCountByDay['2026-03-11'], 1);
    });
  });
}

WorkoutLog _log({
  required String id,
  required String date,
}) {
  return WorkoutLog(
    id: id,
    date: DateOnly.parse(date),
    createdAtUtc: DateTime.utc(2026, 3, 1, 8),
    lastEditedAtUtc: DateTime.utc(2026, 3, 1, 8),
    blocks: <LogBlock>[
      LogBlock.textBlock(id: 'text-$id', text: 'note $id'),
    ],
  );
}

class _FailingRangeWorkoutLogRepository extends InMemoryWorkoutLogRepository {
  @override
  Future<List<WorkoutLog>> findByDateRange({
    required DateOnly from,
    required DateOnly to,
    int? limit,
    int? offset,
  }) {
    throw StateError('synthetic failure');
  }
}
