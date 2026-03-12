import 'dart:convert';

import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'transactional_resource.dart';

class InMemoryWorkoutLogRepository
    implements WorkoutLogRepository, TransactionalResource {
  Map<String, Map<String, dynamic>> _store = <String, Map<String, dynamic>>{};

  @override
  Future<WorkoutLog?> findById(LogId id) async {
    final raw = _store[id];
    return raw == null ? null : WorkoutLog.fromJson(_cloneMap(raw));
  }

  @override
  Future<List<WorkoutLog>> findByDate(DateOnly date) async => _store.values
      .map((e) => WorkoutLog.fromJson(_cloneMap(e)))
      .where((log) => log.date == date)
      .toList(growable: false);

  @override
  Future<List<WorkoutLog>> findAll() async => _store.values
      .map((e) => WorkoutLog.fromJson(_cloneMap(e)))
      .toList(growable: false);

  @override
  Future<void> save(WorkoutLog log) async {
    _store[log.id] = _cloneMap(log.toJson());
  }

  @override
  Future<List<WorkoutLog>> findByDateRange({
    required DateOnly from,
    required DateOnly to,
    int? limit,
    int? offset,
  }) async {
    var results = _store.values
        .map((e) => WorkoutLog.fromJson(_cloneMap(e)))
        .where(
          (log) => log.date.compareTo(from) >= 0 && log.date.compareTo(to) <= 0,
        )
        .toList()
      ..sort((left, right) {
        final dateCompare = right.date.compareTo(left.date);
        if (dateCompare != 0) {
          return dateCompare;
        }
        final createdCompare = right.createdAtUtc.compareTo(left.createdAtUtc);
        if (createdCompare != 0) {
          return createdCompare;
        }
        return left.id.compareTo(right.id);
      });
    final start = offset ?? 0;
    if (start >= results.length) {
      return <WorkoutLog>[];
    }
    results = results.sublist(start);
    if (limit != null && limit < results.length) {
      results = results.sublist(0, limit);
    }
    return results;
  }

  @override
  Future<CursorPage<WorkoutLog>> findByDateRangeCursor({
    required DateOnly from,
    required DateOnly to,
    required int pageSize,
    WorkoutLogCursorKey? cursorKey,
  }) async {
    var results = await findByDateRange(from: from, to: to);
    if (cursorKey != null) {
      results = results.where((log) {
        final dateCompare = log.date.toString().compareTo(cursorKey.date);
        if (dateCompare < 0) {
          return true;
        }
        if (dateCompare > 0) {
          return false;
        }
        final createdCompare = log.createdAtUtc
            .toIso8601String()
            .compareTo(cursorKey.createdAtUtc);
        if (createdCompare < 0) {
          return true;
        }
        if (createdCompare > 0) {
          return false;
        }
        return log.id.compareTo(cursorKey.id) > 0;
      }).toList(growable: false);
    }

    final hasMore = results.length > pageSize;
    final items =
        hasMore ? results.sublist(0, pageSize) : List<WorkoutLog>.from(results);
    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeWorkoutLog(
        WorkoutLogCursorKey(
          date: last.date.toString(),
          createdAtUtc: last.createdAtUtc.toIso8601String(),
          id: last.id,
        ),
      );
    }
    return CursorPage(items: items, nextCursor: nextCursor);
  }

  @override
  Future<CursorPage<DailyCountRow>> countByDateRangeCursor({
    required DateOnly from,
    required DateOnly to,
    required int pageSize,
    DateOnly? cursorDate,
  }) async {
    final filtered = _store.values
        .map((e) => WorkoutLog.fromJson(_cloneMap(e)))
        .where(
          (log) =>
              log.date.compareTo(from) >= 0 &&
              log.date.compareTo(to) <= 0 &&
              (cursorDate == null || log.date.compareTo(cursorDate) < 0),
        )
        .toList(growable: false);

    final countByDate = <String, int>{};
    for (final log in filtered) {
      final key = log.date.toString();
      countByDate[key] = (countByDate[key] ?? 0) + 1;
    }

    final sortedDates = countByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final hasMore = sortedDates.length > pageSize;
    final pageDates = hasMore
        ? sortedDates.sublist(0, pageSize)
        : List<String>.from(sortedDates);
    return CursorPage(
      items: pageDates
          .map(
            (date) => DailyCountRow(
              date: DateOnly.parse(date),
              count: countByDate[date]!,
            ),
          )
          .toList(growable: false),
      nextCursor: null,
    );
  }

  @override
  Future<void> delete(LogId id) async {
    _store.remove(id);
  }

  @override
  Object snapshot() => _cloneStore(_store);

  @override
  void restore(Object snapshot) {
    _store = _cloneStore(snapshot as Map<String, Map<String, dynamic>>);
  }
}

class InMemoryMilestoneRepository
    implements MilestoneRepository, TransactionalResource {
  Map<String, Map<String, dynamic>> _store = <String, Map<String, dynamic>>{};

  @override
  Future<MilestoneEvent?> findByDedupKey(String dedupKey) async {
    for (final raw in _store.values) {
      if (raw['dedupKey'] == dedupKey) {
        return MilestoneEvent.fromJson(_cloneMap(raw));
      }
    }
    return null;
  }

  @override
  Future<void> save(MilestoneEvent event) async {
    _store[event.id] = _cloneMap(event.toJson());
  }

  @override
  Future<List<MilestoneEvent>> findByCreatedAtUtcRange({
    required DateTime fromUtc,
    required DateTime toUtc,
    int? limit,
    int? offset,
  }) async {
    var results = _store.values
        .map((e) => MilestoneEvent.fromJson(_cloneMap(e)))
        .where(
          (event) =>
              !event.createdAtUtc.isBefore(fromUtc) &&
              !event.createdAtUtc.isAfter(toUtc),
        )
        .toList()
      ..sort((left, right) {
        final createdCompare = right.createdAtUtc.compareTo(left.createdAtUtc);
        if (createdCompare != 0) {
          return createdCompare;
        }
        return left.id.compareTo(right.id);
      });
    final start = offset ?? 0;
    if (start >= results.length) {
      return <MilestoneEvent>[];
    }
    results = results.sublist(start);
    if (limit != null && limit < results.length) {
      results = results.sublist(0, limit);
    }
    return results;
  }

  @override
  Future<CursorPage<MilestoneEvent>> findByCreatedAtUtcRangeCursor({
    required DateTime fromUtc,
    required DateTime toUtc,
    required int pageSize,
    MilestoneCursorKey? cursorKey,
  }) async {
    var results = await findByCreatedAtUtcRange(fromUtc: fromUtc, toUtc: toUtc);
    if (cursorKey != null) {
      results = results.where((event) {
        final createdCompare = event.createdAtUtc
            .toIso8601String()
            .compareTo(cursorKey.createdAtUtc);
        if (createdCompare < 0) {
          return true;
        }
        if (createdCompare > 0) {
          return false;
        }
        return event.id.compareTo(cursorKey.id) > 0;
      }).toList(growable: false);
    }

    final hasMore = results.length > pageSize;
    final items = hasMore
        ? results.sublist(0, pageSize)
        : List<MilestoneEvent>.from(results);
    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeMilestone(
        MilestoneCursorKey(
          createdAtUtc: last.createdAtUtc.toIso8601String(),
          id: last.id,
        ),
      );
    }
    return CursorPage(items: items, nextCursor: nextCursor);
  }

  @override
  Object snapshot() => _cloneStore(_store);

  @override
  void restore(Object snapshot) {
    _store = _cloneStore(snapshot as Map<String, Map<String, dynamic>>);
  }
}

class InMemoryExerciseRepository
    implements ExerciseRepository, TransactionalResource {
  Map<String, Map<String, dynamic>> _store = <String, Map<String, dynamic>>{};

  @override
  Future<Exercise?> findById(ExerciseId id) async {
    final raw = _store[id];
    return raw == null ? null : Exercise.fromJson(_cloneMap(raw));
  }

  @override
  Future<List<Exercise>> findAll() async => _store.values
      .map((e) => Exercise.fromJson(_cloneMap(e)))
      .toList(growable: false);

  @override
  Future<void> save(Exercise exercise) async {
    _store[exercise.id] = _cloneMap(exercise.toJson());
  }

  @override
  Future<CursorPage<Exercise>> searchCatalogCursor({
    String? keyword,
    bool includeDeprecated = false,
    required int pageSize,
    ExerciseCatalogCursorKey? cursorKey,
  }) async {
    var results = _store.values
        .map((e) => Exercise.fromJson(_cloneMap(e)))
        .where((exercise) {
      if (keyword != null && keyword.isNotEmpty) {
        if (!exercise.name.toLowerCase().contains(keyword.toLowerCase())) {
          return false;
        }
      }
      if (!includeDeprecated && exercise.deprecated) {
        return false;
      }
      return true;
    }).toList()
      ..sort((left, right) {
        final leftDeprecated = left.deprecated ? 1 : 0;
        final rightDeprecated = right.deprecated ? 1 : 0;
        final deprecatedCompare = leftDeprecated.compareTo(rightDeprecated);
        if (deprecatedCompare != 0) {
          return deprecatedCompare;
        }
        final nameCompare =
            left.name.toLowerCase().compareTo(right.name.toLowerCase());
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });

    if (cursorKey != null) {
      results = results.where((exercise) {
        final deprecated = exercise.deprecated ? 1 : 0;
        if (deprecated > cursorKey.deprecated) {
          return true;
        }
        if (deprecated < cursorKey.deprecated) {
          return false;
        }
        final nameNormalized = exercise.name.toLowerCase();
        final nameCompare = nameNormalized.compareTo(cursorKey.nameNormalized);
        if (nameCompare > 0) {
          return true;
        }
        if (nameCompare < 0) {
          return false;
        }
        return exercise.id.compareTo(cursorKey.id) > 0;
      }).toList(growable: false);
    }

    final hasMore = results.length > pageSize;
    final items =
        hasMore ? results.sublist(0, pageSize) : List<Exercise>.from(results);
    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeExerciseCatalog(
        ExerciseCatalogCursorKey(
          deprecated: last.deprecated ? 1 : 0,
          nameNormalized: last.name.toLowerCase(),
          id: last.id,
        ),
      );
    }
    return CursorPage(items: items, nextCursor: nextCursor);
  }

  @override
  Object snapshot() => _cloneStore(_store);

  @override
  void restore(Object snapshot) {
    _store = _cloneStore(snapshot as Map<String, Map<String, dynamic>>);
  }
}

class InMemoryTagRepository implements TagRepository, TransactionalResource {
  Map<String, Map<String, dynamic>> _store = <String, Map<String, dynamic>>{};

  @override
  Future<Tag?> findById(TagId id) async {
    final raw = _store[id];
    return raw == null ? null : Tag.fromJson(_cloneMap(raw));
  }

  @override
  Future<List<Tag>> findAll() async =>
      _store.values.map((e) => Tag.fromJson(_cloneMap(e))).toList();

  @override
  Future<void> save(Tag tag) async {
    _store[tag.id] = _cloneMap(tag.toJson());
  }

  @override
  Future<void> delete(TagId id) async {
    _store.remove(id);
  }

  @override
  Future<CursorPage<Tag>> searchCatalogCursor({
    String? keyword,
    required int pageSize,
    TagCatalogCursorKey? cursorKey,
  }) async {
    var results =
        _store.values.map((e) => Tag.fromJson(_cloneMap(e))).where((tag) {
      if (keyword != null && keyword.isNotEmpty) {
        return tag.name.toLowerCase().contains(keyword.toLowerCase());
      }
      return true;
    }).toList()
          ..sort((left, right) {
            final nameCompare =
                left.name.toLowerCase().compareTo(right.name.toLowerCase());
            if (nameCompare != 0) {
              return nameCompare;
            }
            return left.id.compareTo(right.id);
          });

    if (cursorKey != null) {
      results = results.where((tag) {
        final nameNormalized = tag.name.toLowerCase();
        final nameCompare = nameNormalized.compareTo(cursorKey.nameNormalized);
        if (nameCompare > 0) {
          return true;
        }
        if (nameCompare < 0) {
          return false;
        }
        return tag.id.compareTo(cursorKey.id) > 0;
      }).toList(growable: false);
    }

    final hasMore = results.length > pageSize;
    final items =
        hasMore ? results.sublist(0, pageSize) : List<Tag>.from(results);
    String? nextCursor;
    if (hasMore) {
      final last = items.last;
      nextCursor = CursorCodec.encodeTagCatalog(
        TagCatalogCursorKey(
          nameNormalized: last.name.toLowerCase(),
          id: last.id,
        ),
      );
    }
    return CursorPage(items: items, nextCursor: nextCursor);
  }

  @override
  Object snapshot() => _cloneStore(_store);

  @override
  void restore(Object snapshot) {
    _store = _cloneStore(snapshot as Map<String, Map<String, dynamic>>);
  }
}

Map<String, dynamic> _cloneMap(Map<String, dynamic> value) =>
    (jsonDecode(jsonEncode(value)) as Map<dynamic, dynamic>)
        .cast<String, dynamic>();

Map<String, Map<String, dynamic>> _cloneStore(
  Map<String, Map<String, dynamic>> store,
) {
  return (jsonDecode(jsonEncode(store)) as Map<dynamic, dynamic>).map(
    (key, value) => MapEntry(
      key as String,
      (value as Map<dynamic, dynamic>).cast<String, dynamic>(),
    ),
  );
}
