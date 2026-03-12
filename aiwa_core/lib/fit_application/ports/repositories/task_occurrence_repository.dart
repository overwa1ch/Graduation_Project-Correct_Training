import 'package:aiwa_core/fit_domain/fit_domain.dart';

abstract interface class TaskOccurrenceRepository {
  Future<TaskOccurrence?> findById(TaskOccurrenceId id);
  Future<void> save(TaskOccurrence occurrence);
}
