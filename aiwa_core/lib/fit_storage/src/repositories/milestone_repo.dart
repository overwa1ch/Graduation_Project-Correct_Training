import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart' as domain;
import 'package:drift/drift.dart';

import '../db/fit_database.dart';
import '../utils/json_codec.dart';
import '../utils/repository_codec.dart';
import '../utils/utc_codec.dart';

class DriftMilestoneRepository implements MilestoneRepository {
  final FitDatabase db;

  const DriftMilestoneRepository(this.db);

  @override
  Future<domain.MilestoneEvent?> findByDedupKey(String dedupKey) async {
    final row = await (db.select(db.milestones)
          ..where((t) => t.dedupKey.equals(dedupKey)))
        .getSingleOrNull();
    if (row == null) return null;

    decodeUtc(row.createdAtUtc, fieldName: 'milestones.created_at_utc');
    if (row.deletedAtUtc != null) {
      decodeUtc(row.deletedAtUtc!, fieldName: 'milestones.deleted_at_utc');
    }

    return decodeDomainJson<domain.MilestoneEvent>(
      row.json,
      domain.MilestoneEvent.fromJson,
      entity: 'milestones',
    );
  }

  @override
  Future<List<domain.MilestoneEvent>> findByCreatedAtUtcRange({
    required DateTime fromUtc,
    required DateTime toUtc,
    int? limit,
    int? offset,
  }) async {
    final fromStr = encodeUtc(fromUtc, fieldName: 'fromUtc');
    final toStr = encodeUtc(toUtc, fieldName: 'toUtc');
    final query = db.select(db.milestones)
      ..where((t) =>
          t.createdAtUtc.isBiggerOrEqualValue(fromStr) &
          t.createdAtUtc.isSmallerOrEqualValue(toStr))
      ..orderBy(<OrderingTerm Function(Milestones)>[
        (t) => OrderingTerm.desc(t.createdAtUtc),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (limit != null) query.limit(limit, offset: offset);
    final rows = await query.get();
    return rows.map((row) {
      decodeUtc(row.createdAtUtc, fieldName: 'milestones.created_at_utc');
      if (row.deletedAtUtc != null) {
        decodeUtc(row.deletedAtUtc!, fieldName: 'milestones.deleted_at_utc');
      }
      return decodeDomainJson<domain.MilestoneEvent>(
        row.json,
        domain.MilestoneEvent.fromJson,
        entity: 'milestones',
      );
    }).toList(growable: false);
  }

  @override
  Future<CursorPage<domain.MilestoneEvent>> findByCreatedAtUtcRangeCursor({
    required DateTime fromUtc,
    required DateTime toUtc,
    required int pageSize,
    MilestoneCursorKey? cursorKey,
  }) async {
    final fetchSize = pageSize + 1;
    final fromStr = encodeUtc(fromUtc, fieldName: 'fromUtc');
    final toStr = encodeUtc(toUtc, fieldName: 'toUtc');

    final query = db.select(db.milestones)
      ..where((t) {
        final rangeFilter = t.createdAtUtc.isBiggerOrEqualValue(fromStr) &
            t.createdAtUtc.isSmallerOrEqualValue(toStr);

        if (cursorKey == null) return rangeFilter;

        final k = cursorKey;
        // Keyset condition: strictly "after" in sort order (createdAtUtc DESC, id ASC)
        final keyFilter = t.createdAtUtc.isSmallerThanValue(k.createdAtUtc) |
            (t.createdAtUtc.equals(k.createdAtUtc) &
                t.id.isBiggerThanValue(k.id));

        return rangeFilter & keyFilter;
      })
      ..orderBy(<OrderingTerm Function(Milestones)>[
        (t) => OrderingTerm.desc(t.createdAtUtc),
        (t) => OrderingTerm.asc(t.id),
      ])
      ..limit(fetchSize);

    final rows = await query.get();
    final hasMore = rows.length > pageSize;
    final pageRows = hasMore ? rows.sublist(0, pageSize) : rows;
    final items = pageRows.map((row) {
      decodeUtc(row.createdAtUtc, fieldName: 'milestones.created_at_utc');
      if (row.deletedAtUtc != null) {
        decodeUtc(row.deletedAtUtc!, fieldName: 'milestones.deleted_at_utc');
      }
      return decodeDomainJson<domain.MilestoneEvent>(
        row.json,
        domain.MilestoneEvent.fromJson,
        entity: 'milestones',
      );
    }).toList(growable: false);

    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeMilestone(MilestoneCursorKey(
        createdAtUtc: last.createdAtUtc.toIso8601String(),
        id: last.id,
      ));
    }

    return CursorPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<void> save(domain.MilestoneEvent event) async {
    final json =
        encodeJson(encodeDomainJson(event.toJson()), fieldName: 'json');
    try {
      await db.into(db.milestones).insert(
            MilestonesCompanion(
              id: Value<String>(event.id),
              dedupKey: Value<String>(event.dedupKey),
              type: Value<String>(event.type),
              exerciseId: Value<String>(event.exerciseId),
              logId: Value<String>(event.logId),
              metricValue: Value<double>(event.metricValue),
              createdAtUtc: Value<String>(
                encodeUtc(event.createdAtUtc, fieldName: 'createdAtUtc'),
              ),
              deletedAtUtc: Value<String?>(
                event.deletedAtUtc == null
                    ? null
                    : encodeUtc(event.deletedAtUtc!, fieldName: 'deletedAtUtc'),
              ),
              json: Value<String>(json),
            ),
            mode: InsertMode.insert,
          );
    } catch (error) {
      throwIfConstraint(error,
          context: <String, Object?>{'table': 'milestones'});
    }
  }
}
