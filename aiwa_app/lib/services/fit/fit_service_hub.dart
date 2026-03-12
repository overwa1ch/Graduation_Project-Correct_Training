import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_storage.dart';

import 'package:aiwa_app/services/fit/task_template_occurrence_sync_service.dart';

/// Central hub for fit use cases and repositories.
class FitServiceHub {
  final FitStoragePaths paths;
  final FitDatabase db;

  final WorkoutLogRepository workoutLogRepository;
  final ExerciseRepository exerciseRepository;
  final TagRepository tagRepository;
  final TaskActivationRepository taskActivationRepository;

  final GetHomeDashboardUseCase getHomeDashboardUseCase;
  final GetExerciseCatalogCursorUseCase getExerciseCatalogCursorUseCase;
  final GetTagCatalogCursorUseCase getTagCatalogCursorUseCase;
  final GetWorkoutLogsByDateRangeUseCase getWorkoutLogsByDateRangeUseCase;
  final GetCalendarSnapshotUseCase getCalendarSnapshotUseCase;
  final GetTaskTemplatesUseCase getTaskTemplatesUseCase;
  final GetTaskTemplateByIdUseCase getTaskTemplateByIdUseCase;
  final SaveTaskTemplateUseCase saveTaskTemplateUseCase;
  final DeleteTaskTemplateUseCase deleteTaskTemplateUseCase;
  final EnsureTaskActivationUseCase ensureTaskActivationUseCase;
  final DeleteTaskLogUseCase deleteTaskLogUseCase;
  final CreateWorkoutLogUseCase createWorkoutLogUseCase;
  final InsertBlockUseCase insertBlockUseCase;
  final AppendBlockUseCase appendBlockUseCase;
  final UpdateBlockUseCase updateBlockUseCase;
  final RemoveBlockUseCase removeBlockUseCase;
  final ReorderBlocksUseCase reorderBlocksUseCase;
  final TaskTemplateOccurrenceSyncService taskTemplateOccurrenceSyncService;

  const FitServiceHub({
    required this.paths,
    required this.db,
    required this.workoutLogRepository,
    required this.exerciseRepository,
    required this.tagRepository,
    required this.taskActivationRepository,
    required this.getHomeDashboardUseCase,
    required this.getExerciseCatalogCursorUseCase,
    required this.getTagCatalogCursorUseCase,
    required this.getWorkoutLogsByDateRangeUseCase,
    required this.getCalendarSnapshotUseCase,
    required this.getTaskTemplatesUseCase,
    required this.getTaskTemplateByIdUseCase,
    required this.saveTaskTemplateUseCase,
    required this.deleteTaskTemplateUseCase,
    required this.ensureTaskActivationUseCase,
    required this.deleteTaskLogUseCase,
    required this.createWorkoutLogUseCase,
    required this.insertBlockUseCase,
    required this.appendBlockUseCase,
    required this.updateBlockUseCase,
    required this.removeBlockUseCase,
    required this.reorderBlocksUseCase,
    required this.taskTemplateOccurrenceSyncService,
  });
}
