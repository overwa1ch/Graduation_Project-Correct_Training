library;

import 'dart:convert';
import 'dart:io';

import 'package:aiwa_core/fit_application/cursor/cursor_codec.dart';
import 'package:aiwa_core/fit_application/cursor/cursor_models.dart';
import 'package:aiwa_core/fit_application/services/application_exception.dart';
import 'package:aiwa_core/fit_application/services/error_codes.dart';
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

String _badCursor() => 'not-valid-base64url!!!';

String _wrongNamespaceCursor() =>
    CursorCodec.encode('wrong:namespace:v1', <String, dynamic>{'k': 'v'});

String _badWorkoutLogVersionCursor() {
  final payload = <String, dynamic>{
    'v': 99,
    'h': WorkoutLogCursorKey.namespace,
    'k': <String, dynamic>{},
  };
  return base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
}

void main() {
  group('Cursor Pagination - Storage layer', () {
    late Directory tempDir;
    late FitStoragePaths paths;
    late FitDatabase db;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('fit_cursor_pagination_');
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

    group('WorkoutLogRepository.findByDateRangeCursor', () {
      late DriftWorkoutLogRepository repo;

      setUp(() => repo = DriftWorkoutLogRepository(db));

      test('second page via nextCursor contains no overlaps', () async {
        for (var i = 1; i <= 6; i++) {
          await repo.save(
            _log(
              id: 'l-$i',
              date: '2026-02-0$i',
              createdAt: DateTime.utc(2026, 2, i, 9),
            ),
          );
        }

        final page1 = await repo.findByDateRangeCursor(
          from: domain.DateOnly.parse('2026-02-01'),
          to: domain.DateOnly.parse('2026-02-06'),
          pageSize: 3,
        );
        final cursorKey = CursorCodec.decodeWorkoutLog(page1.nextCursor!);
        final page2 = await repo.findByDateRangeCursor(
          from: domain.DateOnly.parse('2026-02-01'),
          to: domain.DateOnly.parse('2026-02-06'),
          pageSize: 3,
          cursorKey: cursorKey,
        );

        expect(
          page1.items.map((e) => e.id).toSet().intersection(
                page2.items.map((e) => e.id).toSet(),
              ),
          isEmpty,
        );
      });

      test('invalid cursor surfaces INVALID_CURSOR', () {
        expect(
          () => CursorCodec.decodeWorkoutLog(_badCursor()),
          throwsA(
            predicate(
              (e) =>
                  e is ApplicationException &&
                  e.errorCode == AppErrorCodes.invalidCursor,
            ),
          ),
        );
      });

      test('wrong namespace surfaces CURSOR_MISMATCH', () {
        expect(
          () => CursorCodec.decodeWorkoutLog(_wrongNamespaceCursor()),
          throwsA(
            predicate(
              (e) =>
                  e is ApplicationException &&
                  e.errorCode == AppErrorCodes.cursorMismatch,
            ),
          ),
        );
      });

      test('unsupported version surfaces INVALID_CURSOR_VERSION', () {
        expect(
          () => CursorCodec.decodeWorkoutLog(_badWorkoutLogVersionCursor()),
          throwsA(
            predicate(
              (e) =>
                  e is ApplicationException &&
                  e.errorCode == AppErrorCodes.invalidCursorVersion,
            ),
          ),
        );
      });
    });

    group('MilestoneRepository.findByCreatedAtUtcRangeCursor', () {
      late DriftMilestoneRepository repo;

      setUp(() => repo = DriftMilestoneRepository(db));

      test('second page via nextCursor has no overlaps', () async {
        for (var i = 1; i <= 6; i++) {
          await repo.save(
            _milestone(
              id: 'm-$i',
              exerciseId: 'ex-$i',
              logId: 'l-$i',
              createdAt: DateTime.utc(2026, 2, i, 10),
            ),
          );
        }

        final page1 = await repo.findByCreatedAtUtcRangeCursor(
          fromUtc: DateTime.utc(2026, 2, 1),
          toUtc: DateTime.utc(2026, 2, 28),
          pageSize: 3,
        );
        final cursorKey = CursorCodec.decodeMilestone(page1.nextCursor!);
        final page2 = await repo.findByCreatedAtUtcRangeCursor(
          fromUtc: DateTime.utc(2026, 2, 1),
          toUtc: DateTime.utc(2026, 2, 28),
          pageSize: 3,
          cursorKey: cursorKey,
        );

        expect(
          page1.items.map((e) => e.id).toSet().intersection(
                page2.items.map((e) => e.id).toSet(),
              ),
          isEmpty,
        );
      });

      test('wrong namespace surfaces CURSOR_MISMATCH', () {
        expect(
          () => CursorCodec.decodeMilestone(
            CursorCodec.encodeWorkoutLog(
              const WorkoutLogCursorKey(
                date: '2026-01-01',
                createdAtUtc: '2026-01-01T09:00:00.000Z',
                id: 'l-1',
              ),
            ),
          ),
          throwsA(
            predicate(
              (e) =>
                  e is ApplicationException &&
                  e.errorCode == AppErrorCodes.cursorMismatch,
            ),
          ),
        );
      });
    });
  });
}
