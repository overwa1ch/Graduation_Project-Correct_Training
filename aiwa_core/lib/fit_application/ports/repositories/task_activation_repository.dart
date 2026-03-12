import 'package:aiwa_core/fit_domain/fit_domain.dart';

abstract interface class TaskActivationRepository {
  Future<TaskActivation?> findById(TaskActivationId id);
  Future<List<TaskActivation>> findAll();
  Future<void> save(TaskActivation activation);
  Future<void> delete(TaskActivationId id);
}
