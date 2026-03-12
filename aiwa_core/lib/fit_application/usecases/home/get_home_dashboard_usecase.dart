import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../../dtos/home_dashboard_dto.dart';
import '../../ports/clock.dart';
import '../../ports/repositories/workout_log_repository.dart';
import '../../ports/use_case.dart';
import '../../services/application_exception.dart';
import '../../services/mappers.dart';

class GetHomeDashboardUseCase implements UseCase<DateOnly, HomeDashboardDTO> {
  final WorkoutLogRepository workoutLogRepository;
  final InsightsService insightsService;
  final Clock clock;

  const GetHomeDashboardUseCase({
    required this.workoutLogRepository,
    required this.insightsService,
    required this.clock,
  });

  @override
  Future<HomeDashboardDTO> execute(DateOnly input) async {
    final logsForDay = await workoutLogRepository.findByDate(input);
    final allLogs = await workoutLogRepository.findAll();

    final sortedLogs = logsForDay.toList()
      ..sort((a, b) {
        final createdCmp = a.createdAtUtc.compareTo(b.createdAtUtc);
        if (createdCmp != 0) {
          return createdCmp;
        }
        return a.id.compareTo(b.id);
      });

    final prMap = insightsService.allCurrentPRs(allLogs);
    final sortedPrs = prMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final computedAtUtc = clock.nowUtc();
    requireClockUtc(computedAtUtc);

    final prSummary = ApplicationMappers.toPRSummaryDTO(
      sortedPrs
          .map((entry) => ApplicationMappers.toExercisePrDTO(entry.value))
          .toList(growable: false),
      computedAtUtc,
    );

    final logDTOs = sortedLogs
        .map(ApplicationMappers.toLogEditorDTO)
        .toList(growable: false);

    return HomeDashboardDTO(
      date: input,
      logs: logDTOs,
      prSummary: prSummary,
    );
  }
}
