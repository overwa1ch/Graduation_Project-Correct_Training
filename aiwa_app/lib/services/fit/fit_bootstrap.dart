import 'dart:io';

import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';
import 'package:aiwa_core/fit_storage.dart';

import 'package:aiwa_app/services/fit/fit_clock.dart';
import 'package:aiwa_app/services/fit/fit_id_generator.dart';
import 'package:aiwa_app/services/fit/fit_service_hub.dart';
import 'package:aiwa_app/services/fit/task_template_occurrence_sync_service.dart';

/// Bootstraps fit storage + application layer (no new deps).
/// Call [init] with app documents directory (e.g. from path_provider).
class FitBootstrap {
  FitBootstrap._();

  static Future<FitServiceHub> init(Directory appDocumentsDir) async {
    final paths = FitStoragePaths.fromAppDocumentsDir(appDocumentsDir);
    await paths.ensureInitialized();

    final db = FitDatabase.openFile(paths.dbFile);

    final workoutLogRepo = DriftWorkoutLogRepository(db);
    final taskOccurrenceRepo = DriftTaskOccurrenceRepository(db);
    final taskActivationRepo = DriftTaskActivationRepository(db);
    final taskTemplateRepo = DriftTaskTemplateRepository(db);
    final exerciseRepo = DriftExerciseRepository(db);
    final tagRepo = DriftTagRepository(db);
    final milestoneRepo = DriftMilestoneRepository(db);

    const clock = FitClock();
    const idGenerator = FitIdGenerator();
    const insightsService = InsightsService();
    final unitOfWork = DriftUnitOfWork(db);

    final milestoneWriteService = MilestoneWriteService(
      logRepository: workoutLogRepo,
      milestoneRepository: milestoneRepo,
      idGenerator: idGenerator,
      insightsService: insightsService,
    );

    final logWriteExecutor = LogWriteExecutor(
      logRepository: workoutLogRepo,
      clock: clock,
      unitOfWork: unitOfWork,
      milestoneWriteService: milestoneWriteService,
    );

    final getHomeDashboardUseCase = GetHomeDashboardUseCase(
      workoutLogRepository: workoutLogRepo,
      insightsService: insightsService,
      clock: clock,
    );

    final getExerciseCatalogCursorUseCase = GetExerciseCatalogCursorUseCase(
      exerciseRepository: exerciseRepo,
    );

    final getTagCatalogCursorUseCase = GetTagCatalogCursorUseCase(
      tagRepository: tagRepo,
    );

    final getWorkoutLogsByDateRangeUseCase = GetWorkoutLogsByDateRangeUseCase(
      logRepository: workoutLogRepo,
    );

    final getCalendarSnapshotUseCase = GetCalendarSnapshotUseCase(
      workoutLogRepository: workoutLogRepo,
    );
    final getTaskTemplatesUseCase = GetTaskTemplatesUseCase(
      taskTemplateRepository: taskTemplateRepo,
    );
    final getTaskTemplateByIdUseCase = GetTaskTemplateByIdUseCase(
      taskTemplateRepository: taskTemplateRepo,
    );
    final saveTaskTemplateUseCase = SaveTaskTemplateUseCase(
      taskTemplateRepository: taskTemplateRepo,
    );
    final deleteTaskTemplateUseCase = DeleteTaskTemplateUseCase(
      taskTemplateRepository: taskTemplateRepo,
    );

    final createWorkoutLogUseCase = CreateWorkoutLogUseCase(
      logRepository: workoutLogRepo,
      unitOfWork: unitOfWork,
      clock: clock,
      idGenerator: idGenerator,
    );
    final ensureTaskActivationUseCase = EnsureTaskActivationUseCase(
      taskActivationRepository: taskActivationRepo,
      clock: clock,
      idGenerator: idGenerator,
    );
    final deleteTaskLogUseCase = DeleteTaskLogUseCase(
      workoutLogRepository: workoutLogRepo,
      taskOccurrenceRepository: taskOccurrenceRepo,
      unitOfWork: unitOfWork,
    );

    final insertBlockUseCase = InsertBlockUseCase(logWriteExecutor);
    final appendBlockUseCase = AppendBlockUseCase(logWriteExecutor);
    final updateBlockUseCase = UpdateBlockUseCase(logWriteExecutor);
    final removeBlockUseCase = RemoveBlockUseCase(logWriteExecutor);
    final reorderBlocksUseCase = ReorderBlocksUseCase(logWriteExecutor);
    final taskTemplateOccurrenceSyncService = TaskTemplateOccurrenceSyncService(
      taskActivationRepository: taskActivationRepo,
      taskTemplateRepository: taskTemplateRepo,
      workoutLogRepository: workoutLogRepo,
      createWorkoutLogUseCase: createWorkoutLogUseCase,
    );

    return FitServiceHub(
      paths: paths,
      db: db,
      workoutLogRepository: workoutLogRepo,
      exerciseRepository: exerciseRepo,
      tagRepository: tagRepo,
      taskActivationRepository: taskActivationRepo,
      getHomeDashboardUseCase: getHomeDashboardUseCase,
      getExerciseCatalogCursorUseCase: getExerciseCatalogCursorUseCase,
      getTagCatalogCursorUseCase: getTagCatalogCursorUseCase,
      getWorkoutLogsByDateRangeUseCase: getWorkoutLogsByDateRangeUseCase,
      getCalendarSnapshotUseCase: getCalendarSnapshotUseCase,
      getTaskTemplatesUseCase: getTaskTemplatesUseCase,
      getTaskTemplateByIdUseCase: getTaskTemplateByIdUseCase,
      saveTaskTemplateUseCase: saveTaskTemplateUseCase,
      deleteTaskTemplateUseCase: deleteTaskTemplateUseCase,
      ensureTaskActivationUseCase: ensureTaskActivationUseCase,
      deleteTaskLogUseCase: deleteTaskLogUseCase,
      createWorkoutLogUseCase: createWorkoutLogUseCase,
      insertBlockUseCase: insertBlockUseCase,
      appendBlockUseCase: appendBlockUseCase,
      updateBlockUseCase: updateBlockUseCase,
      removeBlockUseCase: removeBlockUseCase,
      reorderBlocksUseCase: reorderBlocksUseCase,
      taskTemplateOccurrenceSyncService: taskTemplateOccurrenceSyncService,
    );
  }
}
