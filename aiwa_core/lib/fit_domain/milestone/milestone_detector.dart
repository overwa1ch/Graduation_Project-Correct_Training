import '../common/domain_exception.dart';
import '../common/typedef_ids.dart';
import '../log/workout_log.dart';
import 'milestone_event.dart';

class MilestoneDetector {
  const MilestoneDetector();

  List<MilestoneEvent> detectPrMilestones({
    required Iterable<WorkoutLog> logs,
    required Iterable<MilestoneEvent> existingEvents,
    required MilestoneEventId Function(ExerciseId exerciseId, LogId logId)
        idFactory,
    required DateTime nowUtc,
  }) {
    requireUtc(nowUtc, 'nowUtc');

    final existingDedup = <String>{};
    final suppressedDedup = <String>{};
    for (final event in existingEvents) {
      existingDedup.add(event.dedupKey);
      if (event.deletedAtUtc != null) {
        suppressedDedup.add(event.dedupKey);
      }
    }

    final sortedLogs = logs.toList()
      ..sort((a, b) {
        final dateCmp = a.date.compareTo(b.date);
        if (dateCmp != 0) return dateCmp;
        final editedCmp = a.lastEditedAtUtc.compareTo(b.lastEditedAtUtc);
        if (editedCmp != 0) return editedCmp;
        return a.id.compareTo(b.id);
      });

    final previousMax = <ExerciseId, double>{};
    final created = <MilestoneEvent>[];

    for (final log in sortedLogs) {
      final topByExercise = _topWeightByExercise(log);
      for (final entry in topByExercise.entries) {
        final exerciseId = entry.key;
        final topWeight = entry.value;
        final prev = previousMax[exerciseId];
        if (prev == null || topWeight > prev) {
          previousMax[exerciseId] = topWeight;
          final dedupKey = 'pr:$exerciseId:${log.id}';
          if (existingDedup.contains(dedupKey) ||
              suppressedDedup.contains(dedupKey)) {
            continue;
          }
          created.add(MilestoneEvent.pr(
            id: idFactory(exerciseId, log.id),
            exerciseId: exerciseId,
            logId: log.id,
            metricValue: topWeight,
            createdAtUtc: nowUtc,
          ));
          existingDedup.add(dedupKey);
        }
      }
    }

    return created;
  }

  Map<ExerciseId, double> _topWeightByExercise(WorkoutLog log) {
    final result = <ExerciseId, double>{};
    for (final block in log.blocks) {
      block.maybeMap(
        exerciseBlock: (b) {
          double? blockMax;
          for (final set in b.sets) {
            if (!set.isValid) continue;
            if (blockMax == null || set.weightKg > blockMax) {
              blockMax = set.weightKg;
            }
          }
          if (blockMax == null) return;
          final current = result[b.exerciseId];
          if (current == null || blockMax > current) {
            result[b.exerciseId] = blockMax;
          }
        },
        orElse: () {},
      );
    }
    return result;
  }
}
