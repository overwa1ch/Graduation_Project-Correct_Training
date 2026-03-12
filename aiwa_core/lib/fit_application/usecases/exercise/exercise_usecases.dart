import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../../dtos/exercise_dto.dart';
import '../../ports/id_generator.dart';
import '../../ports/repositories/exercise_repository.dart';
import '../../ports/use_case.dart';
import '../../services/error_codes.dart';
import '../../services/mappers.dart';
import '../../services/not_found.dart';

// ---------------------------------------------------------------------------
// CreateExercise
// ---------------------------------------------------------------------------

class CreateExerciseInput {
  final String name;
  final List<String> tagIds;

  const CreateExerciseInput({required this.name, this.tagIds = const []});
}

class CreateExerciseUseCase
    implements UseCase<CreateExerciseInput, ExerciseDTO> {
  final ExerciseRepository exerciseRepository;
  final IdGenerator idGenerator;

  const CreateExerciseUseCase({
    required this.exerciseRepository,
    required this.idGenerator,
  });

  @override
  Future<ExerciseDTO> execute(CreateExerciseInput input) async {
    final exercise = Exercise(
      id: idGenerator.newId(),
      name: input.name,
      tagIds: input.tagIds,
      deprecated: false,
    );
    await exerciseRepository.save(exercise);
    return ApplicationMappers.toExerciseDTO(exercise);
  }
}

// ---------------------------------------------------------------------------
// RenameExercise
// ---------------------------------------------------------------------------

class RenameExerciseInput {
  final String exerciseId;
  final String newName;

  const RenameExerciseInput({required this.exerciseId, required this.newName});
}

class RenameExerciseUseCase
    implements UseCase<RenameExerciseInput, ExerciseDTO> {
  final ExerciseRepository exerciseRepository;

  const RenameExerciseUseCase({required this.exerciseRepository});

  @override
  Future<ExerciseDTO> execute(RenameExerciseInput input) async {
    final exercise = requireFound(
      await exerciseRepository.findById(input.exerciseId),
      errorCode: AppErrorCodes.exerciseNotFound,
      message: 'Exercise not found',
      context: <String, dynamic>{'exerciseId': input.exerciseId},
    );
    exercise.rename(input.newName);
    await exerciseRepository.save(exercise);
    return ApplicationMappers.toExerciseDTO(exercise);
  }
}

// ---------------------------------------------------------------------------
// DeprecateExercise
// ---------------------------------------------------------------------------

class DeprecateExerciseInput {
  final String exerciseId;
  final bool deprecated;

  const DeprecateExerciseInput({
    required this.exerciseId,
    this.deprecated = true,
  });
}

class DeprecateExerciseUseCase
    implements UseCase<DeprecateExerciseInput, ExerciseDTO> {
  final ExerciseRepository exerciseRepository;

  const DeprecateExerciseUseCase({required this.exerciseRepository});

  @override
  Future<ExerciseDTO> execute(DeprecateExerciseInput input) async {
    final exercise = requireFound(
      await exerciseRepository.findById(input.exerciseId),
      errorCode: AppErrorCodes.exerciseNotFound,
      message: 'Exercise not found',
      context: <String, dynamic>{'exerciseId': input.exerciseId},
    );
    exercise.setDeprecated(input.deprecated);
    await exerciseRepository.save(exercise);
    return ApplicationMappers.toExerciseDTO(exercise);
  }
}
