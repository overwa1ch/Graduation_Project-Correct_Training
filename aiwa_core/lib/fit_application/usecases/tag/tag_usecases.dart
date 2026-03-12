import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../../dtos/tag_dto.dart';
import '../../ports/id_generator.dart';
import '../../ports/repositories/exercise_repository.dart';
import '../../ports/repositories/tag_repository.dart';
import '../../ports/unit_of_work.dart';
import '../../ports/use_case.dart';
import '../../services/error_codes.dart';
import '../../services/mappers.dart';
import '../../services/not_found.dart';

// ---------------------------------------------------------------------------
// CreateTag
// ---------------------------------------------------------------------------

class CreateTagInput {
  final String name;

  const CreateTagInput({required this.name});
}

class CreateTagUseCase implements UseCase<CreateTagInput, TagDTO> {
  final TagRepository tagRepository;
  final IdGenerator idGenerator;

  const CreateTagUseCase({
    required this.tagRepository,
    required this.idGenerator,
  });

  @override
  Future<TagDTO> execute(CreateTagInput input) async {
    final tag = Tag(id: idGenerator.newId(), name: input.name);
    await tagRepository.save(tag);
    return ApplicationMappers.toTagDTO(tag);
  }
}

// ---------------------------------------------------------------------------
// RenameTag
// ---------------------------------------------------------------------------

class RenameTagInput {
  final String tagId;
  final String newName;

  const RenameTagInput({required this.tagId, required this.newName});
}

class RenameTagUseCase implements UseCase<RenameTagInput, TagDTO> {
  final TagRepository tagRepository;

  const RenameTagUseCase({required this.tagRepository});

  @override
  Future<TagDTO> execute(RenameTagInput input) async {
    final tag = requireFound(
      await tagRepository.findById(input.tagId),
      errorCode: AppErrorCodes.tagNotFound,
      message: 'Tag not found',
      context: <String, dynamic>{'tagId': input.tagId},
    );
    tag.rename(input.newName);
    await tagRepository.save(tag);
    return ApplicationMappers.toTagDTO(tag);
  }
}

// ---------------------------------------------------------------------------
// DeleteTag（强制 UoW，Spec §6.1）
// ---------------------------------------------------------------------------

class DeleteTagInput {
  final String tagId;

  const DeleteTagInput({required this.tagId});
}

class DeleteTagUseCase implements UseCase<DeleteTagInput, void> {
  final TagRepository tagRepository;
  final ExerciseRepository exerciseRepository;
  final UnitOfWork unitOfWork;

  const DeleteTagUseCase({
    required this.tagRepository,
    required this.exerciseRepository,
    required this.unitOfWork,
  });

  @override
  Future<void> execute(DeleteTagInput input) {
    return unitOfWork.runInTransaction(() async {
      requireFound(
        await tagRepository.findById(input.tagId),
        errorCode: AppErrorCodes.tagNotFound,
        message: 'Tag not found',
        context: <String, dynamic>{'tagId': input.tagId},
      );

      final exercises = await exerciseRepository.findAll();
      for (final exercise in exercises) {
        if (!exercise.tagIds.contains(input.tagId)) continue;
        exercise.removeTag(input.tagId);
        await exerciseRepository.save(exercise);
      }

      await tagRepository.delete(input.tagId);
    });
  }
}
