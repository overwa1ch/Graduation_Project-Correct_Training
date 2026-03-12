import '../../dtos/pr_summary_dto.dart';
import '../../ports/clock.dart';
import '../../ports/repositories/workout_log_repository.dart';
import '../../ports/use_case.dart';
import '../../services/application_exception.dart';
import '../../services/mappers.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

class GetCurrentPRSummaryUseCase implements UseCase<void, PRSummaryDTO> {
  final WorkoutLogRepository workoutLogRepository;
  final InsightsService insightsService;
  final Clock clock;

  const GetCurrentPRSummaryUseCase({
    required this.workoutLogRepository,
    required this.insightsService,
    required this.clock,
  });

  @override
  Future<PRSummaryDTO> execute(void input) async {
    final logs = await workoutLogRepository.findAll();
    final prMap = insightsService.allCurrentPRs(logs);

    final sorted = prMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final prs = sorted.map((entry) {
      return ApplicationMappers.toExercisePrDTO(entry.value);
    }).toList();

    final computedAtUtc = clock.nowUtc();
    requireClockUtc(computedAtUtc);

    return ApplicationMappers.toPRSummaryDTO(prs, computedAtUtc);
  }
}
