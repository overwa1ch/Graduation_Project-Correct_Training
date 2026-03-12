import '../../dtos/calendar_snapshot_dto.dart';
import '../../dtos/log_editor_dto.dart';
import '../../ports/repositories/workout_log_repository.dart';
import '../../../fit_domain/fit_domain.dart';
import '../../ports/use_case.dart';
import '../../services/mappers.dart';

class GetCalendarSnapshotUseCase
    implements UseCase<CalendarSnapshotQuery, CalendarSnapshotDTO> {
  final WorkoutLogRepository workoutLogRepository;

  const GetCalendarSnapshotUseCase({
    required this.workoutLogRepository,
  });

  @override
  Future<CalendarSnapshotDTO> execute(CalendarSnapshotQuery input) async {
    final yearCountRows = await workoutLogRepository.countByDateRangeCursor(
      from: input.yearFrom,
      to: input.yearTo,
      pageSize: 366,
    );
    final monthCountRows = await workoutLogRepository.countByDateRangeCursor(
      from: input.monthFrom,
      to: input.monthTo,
      pageSize: 31,
    );

    final yearLogCountByDay = <String, int>{};
    for (final row in yearCountRows.items) {
      yearLogCountByDay[row.date.toString()] = row.count;
    }

    final monthLogCountByDay = <String, int>{};
    for (final row in monthCountRows.items) {
      monthLogCountByDay[row.date.toString()] = row.count;
    }

    final yearLogs = await _safeLoadLogs(
      from: input.yearFrom,
      to: input.yearTo,
    );
    final monthLogs = await _safeLoadLogs(
      from: input.monthFrom,
      to: input.monthTo,
    );

    return CalendarSnapshotDTO(
      yearLogs: yearLogs,
      monthLogs: monthLogs,
      yearLogDays: yearLogCountByDay.keys.toSet(),
      yearLogCountByDay: yearLogCountByDay,
      monthLogCountByDay: monthLogCountByDay,
    );
  }

  Future<List<LogEditorDTO>> _safeLoadLogs({
    required DateOnly from,
    required DateOnly to,
  }) async {
    try {
      final logs =
          await workoutLogRepository.findByDateRange(from: from, to: to);
      return logs
          .map(ApplicationMappers.toLogEditorDTO)
          .toList(growable: false);
    } catch (_) {
      return const <LogEditorDTO>[];
    }
  }
}
