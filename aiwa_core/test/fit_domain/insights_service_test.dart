import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

WorkoutLog _log({
  required String id,
  required DateOnly date,
  required DateTime lastEditedAtUtc,
  required double weight,
  required int reps,
}) {
  return WorkoutLog(
    id: id,
    date: date,
    createdAtUtc: DateTime.utc(2025, 1, 1),
    lastEditedAtUtc: lastEditedAtUtc,
    blocks: [
      LogBlock.exerciseBlock(
        id: 'b-$id',
        exerciseId: 'e1',
        exerciseNameSnapshot: 'Bench',
        sets: [SetRecord(weightKg: weight, reps: reps)],
      ),
    ],
  );
}

void main() {
  group('InsightsService PR', () {
    test('PR uses tie-break rules', () {
      final service = InsightsService();
      final log1 = _log(
        id: 'a',
        date: DateOnly(2025, 1, 1),
        lastEditedAtUtc: DateTime.utc(2025, 1, 1, 10),
        weight: 100,
        reps: 1,
      );
      final log2 = _log(
        id: 'b',
        date: DateOnly(2025, 1, 2),
        lastEditedAtUtc: DateTime.utc(2025, 1, 1, 9),
        weight: 100,
        reps: 1,
      );
      final log3 = _log(
        id: 'c',
        date: DateOnly(2025, 1, 2),
        lastEditedAtUtc: DateTime.utc(2025, 1, 2, 12),
        weight: 100,
        reps: 1,
      );
      final log4 = _log(
        id: 'd',
        date: DateOnly(2025, 1, 2),
        lastEditedAtUtc: DateTime.utc(2025, 1, 2, 12),
        weight: 100,
        reps: 1,
      );

      final pr = service.currentPRByExercise([log1, log2, log3, log4], 'e1');
      expect(pr, isNotNull);
      // date tie-break: log2/3/4 beat log1
      // lastEditedAtUtc tie-break: log3/4 beat log2
      // logId tie-break: log4 beats log3
      expect(pr!.logId, 'd');
    });

    test('PR ignores reps < 1', () {
      final service = InsightsService();
      final log1 = _log(
        id: 'a',
        date: DateOnly(2025, 1, 1),
        lastEditedAtUtc: DateTime.utc(2025, 1, 1, 10),
        weight: 120,
        reps: 0,
      );
      final log2 = _log(
        id: 'b',
        date: DateOnly(2025, 1, 2),
        lastEditedAtUtc: DateTime.utc(2025, 1, 2, 10),
        weight: 100,
        reps: 1,
      );
      final pr = service.currentPRByExercise([log1, log2], 'e1');
      expect(pr!.weightKg, 100);
    });
  });
}