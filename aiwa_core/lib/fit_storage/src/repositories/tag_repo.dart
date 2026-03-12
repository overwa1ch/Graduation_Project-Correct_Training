import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../db/fit_database.dart';
import '../utils/json_codec.dart';
import '../utils/repository_codec.dart';

class DriftTagRepository implements TagRepository {
  final FitDatabase db;

  const DriftTagRepository(this.db);

  @override
  Future<domain.Tag?> findById(domain.TagId id) async {
    final row = await (db.select(db.tags)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return decodeDomainJson<domain.Tag>(
      row.json,
      domain.Tag.fromJson,
      entity: 'tags',
    );
  }

  @override
  Future<List<domain.Tag>> findAll() async {
    final rows = await (db.select(db.tags)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows
        .map(
          (row) => decodeDomainJson<domain.Tag>(
            row.json,
            domain.Tag.fromJson,
            entity: 'tags',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> save(domain.Tag tag) async {
    final json = encodeJson(encodeDomainJson(tag.toJson()), fieldName: 'json');
    try {
      await db.into(db.tags).insertOnConflictUpdate(
            TagsCompanion(
              id: Value<String>(tag.id),
              name: Value<String>(tag.name),
              json: Value<String>(json),
            ),
          );
    } catch (error) {
      throwIfConstraint(error, context: <String, Object?>{'table': 'tags'});
    }
  }

  @override
  Future<void> delete(domain.TagId id) async {
    await (db.delete(db.tags)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<CursorPage<domain.Tag>> searchCatalogCursor({
    String? keyword,
    required int pageSize,
    TagCatalogCursorKey? cursorKey,
  }) async {
    final fetchSize = pageSize + 1;

    final conditions = <String>[];
    final args = <Variable<Object>>[];

    // Keyword filter
    if (keyword != null && keyword.isNotEmpty) {
      conditions.add("lower(name) LIKE ?");
      args.add(Variable<String>('%${keyword.toLowerCase()}%'));
    }

    // Keyset condition
    if (cursorKey != null) {
      final k = cursorKey;
      conditions.add('(lower(name) > ? OR (lower(name) = ? AND id > ?))');
      args.addAll([
        Variable<String>(k.nameNormalized),
        Variable<String>(k.nameNormalized),
        Variable<String>(k.id),
      ]);
    }

    final whereClause =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final sql = '''
      SELECT id, name, json
      FROM tags
      $whereClause
      ORDER BY lower(name) ASC, id ASC
      LIMIT ?
    ''';

    args.add(Variable<int>(fetchSize));

    final rows = await db.customSelect(sql, variables: args).get();
    final hasMore = rows.length > pageSize;
    final pageRows = hasMore ? rows.sublist(0, pageSize) : rows;

    final items = pageRows
        .map((row) => decodeDomainJson<domain.Tag>(
              row.read<String>('json'),
              domain.Tag.fromJson,
              entity: 'tags',
            ))
        .toList(growable: false);

    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeTagCatalog(TagCatalogCursorKey(
        nameNormalized: last.name.toLowerCase(),
        id: last.id,
      ));
    }

    return CursorPage(items: items, nextCursor: nextCursor);
  }
}
