import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../dtos/log_editor_dto.dart';
import '../ports/clock.dart';
import '../ports/repositories/workout_log_repository.dart';
import '../ports/unit_of_work.dart';
import 'application_exception.dart';
import 'error_codes.dart';
import 'mappers.dart';
import 'milestone_write_service.dart';
import 'not_found.dart';

typedef WorkoutLogMutation = void Function(WorkoutLog log, DateTime nowUtc);

/// 统一写操作执行模板（Spec §9.3 流程模板）：
///
/// 1. nowUtc（断言 UTC）
/// 2. load logBefore
/// 3. mutate(log, nowUtc)（Domain 方法，同步）
/// 4. save logAfter
/// 5. 若 [triggerMilestone] == true：milestone 检测（仅 Set 操作，Spec §9.4）
/// 6. return LogEditorDTO
class LogWriteExecutor {
  final WorkoutLogRepository logRepository;
  final Clock clock;
  final UnitOfWork unitOfWork;
  final MilestoneWriteService milestoneWriteService;

  const LogWriteExecutor({
    required this.logRepository,
    required this.clock,
    required this.unitOfWork,
    required this.milestoneWriteService,
  });

  Future<LogEditorDTO> execute({
    required LogId logId,
    required WorkoutLogMutation mutation,
    bool triggerMilestone = false,
  }) {
    return unitOfWork.runInTransaction(() async {
      // 步骤 1: UTC 断言（Spec §4.1）
      final nowUtc = clock.nowUtc();
      requireClockUtc(nowUtc);

      // 步骤 2: load logBefore
      final log = requireFound(
        await logRepository.findById(logId),
        errorCode: AppErrorCodes.workoutLogNotFound,
        message: 'WorkoutLog not found',
        context: <String, dynamic>{'logId': logId},
      );

      // 步骤 3 & 4: mutate（Domain，同步）→ save
      mutation(log, nowUtc);
      await logRepository.save(log);

      // 步骤 5: milestone 仅 Set 操作触发（Spec §9.4）
      if (triggerMilestone) {
        await milestoneWriteService.handleLogChanged(
          changedLogId: log.id,
          nowUtc: nowUtc,
        );
      }

      return ApplicationMappers.toLogEditorDTO(log);
    });
  }
}
