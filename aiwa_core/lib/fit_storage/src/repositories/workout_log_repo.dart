import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../db/fit_database.dart';
import '../utils/json_codec.dart';
import '../utils/repository_codec.dart';
import '../utils/utc_codec.dart';

class DriftWorkoutLogRepository implements WorkoutLogRepository {
  final FitDatabase db;

  const DriftWorkoutLogRepository(this.db);

  @override
  Future<domain.WorkoutLog?> findById(domain.LogId id) async {
    final row = await (db.select(db.workoutLogs)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _toDomain(row);
  }

  @override
  Future<List<domain.WorkoutLog>> findByDate(domain.DateOnly date) async {
    final rows = await (db.select(db.workoutLogs)
          ..where((t) => t.date.equals(date.toString()))
          ..orderBy(<OrderingTerm Function(WorkoutLogs)>[
            (t) => OrderingTerm.asc(t.createdAtUtc),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<domain.WorkoutLog>> findAll() async {
    final rows = await (db.select(db.workoutLogs)
          ..orderBy(<OrderingTerm Function(WorkoutLogs)>[
            (t) => OrderingTerm.desc(t.date),
            (t) => OrderingTerm.desc(t.createdAtUtc),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<List<domain.WorkoutLog>> findByDateRange({
    required domain.DateOnly from,
    required domain.DateOnly to,
    int? limit,
    int? offset,
  }) async {
    final query = db.select(db.workoutLogs)
      ..where((t) =>
          t.date.isBiggerOrEqualValue(from.toString()) &
          t.date.isSmallerOrEqualValue(to.toString()))
      ..orderBy(<OrderingTerm Function(WorkoutLogs)>[
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAtUtc),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (limit != null) query.limit(limit, offset: offset);
    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<CursorPage<domain.WorkoutLog>> findByDateRangeCursor({
    required domain.DateOnly from,
    required domain.DateOnly to,
    required int pageSize,
    WorkoutLogCursorKey? cursorKey,
  }) async {
    final fetchSize = pageSize + 1;

    final query = db.select(db.workoutLogs)
      ..where((t) {
        final rangeFilter = t.date.isBiggerOrEqualValue(from.toString()) &
            t.date.isSmallerOrEqualValue(to.toString());

        if (cursorKey == null) return rangeFilter;

        final k = cursorKey;
        // Keyset condition: strictly "after" in sort order (date DESC, createdAtUtc DESC, id ASC)
        final keyFilter = t.date.isSmallerThanValue(k.date) |
            (t.date.equals(k.date) &
                t.createdAtUtc.isSmallerThanValue(k.createdAtUtc)) |
            (t.date.equals(k.date) &
                t.createdAtUtc.equals(k.createdAtUtc) &
                t.id.isBiggerThanValue(k.id));

        return rangeFilter & keyFilter;
      })
      ..orderBy(<OrderingTerm Function(WorkoutLogs)>[
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAtUtc),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(fetchSize);

    final rows = await query.get();
    final hasMore = rows.length > pageSize;
    final pageRows = hasMore ? rows.sublist(0, pageSize) : rows;
    final items = pageRows.map(_toDomain).toList(growable: false);

    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeWorkoutLog(WorkoutLogCursorKey(
        date: last.date.toString(),
        createdAtUtc: last.createdAtUtc.toIso8601String(),
        id: last.id,
      ));
    }

    return CursorPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<CursorPage<DailyCountRow>> countByDateRangeCursor({
    required domain.DateOnly from,
    required domain.DateOnly to,
    required int pageSize,
    domain.DateOnly? cursorDate,
  }) async {
    final fetchSize = pageSize + 1;

    String sql;
    List<Variable<Object>> args;

    if (cursorDate == null) {
      sql = '''
        SELECT date, COUNT(*) AS cnt
        FROM workout_logs
        WHERE date >= ? AND date <= ?
        GROUP BY date
        ORDER BY date DESC
        LIMIT ?
      ''';
      args = [
        Variable<String>(from.toString()),
        Variable<String>(to.toString()),
        Variable<int>(fetchSize),
      ];
    } else {
      sql = '''
        SELECT date, COUNT(*) AS cnt
        FROM workout_logs
        WHERE date >= ? AND date <= ? AND date < ?
        GROUP BY date
        ORDER BY date DESC
        LIMIT ?
      ''';
      args = [
        Variable<String>(from.toString()),
        Variable<String>(to.toString()),
        Variable<String>(cursorDate.toString()),
        Variable<int>(fetchSize),
      ];
    }

    final rows = await db.customSelect(sql, variables: args).get();
    final hasMore = rows.length > pageSize;
    final pageRows = hasMore ? rows.sublist(0, pageSize) : rows;

    final items = pageRows
        .map((row) => DailyCountRow(
              date: domain.DateOnly.parse(row.read<String>('date')),
              count: row.read<int>('cnt'),
            ))
        .toList(growable: false);

    return CursorPage(items: items, nextCursor: null);
  }

  @override
  Future<void> save(domain.WorkoutLog log) async {
    final json = encodeJson(encodeDomainJson(log.toJson()), fieldName: 'json');
    try {
      await db.into(db.workoutLogs).insertOnConflictUpdate(
            WorkoutLogsCompanion(
              id: Value<String>(log.id),
              date: Value<String>(log.date.toString()),
              boundTaskOccurrenceId: Value<String?>(log.boundTaskOccurrenceId),
              createdAtUtc: Value<String>(
                encodeUtc(log.createdAtUtc, fieldName: 'createdAtUtc'),
              ),
              lastEditedAtUtc: Value<String>(
                encodeUtc(log.lastEditedAtUtc, fieldName: 'lastEditedAtUtc'),
              ),
              json: Value<String>(json),
            ),
          );
    } catch (error) {
      throwIfConstraint(error,
          context: <String, Object?>{'table': 'workout_logs'});
    }
  }

  @override
  Future<void> delete(domain.LogId id) async {
    await (db.delete(db.workoutLogs)..where((t) => t.id.equals(id))).go();
  }

  domain.WorkoutLog _toDomain(WorkoutLog row) {
    final payload = decodeJsonObject(row.json, fieldName: 'workout_logs.json');
    final boundTaskOccurrenceId = row.boundTaskOccurrenceId ??
        payload['boundTaskOccurrenceId'] as String?;
    payload['boundTaskOccurrenceId'] = boundTaskOccurrenceId;
    final parsed = domain.WorkoutLog.fromJson(payload);

    // Validate indexed UTC fields remain strict UTC with trailing Z.
    decodeUtc(row.createdAtUtc, fieldName: 'workout_logs.created_at_utc');
    decodeUtc(
      row.lastEditedAtUtc,
      fieldName: 'workout_logs.last_edited_at_utc',
    );

    return parsed;
  }
}
