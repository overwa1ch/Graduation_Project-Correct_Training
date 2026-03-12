import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ExerciseBlock set operations', () {
    test('add/update/remove with validation', () {
      final log = WorkoutLog(
        id: 'log-1',
        date: DateOnly(2025, 1, 2),
        createdAtUtc: DateTime.utc(2025, 1, 2, 10),
        lastEditedAtUtc: DateTime.utc(2025, 1, 2, 10, 5),
        blocks: [
          LogBlock.exerciseBlock(
            id: 'ex-1',
            exerciseId: 'e1',
            exerciseNameSnapshot: 'Bench',
            sets: [],
          ),
          LogBlock.textBlock(id: 't1', text: 'note'),
        ],
      );

      final now = DateTime.utc(2025, 1, 2, 11);
      log.addSet('ex-1', SetRecord(weightKg: 100, reps: 5), now);
      final exerciseBlock = log.blocks.first as ExerciseBlock;
      expect(exerciseBlock.sets.length, 1);

      log.updateSet('ex-1', 0, SetRecord(weightKg: 105, reps: 3), now);
      final updatedBlock = log.blocks.first as ExerciseBlock;
      expect(updatedBlock.sets.first.weightKg, 105);

      log.removeSet('ex-1', 0, now);
      final clearedBlock = log.blocks.first as ExerciseBlock;
      expect(clearedBlock.sets, isEmpty);

      expect(
        () => log.updateSet('ex-1', 0, SetRecord(weightKg: 80, reps: 5), now),
        throwsA(isA<ValidationException>()),
      );

      expect(
        () => log.addSet('t1', SetRecord(weightKg: 60, reps: 5), now),
        throwsA(isA<InvariantException>()),
      );
    });
  });
}
