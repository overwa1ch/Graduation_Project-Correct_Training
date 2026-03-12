import '../../ports/repositories/exercise_repository.dart';
import '../../ports/repositories/tag_repository.dart';
import '../../ports/unit_of_work.dart';
import '../../services/error_codes.dart';
import '../../services/not_found.dart';

class DeleteTagInput {
  final String tagId;

  const DeleteTagInput({
    required this.tagId,
  });
}

class DeleteTagUseCase {
  final TagRepository tagRepository;
  final ExerciseRepository exerciseRepository;
  final UnitOfWork unitOfWork;

  const DeleteTagUseCase({
    required this.tagRepository,
    required this.exerciseRepository,
    required this.unitOfWork,
  });

  Future<void> execute(DeleteTagInput input) async {
    await unitOfWork.runInTransaction(() async {
      final tag = requireFound(
        await tagRepository.findById(input.tagId),
        errorCode: AppErrorCodes.tagNotFound,
        message: 'Tag not found',
        context: <String, dynamic>{'tagId': input.tagId},
      );
      await tagRepository.delete(tag.id);

      final exercises = await exerciseRepository.findAll();
      for (final exercise in exercises) {
        if (!exercise.tagIds.contains(input.tagId)) {
          continue;
        }
        exercise.removeTag(input.tagId);
        await exerciseRepository.save(exercise);
      }
    });
  }
}
