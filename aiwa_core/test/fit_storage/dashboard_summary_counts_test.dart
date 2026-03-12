library;

import 'dart:io';

import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:aiwa_core/fit_storage.dart';
import 'package:test/test.dart';

domain.WorkoutLog _log({
  required String id,
  required String date,
}) {
  return domain.WorkoutLog(
    id: id,
    date: domain.DateOnly.parse(date),
    createdAtUtc: DateTime.utc(2026, 1, 1, 9),
    lastEditedAtUtc: DateTime.utc(2026, 1, 1, 9),
    blocks: const <domain.LogBlock>[],
  );
}

void main() {
  group('Dashboard Summary Counts - Storage layer', () {
    late Directory tempDir;
    late FitStoragePaths paths;
    late FitDatabase db;

    setUp(() async {
      tempDir = await Directory.systemTemp
          .createTemp('fit_dashboard_summary_counts_');
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

    group('WorkoutLogRepository.countByDateRangeCursor', () {
      late DriftWorkoutLogRepository repo;

      setUp(() => repo = DriftWorkoutLogRepository(db));

      test('correct daily count for multiple logs on same day', () async {
        await repo.save(_log(id: 'l1', date: '2026-01-01'));
        await repo.save(_log(id: 'l2', date: '2026-01-01'));
        await repo.save(_log(id: 'l3', date: '2026-01-02'));

        final page = await repo.countByDateRangeCursor(
          from: domain.DateOnly.parse('2026-01-01'),
          to: domain.DateOnly.parse('2026-01-02'),
          pageSize: 10,
        );

        expect(page.items.length, 2);
        expect(page.items[0].date.toString(), '2026-01-02');
        expect(page.items[0].count, 1);
        expect(page.items[1].date.toString(), '2026-01-01');
        expect(page.items[1].count, 2);
      });

      test('cursorDate only returns date < cursorDate', () async {
        for (var i = 1; i <= 5; i++) {
          await repo.save(_log(id: 'l-$i', date: '2026-03-0$i'));
        }

        final page = await repo.countByDateRangeCursor(
          from: domain.DateOnly.parse('2026-03-01'),
          to: domain.DateOnly.parse('2026-03-05'),
          pageSize: 10,
          cursorDate: domain.DateOnly.parse('2026-03-04'),
        );

        final dates = page.items.map((r) => r.date.toString()).toList();
        expect(dates, isNot(contains('2026-03-04')));
        expect(dates, isNot(contains('2026-03-05')));
        expect(dates, contains('2026-03-03'));
        expect(dates, contains('2026-03-01'));
      });

      test('pageSize limits result rows', () async {
        for (var i = 1; i <= 6; i++) {
          await repo.save(_log(id: 'l-$i', date: '2026-04-0$i'));
        }

        final page = await repo.countByDateRangeCursor(
          from: domain.DateOnly.parse('2026-04-01'),
          to: domain.DateOnly.parse('2026-04-06'),
          pageSize: 3,
        );

        expect(page.items.length, 3);
        expect(page.items[0].date.toString(), '2026-04-06');
        expect(page.items[1].date.toString(), '2026-04-05');
        expect(page.items[2].date.toString(), '2026-04-04');
      });
    });
  });
}
