import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../../dtos/block_dto.dart';
import '../../dtos/log_editor_dto.dart';
import '../../ports/clock.dart';
import '../../ports/id_generator.dart';
import '../../ports/repositories/workout_log_repository.dart';
import '../../ports/unit_of_work.dart';
import '../../ports/use_case.dart';
import '../../services/application_exception.dart';
import '../../services/log_write_executor.dart';
import '../../services/mappers.dart';

class CreateWorkoutLogInput {
  final String date;
  final String? boundTaskOccurrenceId;
  final Map<String, dynamic> metadata;
  final List<BlockDTO> blocks;

  const CreateWorkoutLogInput({
    required this.date,
    this.boundTaskOccurrenceId,
    this.metadata = const <String, dynamic>{},
    this.blocks = const [],
  });
}

class CreateWorkoutLogUseCase
    implements UseCase<CreateWorkoutLogInput, LogEditorDTO> {
  final WorkoutLogRepository logRepository;
  final UnitOfWork unitOfWork;
  final Clock clock;
  final IdGenerator idGenerator;

  const CreateWorkoutLogUseCase({
    required this.logRepository,
    required this.unitOfWork,
    required this.clock,
    required this.idGenerator,
  });

  @override
  Future<LogEditorDTO> execute(CreateWorkoutLogInput input) {
    return unitOfWork.runInTransaction(() async {
      final nowUtc = clock.nowUtc();
      requireClockUtc(nowUtc);

      final log = WorkoutLog(
        id: idGenerator.newId(),
        date: DateOnly.parse(input.date),
        createdAtUtc: nowUtc,
        lastEditedAtUtc: nowUtc,
        metadata: input.metadata,
        blocks: input.blocks.map(ApplicationMappers.toDomainBlock).toList(),
      );

      if (input.boundTaskOccurrenceId != null) {
        log.bindTaskOccurrence(input.boundTaskOccurrenceId!, nowUtc);
      }

      await logRepository.save(log);
      return ApplicationMappers.toLogEditorDTO(log);
    });
  }
}

class InsertBlockInput {
  final String logId;
  final int position;
  final BlockDTO block;

  const InsertBlockInput({
    required this.logId,
    required this.position,
    required this.block,
  });
}

class InsertBlockUseCase implements UseCase<InsertBlockInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const InsertBlockUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(InsertBlockInput input) => executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) => log.insertBlock(
          input.position,
          ApplicationMappers.toDomainBlock(input.block),
          nowUtc,
        ),
      );
}

class AppendBlockInput {
  final String logId;
  final BlockDTO block;

  const AppendBlockInput({required this.logId, required this.block});
}

class AppendBlockUseCase implements UseCase<AppendBlockInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const AppendBlockUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(AppendBlockInput input) => executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) => log.appendBlock(
          ApplicationMappers.toDomainBlock(input.block),
          nowUtc,
        ),
      );
}

class UpdateBlockInput {
  final String logId;
  final String blockId;
  final BlockDTO block;

  const UpdateBlockInput({
    required this.logId,
    required this.blockId,
    required this.block,
  });
}

class UpdateBlockUseCase implements UseCase<UpdateBlockInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const UpdateBlockUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(UpdateBlockInput input) => executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) => log.updateBlock(
          input.blockId,
          ApplicationMappers.toDomainBlock(input.block),
          nowUtc,
        ),
      );
}

class RemoveBlockInput {
  final String logId;
  final String blockId;

  const RemoveBlockInput({required this.logId, required this.blockId});
}

class RemoveBlockUseCase implements UseCase<RemoveBlockInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const RemoveBlockUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(RemoveBlockInput input) => executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) => log.removeBlock(input.blockId, nowUtc),
      );
}

class ReorderBlocksInput {
  final String logId;
  final int fromIndex;
  final int toIndex;

  const ReorderBlocksInput({
    required this.logId,
    required this.fromIndex,
    required this.toIndex,
  });
}

class ReorderBlocksUseCase
    implements UseCase<ReorderBlocksInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const ReorderBlocksUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(ReorderBlocksInput input) => executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) =>
            log.reorderBlocks(input.fromIndex, input.toIndex, nowUtc),
      );
}

class ToggleChecklistItemInput {
  final String logId;
  final String blockId;
  final int index;

  const ToggleChecklistItemInput({
    required this.logId,
    required this.blockId,
    required this.index,
  });
}

class ToggleChecklistItemUseCase
    implements UseCase<ToggleChecklistItemInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const ToggleChecklistItemUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(ToggleChecklistItemInput input) =>
      executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) =>
            log.toggleChecklistItem(input.blockId, input.index, nowUtc),
      );
}

class AddChecklistItemInput {
  final String logId;
  final String blockId;
  final String text;

  const AddChecklistItemInput({
    required this.logId,
    required this.blockId,
    required this.text,
  });
}

class AddChecklistItemUseCase
    implements UseCase<AddChecklistItemInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const AddChecklistItemUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(AddChecklistItemInput input) => executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) =>
            log.addChecklistItem(input.blockId, input.text, nowUtc),
      );
}

class RemoveChecklistItemInput {
  final String logId;
  final String blockId;
  final int index;

  const RemoveChecklistItemInput({
    required this.logId,
    required this.blockId,
    required this.index,
  });
}

class RemoveChecklistItemUseCase
    implements UseCase<RemoveChecklistItemInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const RemoveChecklistItemUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(RemoveChecklistItemInput input) =>
      executor.execute(
        logId: input.logId,
        mutation: (log, nowUtc) =>
            log.removeChecklistItem(input.blockId, input.index, nowUtc),
      );
}

class AddSetInput {
  final String logId;
  final String blockId;
  final SetRecordDTO set;

  const AddSetInput({
    required this.logId,
    required this.blockId,
    required this.set,
  });
}

class AddSetUseCase implements UseCase<AddSetInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const AddSetUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(AddSetInput input) => executor.execute(
        logId: input.logId,
        triggerMilestone: true,
        mutation: (log, nowUtc) => log.addSet(
          input.blockId,
          ApplicationMappers.toDomainSet(input.set),
          nowUtc,
        ),
      );
}

class UpdateSetInput {
  final String logId;
  final String blockId;
  final int setIndex;
  final SetRecordDTO set;

  const UpdateSetInput({
    required this.logId,
    required this.blockId,
    required this.setIndex,
    required this.set,
  });
}

class UpdateSetUseCase implements UseCase<UpdateSetInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const UpdateSetUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(UpdateSetInput input) => executor.execute(
        logId: input.logId,
        triggerMilestone: true,
        mutation: (log, nowUtc) => log.updateSet(
          input.blockId,
          input.setIndex,
          ApplicationMappers.toDomainSet(input.set),
          nowUtc,
        ),
      );
}

class RemoveSetInput {
  final String logId;
  final String blockId;
  final int setIndex;

  const RemoveSetInput({
    required this.logId,
    required this.blockId,
    required this.setIndex,
  });
}

class RemoveSetUseCase implements UseCase<RemoveSetInput, LogEditorDTO> {
  final LogWriteExecutor executor;

  const RemoveSetUseCase(this.executor);

  @override
  Future<LogEditorDTO> execute(RemoveSetInput input) => executor.execute(
        logId: input.logId,
        triggerMilestone: true,
        mutation: (log, nowUtc) =>
            log.removeSet(input.blockId, input.setIndex, nowUtc),
      );
}
