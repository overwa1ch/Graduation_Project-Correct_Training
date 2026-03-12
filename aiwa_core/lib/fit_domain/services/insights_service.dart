import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/date_only.dart';
import '../common/typedef_ids.dart';
import '../log/set_record.dart';
import '../log/workout_log.dart';

part 'insights_service.freezed.dart';
part 'insights_service.g.dart';

@freezed
class PrRecord with _$PrRecord {
  const PrRecord._();

  @Assert('exerciseId.isNotEmpty')
  @Assert('logId.isNotEmpty')
  @Assert('lastEditedAtUtc.isUtc')
  factory PrRecord({
    required ExerciseId exerciseId,
    required double weightKg,
    required LogId logId,
    @DateOnlyJsonConverter() required DateOnly date,
    @UtcDateTimeConverter() required DateTime lastEditedAtUtc,
  }) = _PrRecord;

  factory PrRecord.fromJson(Map<String, dynamic> json) =>
      _$PrRecordFromJson(json);
}

class InsightsService {
  const InsightsService();

  PrRecord? currentPRByExercise(
      Iterable<WorkoutLog> logs, ExerciseId exerciseId) {
    PrRecord? best;
    for (final log in logs) {
      final maxWeight = _maxWeightInLog(log, exerciseId);
      if (maxWeight == null) continue;
      final candidate = PrRecord(
        exerciseId: exerciseId,
        weightKg: maxWeight,
        logId: log.id,
        date: log.date,
        lastEditedAtUtc: log.lastEditedAtUtc,
      );
      if (best == null || _isBetter(candidate, best)) {
        best = candidate;
      }
    }
    return best;
  }

  Map<ExerciseId, PrRecord> allCurrentPRs(Iterable<WorkoutLog> logs) {
    final result = <ExerciseId, PrRecord>{};
    for (final log in logs) {
      final topByExercise = _topWeightByExercise(log);
      for (final entry in topByExercise.entries) {
        final exerciseId = entry.key;
        final candidate = PrRecord(
          exerciseId: exerciseId,
          weightKg: entry.value,
          logId: log.id,
          date: log.date,
          lastEditedAtUtc: log.lastEditedAtUtc,
        );
        final current = result[exerciseId];
        if (current == null || _isBetter(candidate, current)) {
          result[exerciseId] = candidate;
        }
      }
    }
    return result;
  }

  double logVolume(WorkoutLog log) {
    double total = 0;
    for (final block in log.blocks) {
      block.maybeMap(
        exerciseBlock: (b) {
          total += _volumeFromSets(b.sets);
        },
        orElse: () {},
      );
    }
    return total;
  }

  double exerciseVolumeInLog(WorkoutLog log, ExerciseId exerciseId) {
    double total = 0;
    for (final block in log.blocks) {
      block.maybeMap(
        exerciseBlock: (b) {
          if (b.exerciseId != exerciseId) return;
          total += _volumeFromSets(b.sets);
        },
        orElse: () {},
      );
    }
    return total;
  }

  double? maxEstimated1RM(Iterable<WorkoutLog> logs, ExerciseId exerciseId) {
    double? best;
    for (final log in logs) {
      for (final block in log.blocks) {
        block.maybeMap(
          exerciseBlock: (b) {
            if (b.exerciseId != exerciseId) return;
            for (final set in b.sets) {
              if (!set.isValid) continue;
              final e1rm = set.estimated1RM;
              if (best == null || e1rm > best!) {
                best = e1rm;
              }
            }
          },
          orElse: () {},
        );
      }
    }
    return best;
  }

  bool _isBetter(PrRecord candidate, PrRecord current) {
    if (candidate.weightKg != current.weightKg) {
      return candidate.weightKg > current.weightKg;
    }
    final dateCmp = candidate.date.compareTo(current.date);
    if (dateCmp != 0) return dateCmp > 0;
    final editedCmp =
        candidate.lastEditedAtUtc.compareTo(current.lastEditedAtUtc);
    if (editedCmp != 0) return editedCmp > 0;
    return candidate.logId.compareTo(current.logId) > 0;
  }

  double? _maxWeightInLog(WorkoutLog log, ExerciseId exerciseId) {
    double? best;
    for (final block in log.blocks) {
      block.maybeMap(
        exerciseBlock: (b) {
          if (b.exerciseId != exerciseId) return;
          for (final set in b.sets) {
            if (!set.isValid) continue;
            if (best == null || set.weightKg > best!) {
              best = set.weightKg;
            }
          }
        },
        orElse: () {},
      );
    }
    return best;
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

  double _volumeFromSets(List<SetRecord> sets) {
    double total = 0;
    for (final set in sets) {
      if (!set.isValid) continue;
      total += set.volume;
    }
    return total;
  }
}
