import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../db/fit_database.dart';
import '../utils/json_codec.dart';
import '../utils/repository_codec.dart';

class DriftExerciseRepository implements ExerciseRepository {
  final FitDatabase db;

  const DriftExerciseRepository(this.db);

  @override
  Future<domain.Exercise?> findById(domain.ExerciseId id) async {
    final row = await (db.select(db.exercises)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return decodeDomainJson<domain.Exercise>(
      row.json,
      domain.Exercise.fromJson,
      entity: 'exercises',
    );
  }

  @override
  Future<List<domain.Exercise>> findAll() async {
    final rows = await (db.select(db.exercises)
          ..orderBy(<OrderingTerm Function(Exercises)>[
            (t) => OrderingTerm.asc(t.deprecated),
            (t) => OrderingTerm.asc(t.name),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();

    return rows
        .map(
          (row) => decodeDomainJson<domain.Exercise>(
            row.json,
            domain.Exercise.fromJson,
            entity: 'exercises',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(domain.Exercise exercise) async {
    final json =
        encodeJson(encodeDomainJson(exercise.toJson()), fieldName: 'json');

    try {
      await db.into(db.exercises).insertOnConflictUpdate(
            ExercisesCompanion(
              id: Value<String>(exercise.id),
              name: Value<String>(exercise.name),
              deprecated: Value<int>(exercise.deprecated ? 1 : 0),
              json: Value<String>(json),
            ),
          );
    } catch (error) {
      throwIfConstraint(error,
          context: <String, Object?>{'table': 'exercises'});
    }
  }

  @override
  Future<CursorPage<domain.Exercise>> searchCatalogCursor({
    String? keyword,
    bool includeDeprecated = false,
    required int pageSize,
    ExerciseCatalogCursorKey? cursorKey,
  }) async {
    final fetchSize = pageSize + 1;

    final conditions = <String>[];
    final args = <Variable<Object>>[];

    // Keyword filter
    if (keyword != null && keyword.isNotEmpty) {
      conditions.add("lower(name) LIKE ?");
      args.add(Variable<String>('%${keyword.toLowerCase()}%'));
    }

    // Deprecated filter
    if (!includeDeprecated) {
      conditions.add('deprecated = 0');
    }

    // Keyset condition
    if (cursorKey != null) {
      final k = cursorKey;
      conditions.add(
        '(deprecated > ? OR (deprecated = ? AND lower(name) > ?) OR '
        '(deprecated = ? AND lower(name) = ? AND id > ?))',
      );
      args.addAll([
        Variable<int>(k.deprecated),
        Variable<int>(k.deprecated),
        Variable<String>(k.nameNormalized),
        Variable<int>(k.deprecated),
        Variable<String>(k.nameNormalized),
        Variable<String>(k.id),
      ]);
    }

    final whereClause =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final sql = '''
      SELECT id, name, deprecated, json
      FROM exercises
      $whereClause
      ORDER BY deprecated ASC, lower(name) ASC, id ASC
      LIMIT ?
    ''';

    args.add(Variable<int>(fetchSize));

    final rows = await db.customSelect(sql, variables: args).get();
    final hasMore = rows.length > pageSize;
    final pageRows = hasMore ? rows.sublist(0, pageSize) : rows;

    final items = pageRows
        .map((row) => decodeDomainJson<domain.Exercise>(
              row.read<String>('json'),
              domain.Exercise.fromJson,
              entity: 'exercises',
            ))
        .toList(growable: false);

    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeExerciseCatalog(ExerciseCatalogCursorKey(
        deprecated: last.deprecated ? 1 : 0,
        nameNormalized: last.name.toLowerCase(),
        id: last.id,
      ));
    }

    return CursorPage(items: items, nextCursor: nextCursor);
  }
}
