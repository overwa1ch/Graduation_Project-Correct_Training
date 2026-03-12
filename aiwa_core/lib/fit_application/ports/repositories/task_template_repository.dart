import 'package:aiwa_core/fit_domain/fit_domain.dart';

abstract interface class TaskTemplateRepository {
  Future<TaskTemplate?> findById(TaskTemplateId id);
  Future<List<TaskTemplate>> findAll();
  Future<void> save(TaskTemplate template);
  Future<void> delete(TaskTemplateId id);
}
