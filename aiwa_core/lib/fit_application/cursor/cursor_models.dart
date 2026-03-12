import 'package:aiwa_core/fit_domain/fit_domain.dart';

class CursorPage<T> {
  final List<T> items;
  final String? nextCursor;

  const CursorPage({required this.items, this.nextCursor});
}

class WorkoutLogCursorKey {
  static const String namespace = 'workoutLog:dateRange:v1';

  final String date;
  final String createdAtUtc;
  final String id;

  const WorkoutLogCursorKey({
    required this.date,
    required this.createdAtUtc,
    required this.id,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date,
        'createdAtUtc': createdAtUtc,
        'id': id,
      };

  static WorkoutLogCursorKey fromJson(Map<String, dynamic> json) =>
      WorkoutLogCursorKey(
        date: json['date'] as String,
        createdAtUtc: json['createdAtUtc'] as String,
        id: json['id'] as String,
      );
}

class MilestoneCursorKey {
  static const String namespace = 'milestone:createdAtRange:v1';

  final String createdAtUtc;
  final String id;

  const MilestoneCursorKey({required this.createdAtUtc, required this.id});

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'createdAtUtc': createdAtUtc, 'id': id};

  static MilestoneCursorKey fromJson(Map<String, dynamic> json) =>
      MilestoneCursorKey(
        createdAtUtc: json['createdAtUtc'] as String,
        id: json['id'] as String,
      );
}

class ExerciseCatalogCursorKey {
  static const String namespace = 'exerciseCatalog:v1';

  final int deprecated;
  final String nameNormalized;
  final String id;

  const ExerciseCatalogCursorKey({
    required this.deprecated,
    required this.nameNormalized,
    required this.id,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'deprecated': deprecated,
        'nameNormalized': nameNormalized,
        'id': id,
      };

  static ExerciseCatalogCursorKey fromJson(Map<String, dynamic> json) =>
      ExerciseCatalogCursorKey(
        deprecated: json['deprecated'] as int,
        nameNormalized: json['nameNormalized'] as String,
        id: json['id'] as String,
      );
}

class TagCatalogCursorKey {
  static const String namespace = 'tagCatalog:v1';

  final String nameNormalized;
  final String id;

  const TagCatalogCursorKey({
    required this.nameNormalized,
    required this.id,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nameNormalized': nameNormalized,
        'id': id,
      };

  static TagCatalogCursorKey fromJson(Map<String, dynamic> json) =>
      TagCatalogCursorKey(
        nameNormalized: json['nameNormalized'] as String,
        id: json['id'] as String,
      );
}

class WorkoutLogCursorQuery {
  final DateOnly from;
  final DateOnly to;
  final int pageSize;
  final String? cursor;

  const WorkoutLogCursorQuery({
    required this.from,
    required this.to,
    required this.pageSize,
    this.cursor,
  });
}

class MilestoneCursorQuery {
  final DateTime fromUtc;
  final DateTime toUtc;
  final int pageSize;
  final String? cursor;

  const MilestoneCursorQuery({
    required this.fromUtc,
    required this.toUtc,
    required this.pageSize,
    this.cursor,
  });
}

class CatalogCursorQuery {
  final String? keyword;
  final bool includeDeprecated;
  final String? tagId;
  final int pageSize;
  final String? cursor;

  const CatalogCursorQuery({
    this.keyword,
    this.includeDeprecated = false,
    this.tagId,
    required this.pageSize,
    this.cursor,
  });
}

class DailyCountRow {
  final DateOnly date;
  final int count;

  const DailyCountRow({required this.date, required this.count});
}
