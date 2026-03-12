import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../db/fit_database.dart';
import '../utils/json_codec.dart';
import '../utils/repository_codec.dart';

class DriftTaskTemplateRepository implements TaskTemplateRepository {
  final FitDatabase db;

  const DriftTaskTemplateRepository(this.db);

  @override
  Future<domain.TaskTemplate?> findById(domain.TaskTemplateId id) async {
    final row = await (db.select(db.taskTemplates)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return decodeDomainJson<domain.TaskTemplate>(
      row.json,
      domain.TaskTemplate.fromJson,
      entity: 'task_templates',
    );
  }

  @override
  Future<List<domain.TaskTemplate>> findAll() async {
    final rows = await (db.select(db.taskTemplates)
          ..orderBy(<OrderingTerm Function(TaskTemplates)>[
            (t) => OrderingTerm.asc(t.title),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    return rows
        .map(
          (row) => decodeDomainJson<domain.TaskTemplate>(
            row.json,
            domain.TaskTemplate.fromJson,
            entity: 'task_templates',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(domain.TaskTemplate template) async {
    final json =
        encodeJson(encodeDomainJson(template.toJson()), fieldName: 'json');
    await db.into(db.taskTemplates).insertOnConflictUpdate(
          TaskTemplatesCompanion(
            id: Value<String>(template.id),
            title: Value<String>(template.title),
            description: Value<String?>(template.description),
            json: Value<String>(json),
          ),
        );
  }

  @override
  Future<void> delete(domain.TaskTemplateId id) async {
    await (db.delete(db.taskTemplates)..where((t) => t.id.equals(id))).go();
  }
}
