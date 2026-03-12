import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../ports/id_generator.dart';
import '../ports/repositories/milestone_repository.dart';
import '../ports/repositories/workout_log_repository.dart';
import 'error_codes.dart';

/// MilestoneWriteService — Milestone 落库编排（Spec §9.2 ~ §9.5）
///
/// 仅被 [AddSetUseCase] / [UpdateSetUseCase] / [RemoveSetUseCase] 调用（Spec §9.4）。
/// 其他 Block 编辑用例不得调用本服务。
class MilestoneWriteService {
  final WorkoutLogRepository logRepository;
  final MilestoneRepository milestoneRepository;
  final IdGenerator idGenerator;
  final InsightsService insightsService;

  const MilestoneWriteService({
    required this.logRepository,
    required this.milestoneRepository,
    required this.idGenerator,
    required this.insightsService,
  });

  /// 在 log 已保存（logAfter）之后调用。
  ///
  /// baseline 通过排除 [changedLogId] 模拟"修改前"状态（Spec §9.3）。
  /// 严禁用 logAfter 回算 baseline。
  Future<void> handleLogChanged({
    required LogId changedLogId,
    required DateTime nowUtc,
  }) async {
    final logsAll = await logRepository.findAll();
    final changedLog = _findChangedLog(logsAll, changedLogId);

    final changedTopWeights = _topWeightByExercise(changedLog);
    if (changedTopWeights.isEmpty) return;

    // baseline = 排除 changedLog 后的全量（等价于 logBefore 状态）
    final baselineLogs = logsAll.where((log) => log.id != changedLogId);

    for (final entry in changedTopWeights.entries) {
      final exerciseId = entry.key;
      final changedLogTopWeight = entry.value;

      final baselinePr =
          insightsService.currentPRByExercise(baselineLogs, exerciseId);
      final previousMaxWeight = baselinePr?.weightKg;

      final isNewPr = previousMaxWeight == null
          ? true
          : changedLogTopWeight > previousMaxWeight;
      if (!isNewPr) continue;

      // 去重（Spec §9.5）
      final dedupKey = 'pr:$exerciseId:$changedLogId';
      final existing = await milestoneRepository.findByDedupKey(dedupKey);
      if (existing != null) continue; // existing（不管是否 deleted）均禁止重建/重复

      final event = MilestoneEvent.pr(
        id: idGenerator.newId(),
        exerciseId: exerciseId,
        logId: changedLogId,
        metricValue: changedLogTopWeight,
        createdAtUtc: nowUtc,
      );
      await milestoneRepository.save(event);
    }
  }

  WorkoutLog _findChangedLog(List<WorkoutLog> logsAll, LogId changedLogId) {
    for (final log in logsAll) {
      if (log.id == changedLogId) return log;
    }
    throw NotFoundException(
      AppErrorCodes.changedLogNotFound,
      'Changed workout log not found',
      <String, dynamic>{'logId': changedLogId},
    );
  }

  Map<ExerciseId, double> _topWeightByExercise(WorkoutLog log) {
    final result = <ExerciseId, double>{};
    for (final block in log.blocks) {
      block.maybeMap(
        exerciseBlock: (exerciseBlock) {
          double? maxWeight;
          for (final set in exerciseBlock.sets) {
            if (set.reps < 1) continue;
            if (maxWeight == null || set.weightKg > maxWeight) {
              maxWeight = set.weightKg;
            }
          }
          if (maxWeight == null) return;
          final previous = result[exerciseBlock.exerciseId];
          if (previous == null || maxWeight > previous) {
            result[exerciseBlock.exerciseId] = maxWeight;
          }
        },
        orElse: () {},
      );
    }
    return result;
  }
}
