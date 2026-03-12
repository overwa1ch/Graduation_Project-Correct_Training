import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../db/fit_database.dart';
import '../utils/json_codec.dart';
import '../utils/repository_codec.dart';
import '../utils/utc_codec.dart';

class DriftTaskActivationRepository implements TaskActivationRepository {
  final FitDatabase db;

  const DriftTaskActivationRepository(this.db);

  @override
  Future<domain.TaskActivation?> findById(domain.TaskActivationId id) async {
    final row = await (db.select(db.taskActivations)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row);
  }

  @override
  Future<List<domain.TaskActivation>> findAll() async {
    final rows = await (db.select(db.taskActivations)
          ..orderBy(<OrderingTerm Function(TaskActivations)>[
            (t) => OrderingTerm.desc(t.startDate),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    final result = <domain.TaskActivation>[];
    for (final row in rows) {
      result.add(await _toDomain(row));
    }
    return result;
  }

  @override
  Future<void> save(domain.TaskActivation activation) async {
    final activationJson =
        encodeJson(encodeDomainJson(activation.toJson()), fieldName: 'json');

    try {
      await db.transaction(() async {
        await db.into(db.taskActivations).insertOnConflictUpdate(
              TaskActivationsCompanion(
                id: Value<String>(activation.id),
                templateId: Value<String>(activation.templateId),
                startDate: Value<String>(activation.startDate.toString()),
                createdAtUtc: Value<String>(
                  encodeUtc(activation.createdAtUtc, fieldName: 'createdAtUtc'),
                ),
                json: Value<String>(activationJson),
              ),
            );

        await (db.delete(db.taskOccurrences)
              ..where((t) => t.activationId.equals(activation.id)))
            .go();

        for (final occurrence in activation.occurrences) {
          final occurrenceJson = encodeJson(
            encodeDomainJson(occurrence.toJson()),
            fieldName: 'json',
          );
          await db.into(db.taskOccurrences).insert(
                TaskOccurrencesCompanion(
                  id: Value<String>(occurrence.id),
                  activationId: Value<String>(activation.id),
                  date: Value<String>(occurrence.date.toString()),
                  boundLogId: Value<String?>(occurrence.boundLogId),
                  suppressed: Value<bool>(occurrence.suppressed),
                  json: Value<String>(occurrenceJson),
                ),
              );
        }
      });
    } catch (error) {
      throwIfConstraint(
        error,
        context: <String, Object?>{'table': 'task_activations'},
      );
    }
  }

  @override
  Future<void> delete(domain.TaskActivationId id) async {
    await db.transaction(() async {
      await (db.delete(db.taskOccurrences)
            ..where((t) => t.activationId.equals(id)))
          .go();
      await (db.delete(db.taskActivations)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<domain.TaskActivation> _toDomain(TaskActivation row) async {
    decodeUtc(row.createdAtUtc, fieldName: 'task_activations.created_at_utc');
    final occurrenceRows = await (db.select(db.taskOccurrences)
          ..where((t) => t.activationId.equals(row.id))
          ..orderBy(<OrderingTerm Function(TaskOccurrences)>[
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();

    return domain.TaskActivation(
      id: row.id,
      templateId: row.templateId,
      startDate: domain.DateOnly.parse(row.startDate),
      occurrences: occurrenceRows
          .map(
            (occurrence) => domain.TaskOccurrence(
              id: occurrence.id,
              date: domain.DateOnly.parse(occurrence.date),
              boundLogId: occurrence.boundLogId,
              suppressed: occurrence.suppressed,
            ),
          )
          .toList(growable: false),
      createdAtUtc: decodeUtc(
        row.createdAtUtc,
        fieldName: 'task_activations.created_at_utc',
      ),
    );
  }
}
