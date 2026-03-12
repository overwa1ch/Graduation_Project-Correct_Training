import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../../dtos/date_range_query.dart';
import '../../dtos/log_editor_dto.dart';
import '../../dtos/milestone_dto.dart';
import '../../dtos/utc_range_query.dart';
import '../../ports/repositories/milestone_repository.dart';
import '../../ports/repositories/workout_log_repository.dart';
import '../../ports/use_case.dart';
import '../../services/application_exception.dart';
import '../../services/error_codes.dart';
import '../../services/mappers.dart';

void _validateDateRange(DateOnly from, DateOnly to) {
  if (from.compareTo(to) > 0) {
    throw ApplicationException(
      AppErrorCodes.invalidRange,
      'from ($from) must not be after to ($to)',
      <String, dynamic>{'from': from.toString(), 'to': to.toString()},
    );
  }
}

void _validateUtcRange(DateTime fromUtc, DateTime toUtc) {
  if (!fromUtc.isUtc || !toUtc.isUtc) {
    throw ApplicationException(
      AppErrorCodes.invalidUtcRange,
      'fromUtc and toUtc must be UTC DateTime instances',
      <String, dynamic>{
        'fromUtc': fromUtc.toIso8601String(),
        'toUtc': toUtc.toIso8601String(),
      },
    );
  }
  if (fromUtc.isAfter(toUtc)) {
    throw ApplicationException(
      AppErrorCodes.invalidUtcRange,
      'fromUtc ($fromUtc) must not be after toUtc ($toUtc)',
      <String, dynamic>{
        'fromUtc': fromUtc.toIso8601String(),
        'toUtc': toUtc.toIso8601String(),
      },
    );
  }
}

class GetWorkoutLogsByDateRangeUseCase
    implements UseCase<DateRangeQuery, List<LogEditorDTO>> {
  final WorkoutLogRepository logRepository;

  const GetWorkoutLogsByDateRangeUseCase({required this.logRepository});

  @override
  Future<List<LogEditorDTO>> execute(DateRangeQuery input) async {
    _validateDateRange(input.from, input.to);
    final logs = await logRepository.findByDateRange(
      from: input.from,
      to: input.to,
      limit: input.limit,
      offset: input.offset,
    );
    return logs.map(ApplicationMappers.toLogEditorDTO).toList(growable: false);
  }
}

class GetMilestonesByCreatedAtUtcRangeUseCase
    implements UseCase<UtcRangeQuery, List<MilestoneDTO>> {
  final MilestoneRepository milestoneRepository;

  const GetMilestonesByCreatedAtUtcRangeUseCase({
    required this.milestoneRepository,
  });

  @override
  Future<List<MilestoneDTO>> execute(UtcRangeQuery input) async {
    _validateUtcRange(input.fromUtc, input.toUtc);
    final events = await milestoneRepository.findByCreatedAtUtcRange(
      fromUtc: input.fromUtc,
      toUtc: input.toUtc,
      limit: input.limit,
      offset: input.offset,
    );
    return events.map(_toDTO).toList(growable: false);
  }

  static MilestoneDTO _toDTO(MilestoneEvent e) => MilestoneDTO(
        id: e.id,
        type: e.type,
        exerciseId: e.exerciseId,
        logId: e.logId,
        metricValue: e.metricValue,
        dedupKey: e.dedupKey,
        createdAtUtc: e.createdAtUtc.toIso8601String(),
        deletedAtUtc: e.deletedAtUtc?.toIso8601String(),
      );
}
