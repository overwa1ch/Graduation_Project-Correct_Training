import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../db/fit_database.dart';
import '../errors/storage_exception.dart';
import '../utils/json_codec.dart';
import '../utils/repository_codec.dart';

class DriftTaskOccurrenceRepository implements TaskOccurrenceRepository {
  final FitDatabase db;

  const DriftTaskOccurrenceRepository(this.db);

  @override
  Future<domain.TaskOccurrence?> findById(domain.TaskOccurrenceId id) async {
    final row = await (db.select(db.taskOccurrences)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return domain.TaskOccurrence(
      id: row.id,
      date: domain.DateOnly.parse(row.date),
      boundLogId: row.boundLogId,
      suppressed: row.suppressed,
    );
  }

  @override
  Future<void> save(domain.TaskOccurrence occurrence) async {
    final existing = await (db.select(db.taskOccurrences)
          ..where((t) => t.id.equals(occurrence.id)))
        .getSingleOrNull();
    if (existing == null) {
      throw const StorageException(
        errorCode: StorageException.dbConstraintViolation,
        message: 'TaskOccurrence update requires an existing row',
      );
    }

    final json =
        encodeJson(encodeDomainJson(occurrence.toJson()), fieldName: 'json');
    final affected = await (db.update(db.taskOccurrences)
          ..where((t) => t.id.equals(occurrence.id)))
        .write(
      TaskOccurrencesCompanion(
        date: Value<String>(occurrence.date.toString()),
        boundLogId: Value<String?>(occurrence.boundLogId),
        suppressed: Value<bool>(occurrence.suppressed),
        json: Value<String>(json),
      ),
    );
    if (affected == 0) {
      throw const StorageException(
        errorCode: StorageException.dbConstraintViolation,
        message: 'TaskOccurrence update failed',
      );
    }
  }
}
