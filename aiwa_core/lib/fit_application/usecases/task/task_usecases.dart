import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../../ports/clock.dart';
import '../../ports/id_generator.dart';
import '../../ports/repositories/task_activation_repository.dart';
import '../../ports/repositories/task_occurrence_repository.dart';
import '../../ports/repositories/task_template_repository.dart';
import '../../ports/repositories/workout_log_repository.dart';
import '../../ports/unit_of_work.dart';
import '../../ports/use_case.dart';
import '../../services/error_codes.dart';
import '../../services/not_found.dart';

class NoInput {
  const NoInput();
}

class GetTaskTemplatesUseCase implements UseCase<NoInput, List<TaskTemplate>> {
  final TaskTemplateRepository taskTemplateRepository;

  const GetTaskTemplatesUseCase({required this.taskTemplateRepository});

  @override
  Future<List<TaskTemplate>> execute(NoInput input) {
    return taskTemplateRepository.findAll();
  }
}

class GetTaskTemplateByIdUseCase
    implements UseCase<TaskTemplateId, TaskTemplate?> {
  final TaskTemplateRepository taskTemplateRepository;

  const GetTaskTemplateByIdUseCase({required this.taskTemplateRepository});

  @override
  Future<TaskTemplate?> execute(TaskTemplateId input) {
    return taskTemplateRepository.findById(input);
  }
}

class SaveTaskTemplateUseCase implements UseCase<TaskTemplate, void> {
  final TaskTemplateRepository taskTemplateRepository;

  const SaveTaskTemplateUseCase({required this.taskTemplateRepository});

  @override
  Future<void> execute(TaskTemplate input) {
    return taskTemplateRepository.save(input);
  }
}

class DeleteTaskTemplateUseCase implements UseCase<TaskTemplateId, void> {
  final TaskTemplateRepository taskTemplateRepository;

  const DeleteTaskTemplateUseCase({required this.taskTemplateRepository});

  @override
  Future<void> execute(TaskTemplateId input) {
    return taskTemplateRepository.delete(input);
  }
}

class EnsureTaskActivationInput {
  final TaskTemplateId templateId;
  final DateOnly startDate;

  const EnsureTaskActivationInput({
    required this.templateId,
    required this.startDate,
  });
}

class EnsureTaskActivationUseCase
    implements UseCase<EnsureTaskActivationInput, TaskActivation> {
  final TaskActivationRepository taskActivationRepository;
  final Clock clock;
  final IdGenerator idGenerator;

  const EnsureTaskActivationUseCase({
    required this.taskActivationRepository,
    required this.clock,
    required this.idGenerator,
  });

  @override
  Future<TaskActivation> execute(EnsureTaskActivationInput input) async {
    final activations = await taskActivationRepository.findAll();
    for (final activation in activations) {
      if (activation.templateId == input.templateId) {
        return activation;
      }
    }
    final created = TaskActivation(
      id: 'task_activation_${idGenerator.newId()}',
      templateId: input.templateId,
      startDate: input.startDate,
      occurrences: const <TaskOccurrence>[],
      createdAtUtc: clock.nowUtc().toUtc(),
    );
    await taskActivationRepository.save(created);
    return created;
  }
}

class DeleteTaskLogInput {
  final LogId logId;
  final TaskOccurrenceId? taskOccurrenceId;

  const DeleteTaskLogInput({
    required this.logId,
    this.taskOccurrenceId,
  });
}

class DeleteTaskLogUseCase implements UseCase<DeleteTaskLogInput, void> {
  final WorkoutLogRepository workoutLogRepository;
  final TaskOccurrenceRepository taskOccurrenceRepository;
  final UnitOfWork unitOfWork;

  const DeleteTaskLogUseCase({
    required this.workoutLogRepository,
    required this.taskOccurrenceRepository,
    required this.unitOfWork,
  });

  @override
  Future<void> execute(DeleteTaskLogInput input) {
    return unitOfWork.runInTransaction(() async {
      if (input.taskOccurrenceId != null) {
        final occurrence = requireFound(
          await taskOccurrenceRepository.findById(input.taskOccurrenceId!),
          errorCode: AppErrorCodes.taskOccurrenceNotFound,
          message: 'TaskOccurrence not found',
          context: <String, dynamic>{
            'taskOccurrenceId': input.taskOccurrenceId,
          },
        );
        if (occurrence.boundLogId == input.logId) {
          await taskOccurrenceRepository.save(
            occurrence.copyWith(boundLogId: null, suppressed: true),
          );
        }
      }
      await workoutLogRepository.delete(input.logId);
    });
  }
}
