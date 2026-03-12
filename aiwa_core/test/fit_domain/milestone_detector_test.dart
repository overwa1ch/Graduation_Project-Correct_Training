import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:test/test.dart';

WorkoutLog _log(String id, double weight) {
  return WorkoutLog(
    id: id,
    date: DateOnly(2025, 1, int.parse(id.substring(1)) + 1),
    createdAtUtc: DateTime.utc(2025, 1, 1),
    lastEditedAtUtc: DateTime.utc(2025, 1, 1, 12),
    blocks: [
      LogBlock.exerciseBlock(
        id: 'b-$id',
        exerciseId: 'e1',
        exerciseNameSnapshot: 'Bench',
        sets: [SetRecord(weightKg: weight, reps: 1)],
      ),
    ],
  );
}

void main() {
  group('MilestoneDetector', () {
    test('triggers PR and respects dedup', () {
      final detector = MilestoneDetector();
      final log1 = _log('l1', 100);
      final log2 = _log('l2', 110);
      final log3 = _log('l3', 105);

      final now = DateTime.utc(2025, 1, 3, 10);
      final created = detector.detectPrMilestones(
        logs: [log1, log2, log3],
        existingEvents: [],
        idFactory: (exerciseId, logId) => 'm-$exerciseId-$logId',
        nowUtc: now,
      );

      expect(created.length, 2);
      expect(created[0].logId, 'l1');
      expect(created[1].logId, 'l2');

      final existing = [
        MilestoneEvent.pr(
          id: 'm-e1-l2',
          exerciseId: 'e1',
          logId: 'l2',
          metricValue: 110,
          createdAtUtc: now,
        ),
      ];

      final createdWithDedup = detector.detectPrMilestones(
        logs: [log1, log2, log3],
        existingEvents: existing,
        idFactory: (exerciseId, logId) => 'm-$exerciseId-$logId',
        nowUtc: now,
      );

      expect(createdWithDedup.length, 1);
      expect(createdWithDedup.first.logId, 'l1');
    });

    test('deleted milestone suppresses re-create', () {
      final detector = MilestoneDetector();
      final log1 = _log('l1', 100);
      final log2 = _log('l2', 110);

      final now = DateTime.utc(2025, 1, 3, 10);
      final deleted = MilestoneEvent.pr(
        id: 'm-e1-l2',
        exerciseId: 'e1',
        logId: 'l2',
        metricValue: 110,
        createdAtUtc: now,
      ).copyWith(deletedAtUtc: DateTime.utc(2025, 1, 4));

      final created = detector.detectPrMilestones(
        logs: [log1, log2],
        existingEvents: [deleted],
        idFactory: (exerciseId, logId) => 'm-$exerciseId-$logId',
        nowUtc: now,
      );

      // l1 created, l2 suppressed because deleted
      expect(created.length, 1);
      expect(created.first.logId, 'l1');
    });
  });
}