library;

import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../../cursor/cursor_codec.dart';
import '../../cursor/cursor_models.dart';
import '../../dtos/log_editor_dto.dart';
import '../../dtos/milestone_dto.dart';
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

class GetWorkoutLogsByDateRangeCursorUseCase
    implements UseCase<WorkoutLogCursorQuery, CursorPage<LogEditorDTO>> {
  final WorkoutLogRepository logRepository;

  const GetWorkoutLogsByDateRangeCursorUseCase({required this.logRepository});

  @override
  Future<CursorPage<LogEditorDTO>> execute(WorkoutLogCursorQuery input) async {
    _validateDateRange(input.from, input.to);

    WorkoutLogCursorKey? cursorKey;
    if (input.cursor != null) {
      cursorKey = CursorCodec.decodeWorkoutLog(input.cursor!);
    }

    final page = await logRepository.findByDateRangeCursor(
      from: input.from,
      to: input.to,
      pageSize: input.pageSize.clamp(1, 200),
      cursorKey: cursorKey,
    );

    return CursorPage(
      items: page.items
          .map(ApplicationMappers.toLogEditorDTO)
          .toList(growable: false),
      nextCursor: page.nextCursor,
    );
  }
}

class GetMilestonesByCreatedAtUtcRangeCursorUseCase
    implements UseCase<MilestoneCursorQuery, CursorPage<MilestoneDTO>> {
  final MilestoneRepository milestoneRepository;

  const GetMilestonesByCreatedAtUtcRangeCursorUseCase({
    required this.milestoneRepository,
  });

  @override
  Future<CursorPage<MilestoneDTO>> execute(MilestoneCursorQuery input) async {
    _validateUtcRange(input.fromUtc, input.toUtc);

    MilestoneCursorKey? cursorKey;
    if (input.cursor != null) {
      cursorKey = CursorCodec.decodeMilestone(input.cursor!);
    }

    final page = await milestoneRepository.findByCreatedAtUtcRangeCursor(
      fromUtc: input.fromUtc,
      toUtc: input.toUtc,
      pageSize: input.pageSize.clamp(1, 200),
      cursorKey: cursorKey,
    );

    return CursorPage(
      items: page.items.map(_toDTO).toList(growable: false),
      nextCursor: page.nextCursor,
    );
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
