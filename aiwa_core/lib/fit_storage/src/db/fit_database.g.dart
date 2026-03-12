// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fit_database.dart';

// ignore_for_file: type=lint
class $WorkoutLogsTable extends WorkoutLogs
    with TableInfo<$WorkoutLogsTable, WorkoutLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _boundTaskOccurrenceIdMeta =
      const VerificationMeta('boundTaskOccurrenceId');
  @override
  late final GeneratedColumn<String> boundTaskOccurrenceId =
      GeneratedColumn<String>('bound_task_occurrence_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtUtcMeta =
      const VerificationMeta('createdAtUtc');
  @override
  late final GeneratedColumn<String> createdAtUtc = GeneratedColumn<String>(
      'created_at_utc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastEditedAtUtcMeta =
      const VerificationMeta('lastEditedAtUtc');
  @override
  late final GeneratedColumn<String> lastEditedAtUtc = GeneratedColumn<String>(
      'last_edited_at_utc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, boundTaskOccurrenceId, createdAtUtc, lastEditedAtUtc, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_logs';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bound_task_occurrence_id')) {
      context.handle(
          _boundTaskOccurrenceIdMeta,
          boundTaskOccurrenceId.isAcceptableOrUnknown(
              data['bound_task_occurrence_id']!, _boundTaskOccurrenceIdMeta));
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
          _createdAtUtcMeta,
          createdAtUtc.isAcceptableOrUnknown(
              data['created_at_utc']!, _createdAtUtcMeta));
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('last_edited_at_utc')) {
      context.handle(
          _lastEditedAtUtcMeta,
          lastEditedAtUtc.isAcceptableOrUnknown(
              data['last_edited_at_utc']!, _lastEditedAtUtcMeta));
    } else if (isInserting) {
      context.missing(_lastEditedAtUtcMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      boundTaskOccurrenceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}bound_task_occurrence_id']),
      createdAtUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at_utc'])!,
      lastEditedAtUtc: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_edited_at_utc'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $WorkoutLogsTable createAlias(String alias) {
    return $WorkoutLogsTable(attachedDatabase, alias);
  }
}

class WorkoutLog extends DataClass implements Insertable<WorkoutLog> {
  final String id;
  final String date;
  final String? boundTaskOccurrenceId;
  final String createdAtUtc;
  final String lastEditedAtUtc;
  final String json;
  const WorkoutLog(
      {required this.id,
      required this.date,
      this.boundTaskOccurrenceId,
      required this.createdAtUtc,
      required this.lastEditedAtUtc,
      required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || boundTaskOccurrenceId != null) {
      map['bound_task_occurrence_id'] = Variable<String>(boundTaskOccurrenceId);
    }
    map['created_at_utc'] = Variable<String>(createdAtUtc);
    map['last_edited_at_utc'] = Variable<String>(lastEditedAtUtc);
    map['json'] = Variable<String>(json);
    return map;
  }

  WorkoutLogsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutLogsCompanion(
      id: Value(id),
      date: Value(date),
      boundTaskOccurrenceId: boundTaskOccurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(boundTaskOccurrenceId),
      createdAtUtc: Value(createdAtUtc),
      lastEditedAtUtc: Value(lastEditedAtUtc),
      json: Value(json),
    );
  }

  factory WorkoutLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutLog(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      boundTaskOccurrenceId:
          serializer.fromJson<String?>(json['boundTaskOccurrenceId']),
      createdAtUtc: serializer.fromJson<String>(json['createdAtUtc']),
      lastEditedAtUtc: serializer.fromJson<String>(json['lastEditedAtUtc']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'boundTaskOccurrenceId':
          serializer.toJson<String?>(boundTaskOccurrenceId),
      'createdAtUtc': serializer.toJson<String>(createdAtUtc),
      'lastEditedAtUtc': serializer.toJson<String>(lastEditedAtUtc),
      'json': serializer.toJson<String>(json),
    };
  }

  WorkoutLog copyWith(
          {String? id,
          String? date,
          Value<String?> boundTaskOccurrenceId = const Value.absent(),
          String? createdAtUtc,
          String? lastEditedAtUtc,
          String? json}) =>
      WorkoutLog(
        id: id ?? this.id,
        date: date ?? this.date,
        boundTaskOccurrenceId: boundTaskOccurrenceId.present
            ? boundTaskOccurrenceId.value
            : this.boundTaskOccurrenceId,
        createdAtUtc: createdAtUtc ?? this.createdAtUtc,
        lastEditedAtUtc: lastEditedAtUtc ?? this.lastEditedAtUtc,
        json: json ?? this.json,
      );
  WorkoutLog copyWithCompanion(WorkoutLogsCompanion data) {
    return WorkoutLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      boundTaskOccurrenceId: data.boundTaskOccurrenceId.present
          ? data.boundTaskOccurrenceId.value
          : this.boundTaskOccurrenceId,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      lastEditedAtUtc: data.lastEditedAtUtc.present
          ? data.lastEditedAtUtc.value
          : this.lastEditedAtUtc,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('boundTaskOccurrenceId: $boundTaskOccurrenceId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('lastEditedAtUtc: $lastEditedAtUtc, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, date, boundTaskOccurrenceId, createdAtUtc, lastEditedAtUtc, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.boundTaskOccurrenceId == this.boundTaskOccurrenceId &&
          other.createdAtUtc == this.createdAtUtc &&
          other.lastEditedAtUtc == this.lastEditedAtUtc &&
          other.json == this.json);
}

class WorkoutLogsCompanion extends UpdateCompanion<WorkoutLog> {
  final Value<String> id;
  final Value<String> date;
  final Value<String?> boundTaskOccurrenceId;
  final Value<String> createdAtUtc;
  final Value<String> lastEditedAtUtc;
  final Value<String> json;
  final Value<int> rowid;
  const WorkoutLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.boundTaskOccurrenceId = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.lastEditedAtUtc = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutLogsCompanion.insert({
    required String id,
    required String date,
    this.boundTaskOccurrenceId = const Value.absent(),
    required String createdAtUtc,
    required String lastEditedAtUtc,
    required String json,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        date = Value(date),
        createdAtUtc = Value(createdAtUtc),
        lastEditedAtUtc = Value(lastEditedAtUtc),
        json = Value(json);
  static Insertable<WorkoutLog> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? boundTaskOccurrenceId,
    Expression<String>? createdAtUtc,
    Expression<String>? lastEditedAtUtc,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (boundTaskOccurrenceId != null)
        'bound_task_occurrence_id': boundTaskOccurrenceId,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (lastEditedAtUtc != null) 'last_edited_at_utc': lastEditedAtUtc,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutLogsCompanion copyWith(
      {Value<String>? id,
      Value<String>? date,
      Value<String?>? boundTaskOccurrenceId,
      Value<String>? createdAtUtc,
      Value<String>? lastEditedAtUtc,
      Value<String>? json,
      Value<int>? rowid}) {
    return WorkoutLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      boundTaskOccurrenceId:
          boundTaskOccurrenceId ?? this.boundTaskOccurrenceId,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      lastEditedAtUtc: lastEditedAtUtc ?? this.lastEditedAtUtc,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (boundTaskOccurrenceId.present) {
      map['bound_task_occurrence_id'] =
          Variable<String>(boundTaskOccurrenceId.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<String>(createdAtUtc.value);
    }
    if (lastEditedAtUtc.present) {
      map['last_edited_at_utc'] = Variable<String>(lastEditedAtUtc.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('boundTaskOccurrenceId: $boundTaskOccurrenceId, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('lastEditedAtUtc: $lastEditedAtUtc, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deprecatedMeta =
      const VerificationMeta('deprecated');
  @override
  late final GeneratedColumn<int> deprecated = GeneratedColumn<int>(
      'deprecated', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, deprecated, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('deprecated')) {
      context.handle(
          _deprecatedMeta,
          deprecated.isAcceptableOrUnknown(
              data['deprecated']!, _deprecatedMeta));
    } else if (isInserting) {
      context.missing(_deprecatedMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      deprecated: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deprecated'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final String name;
  final int deprecated;
  final String json;
  const Exercise(
      {required this.id,
      required this.name,
      required this.deprecated,
      required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['deprecated'] = Variable<int>(deprecated);
    map['json'] = Variable<String>(json);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      name: Value(name),
      deprecated: Value(deprecated),
      json: Value(json),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deprecated: serializer.fromJson<int>(json['deprecated']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'deprecated': serializer.toJson<int>(deprecated),
      'json': serializer.toJson<String>(json),
    };
  }

  Exercise copyWith(
          {String? id, String? name, int? deprecated, String? json}) =>
      Exercise(
        id: id ?? this.id,
        name: name ?? this.name,
        deprecated: deprecated ?? this.deprecated,
        json: json ?? this.json,
      );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deprecated:
          data.deprecated.present ? data.deprecated.value : this.deprecated,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deprecated: $deprecated, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, deprecated, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.name == this.name &&
          other.deprecated == this.deprecated &&
          other.json == this.json);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> deprecated;
  final Value<String> json;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deprecated = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required String name,
    required int deprecated,
    required String json,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        deprecated = Value(deprecated),
        json = Value(json);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? deprecated,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deprecated != null) 'deprecated': deprecated,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? deprecated,
      Value<String>? json,
      Value<int>? rowid}) {
    return ExercisesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deprecated: deprecated ?? this.deprecated,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deprecated.present) {
      map['deprecated'] = Variable<int>(deprecated.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deprecated: $deprecated, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(Insertable<Tag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final String json;
  const Tag({required this.id, required this.name, required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['json'] = Variable<String>(json);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      json: Value(json),
    );
  }

  factory Tag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'json': serializer.toJson<String>(json),
    };
  }

  Tag copyWith({String? id, String? name, String? json}) => Tag(
        id: id ?? this.id,
        name: name ?? this.name,
        json: json ?? this.json,
      );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.json == this.json);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> json;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required String json,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        json = Value(json);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? json,
      Value<int>? rowid}) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTemplatesTable extends TaskTemplates
    with TableInfo<$TaskTemplatesTable, TaskTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, title, description, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_templates';
  @override
  VerificationContext validateIntegrity(Insertable<TaskTemplate> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTemplate(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $TaskTemplatesTable createAlias(String alias) {
    return $TaskTemplatesTable(attachedDatabase, alias);
  }
}

class TaskTemplate extends DataClass implements Insertable<TaskTemplate> {
  final String id;
  final String title;
  final String? description;
  final String json;
  const TaskTemplate(
      {required this.id,
      required this.title,
      this.description,
      required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['json'] = Variable<String>(json);
    return map;
  }

  TaskTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TaskTemplatesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      json: Value(json),
    );
  }

  factory TaskTemplate.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTemplate(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'json': serializer.toJson<String>(json),
    };
  }

  TaskTemplate copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          String? json}) =>
      TaskTemplate(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        json: json ?? this.json,
      );
  TaskTemplate copyWithCompanion(TaskTemplatesCompanion data) {
    return TaskTemplate(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplate(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTemplate &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.json == this.json);
}

class TaskTemplatesCompanion extends UpdateCompanion<TaskTemplate> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> json;
  final Value<int> rowid;
  const TaskTemplatesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTemplatesCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        json = Value(json);
  static Insertable<TaskTemplate> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTemplatesCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String>? json,
      Value<int>? rowid}) {
    return TaskTemplatesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskActivationsTable extends TaskActivations
    with TableInfo<$TaskActivationsTable, TaskActivation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskActivationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateIdMeta =
      const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
      'template_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startDateMeta =
      const VerificationMeta('startDate');
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
      'start_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtUtcMeta =
      const VerificationMeta('createdAtUtc');
  @override
  late final GeneratedColumn<String> createdAtUtc = GeneratedColumn<String>(
      'created_at_utc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, templateId, startDate, createdAtUtc, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_activations';
  @override
  VerificationContext validateIntegrity(Insertable<TaskActivation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
          _templateIdMeta,
          templateId.isAcceptableOrUnknown(
              data['template_id']!, _templateIdMeta));
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(_startDateMeta,
          startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta));
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
          _createdAtUtcMeta,
          createdAtUtc.isAcceptableOrUnknown(
              data['created_at_utc']!, _createdAtUtcMeta));
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskActivation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskActivation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      templateId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_id'])!,
      startDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}start_date'])!,
      createdAtUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at_utc'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $TaskActivationsTable createAlias(String alias) {
    return $TaskActivationsTable(attachedDatabase, alias);
  }
}

class TaskActivation extends DataClass implements Insertable<TaskActivation> {
  final String id;
  final String templateId;
  final String startDate;
  final String createdAtUtc;
  final String json;
  const TaskActivation(
      {required this.id,
      required this.templateId,
      required this.startDate,
      required this.createdAtUtc,
      required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['start_date'] = Variable<String>(startDate);
    map['created_at_utc'] = Variable<String>(createdAtUtc);
    map['json'] = Variable<String>(json);
    return map;
  }

  TaskActivationsCompanion toCompanion(bool nullToAbsent) {
    return TaskActivationsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      startDate: Value(startDate),
      createdAtUtc: Value(createdAtUtc),
      json: Value(json),
    );
  }

  factory TaskActivation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskActivation(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      startDate: serializer.fromJson<String>(json['startDate']),
      createdAtUtc: serializer.fromJson<String>(json['createdAtUtc']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'startDate': serializer.toJson<String>(startDate),
      'createdAtUtc': serializer.toJson<String>(createdAtUtc),
      'json': serializer.toJson<String>(json),
    };
  }

  TaskActivation copyWith(
          {String? id,
          String? templateId,
          String? startDate,
          String? createdAtUtc,
          String? json}) =>
      TaskActivation(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        startDate: startDate ?? this.startDate,
        createdAtUtc: createdAtUtc ?? this.createdAtUtc,
        json: json ?? this.json,
      );
  TaskActivation copyWithCompanion(TaskActivationsCompanion data) {
    return TaskActivation(
      id: data.id.present ? data.id.value : this.id,
      templateId:
          data.templateId.present ? data.templateId.value : this.templateId,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskActivation(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('startDate: $startDate, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateId, startDate, createdAtUtc, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskActivation &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.startDate == this.startDate &&
          other.createdAtUtc == this.createdAtUtc &&
          other.json == this.json);
}

class TaskActivationsCompanion extends UpdateCompanion<TaskActivation> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> startDate;
  final Value<String> createdAtUtc;
  final Value<String> json;
  final Value<int> rowid;
  const TaskActivationsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.startDate = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskActivationsCompanion.insert({
    required String id,
    required String templateId,
    required String startDate,
    required String createdAtUtc,
    required String json,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        templateId = Value(templateId),
        startDate = Value(startDate),
        createdAtUtc = Value(createdAtUtc),
        json = Value(json);
  static Insertable<TaskActivation> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? startDate,
    Expression<String>? createdAtUtc,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (startDate != null) 'start_date': startDate,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskActivationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? templateId,
      Value<String>? startDate,
      Value<String>? createdAtUtc,
      Value<String>? json,
      Value<int>? rowid}) {
    return TaskActivationsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      startDate: startDate ?? this.startDate,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<String>(createdAtUtc.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskActivationsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('startDate: $startDate, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskOccurrencesTable extends TaskOccurrences
    with TableInfo<$TaskOccurrencesTable, TaskOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activationIdMeta =
      const VerificationMeta('activationId');
  @override
  late final GeneratedColumn<String> activationId = GeneratedColumn<String>(
      'activation_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _boundLogIdMeta =
      const VerificationMeta('boundLogId');
  @override
  late final GeneratedColumn<String> boundLogId = GeneratedColumn<String>(
      'bound_log_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _suppressedMeta =
      const VerificationMeta('suppressed');
  @override
  late final GeneratedColumn<bool> suppressed = GeneratedColumn<bool>(
      'suppressed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("suppressed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, activationId, date, boundLogId, suppressed, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_occurrences';
  @override
  VerificationContext validateIntegrity(Insertable<TaskOccurrence> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('activation_id')) {
      context.handle(
          _activationIdMeta,
          activationId.isAcceptableOrUnknown(
              data['activation_id']!, _activationIdMeta));
    } else if (isInserting) {
      context.missing(_activationIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bound_log_id')) {
      context.handle(
          _boundLogIdMeta,
          boundLogId.isAcceptableOrUnknown(
              data['bound_log_id']!, _boundLogIdMeta));
    }
    if (data.containsKey('suppressed')) {
      context.handle(
          _suppressedMeta,
          suppressed.isAcceptableOrUnknown(
              data['suppressed']!, _suppressedMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {activationId, date},
      ];
  @override
  TaskOccurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskOccurrence(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      activationId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activation_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      boundLogId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}bound_log_id']),
      suppressed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}suppressed'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $TaskOccurrencesTable createAlias(String alias) {
    return $TaskOccurrencesTable(attachedDatabase, alias);
  }
}

class TaskOccurrence extends DataClass implements Insertable<TaskOccurrence> {
  final String id;
  final String activationId;
  final String date;
  final String? boundLogId;
  final bool suppressed;
  final String json;
  const TaskOccurrence(
      {required this.id,
      required this.activationId,
      required this.date,
      this.boundLogId,
      required this.suppressed,
      required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['activation_id'] = Variable<String>(activationId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || boundLogId != null) {
      map['bound_log_id'] = Variable<String>(boundLogId);
    }
    map['suppressed'] = Variable<bool>(suppressed);
    map['json'] = Variable<String>(json);
    return map;
  }

  TaskOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return TaskOccurrencesCompanion(
      id: Value(id),
      activationId: Value(activationId),
      date: Value(date),
      boundLogId: boundLogId == null && nullToAbsent
          ? const Value.absent()
          : Value(boundLogId),
      suppressed: Value(suppressed),
      json: Value(json),
    );
  }

  factory TaskOccurrence.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskOccurrence(
      id: serializer.fromJson<String>(json['id']),
      activationId: serializer.fromJson<String>(json['activationId']),
      date: serializer.fromJson<String>(json['date']),
      boundLogId: serializer.fromJson<String?>(json['boundLogId']),
      suppressed: serializer.fromJson<bool>(json['suppressed']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'activationId': serializer.toJson<String>(activationId),
      'date': serializer.toJson<String>(date),
      'boundLogId': serializer.toJson<String?>(boundLogId),
      'suppressed': serializer.toJson<bool>(suppressed),
      'json': serializer.toJson<String>(json),
    };
  }

  TaskOccurrence copyWith(
          {String? id,
          String? activationId,
          String? date,
          Value<String?> boundLogId = const Value.absent(),
          bool? suppressed,
          String? json}) =>
      TaskOccurrence(
        id: id ?? this.id,
        activationId: activationId ?? this.activationId,
        date: date ?? this.date,
        boundLogId: boundLogId.present ? boundLogId.value : this.boundLogId,
        suppressed: suppressed ?? this.suppressed,
        json: json ?? this.json,
      );
  TaskOccurrence copyWithCompanion(TaskOccurrencesCompanion data) {
    return TaskOccurrence(
      id: data.id.present ? data.id.value : this.id,
      activationId: data.activationId.present
          ? data.activationId.value
          : this.activationId,
      date: data.date.present ? data.date.value : this.date,
      boundLogId:
          data.boundLogId.present ? data.boundLogId.value : this.boundLogId,
      suppressed:
          data.suppressed.present ? data.suppressed.value : this.suppressed,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrence(')
          ..write('id: $id, ')
          ..write('activationId: $activationId, ')
          ..write('date: $date, ')
          ..write('boundLogId: $boundLogId, ')
          ..write('suppressed: $suppressed, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, activationId, date, boundLogId, suppressed, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskOccurrence &&
          other.id == this.id &&
          other.activationId == this.activationId &&
          other.date == this.date &&
          other.boundLogId == this.boundLogId &&
          other.suppressed == this.suppressed &&
          other.json == this.json);
}

class TaskOccurrencesCompanion extends UpdateCompanion<TaskOccurrence> {
  final Value<String> id;
  final Value<String> activationId;
  final Value<String> date;
  final Value<String?> boundLogId;
  final Value<bool> suppressed;
  final Value<String> json;
  final Value<int> rowid;
  const TaskOccurrencesCompanion({
    this.id = const Value.absent(),
    this.activationId = const Value.absent(),
    this.date = const Value.absent(),
    this.boundLogId = const Value.absent(),
    this.suppressed = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskOccurrencesCompanion.insert({
    required String id,
    required String activationId,
    required String date,
    this.boundLogId = const Value.absent(),
    this.suppressed = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        activationId = Value(activationId),
        date = Value(date),
        json = Value(json);
  static Insertable<TaskOccurrence> custom({
    Expression<String>? id,
    Expression<String>? activationId,
    Expression<String>? date,
    Expression<String>? boundLogId,
    Expression<bool>? suppressed,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (activationId != null) 'activation_id': activationId,
      if (date != null) 'date': date,
      if (boundLogId != null) 'bound_log_id': boundLogId,
      if (suppressed != null) 'suppressed': suppressed,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskOccurrencesCompanion copyWith(
      {Value<String>? id,
      Value<String>? activationId,
      Value<String>? date,
      Value<String?>? boundLogId,
      Value<bool>? suppressed,
      Value<String>? json,
      Value<int>? rowid}) {
    return TaskOccurrencesCompanion(
      id: id ?? this.id,
      activationId: activationId ?? this.activationId,
      date: date ?? this.date,
      boundLogId: boundLogId ?? this.boundLogId,
      suppressed: suppressed ?? this.suppressed,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (activationId.present) {
      map['activation_id'] = Variable<String>(activationId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (boundLogId.present) {
      map['bound_log_id'] = Variable<String>(boundLogId.value);
    }
    if (suppressed.present) {
      map['suppressed'] = Variable<bool>(suppressed.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('activationId: $activationId, ')
          ..write('date: $date, ')
          ..write('boundLogId: $boundLogId, ')
          ..write('suppressed: $suppressed, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MilestonesTable extends Milestones
    with TableInfo<$MilestonesTable, Milestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dedupKeyMeta =
      const VerificationMeta('dedupKey');
  @override
  late final GeneratedColumn<String> dedupKey = GeneratedColumn<String>(
      'dedup_key', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _logIdMeta = const VerificationMeta('logId');
  @override
  late final GeneratedColumn<String> logId = GeneratedColumn<String>(
      'log_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _metricValueMeta =
      const VerificationMeta('metricValue');
  @override
  late final GeneratedColumn<double> metricValue = GeneratedColumn<double>(
      'metric_value', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdAtUtcMeta =
      const VerificationMeta('createdAtUtc');
  @override
  late final GeneratedColumn<String> createdAtUtc = GeneratedColumn<String>(
      'created_at_utc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtUtcMeta =
      const VerificationMeta('deletedAtUtc');
  @override
  late final GeneratedColumn<String> deletedAtUtc = GeneratedColumn<String>(
      'deleted_at_utc', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        dedupKey,
        type,
        exerciseId,
        logId,
        metricValue,
        createdAtUtc,
        deletedAtUtc,
        json
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'milestones';
  @override
  VerificationContext validateIntegrity(Insertable<Milestone> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('dedup_key')) {
      context.handle(_dedupKeyMeta,
          dedupKey.isAcceptableOrUnknown(data['dedup_key']!, _dedupKeyMeta));
    } else if (isInserting) {
      context.missing(_dedupKeyMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('log_id')) {
      context.handle(
          _logIdMeta, logId.isAcceptableOrUnknown(data['log_id']!, _logIdMeta));
    } else if (isInserting) {
      context.missing(_logIdMeta);
    }
    if (data.containsKey('metric_value')) {
      context.handle(
          _metricValueMeta,
          metricValue.isAcceptableOrUnknown(
              data['metric_value']!, _metricValueMeta));
    } else if (isInserting) {
      context.missing(_metricValueMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
          _createdAtUtcMeta,
          createdAtUtc.isAcceptableOrUnknown(
              data['created_at_utc']!, _createdAtUtcMeta));
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('deleted_at_utc')) {
      context.handle(
          _deletedAtUtcMeta,
          deletedAtUtc.isAcceptableOrUnknown(
              data['deleted_at_utc']!, _deletedAtUtcMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Milestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Milestone(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      dedupKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dedup_key'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      logId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}log_id'])!,
      metricValue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}metric_value'])!,
      createdAtUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at_utc'])!,
      deletedAtUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}deleted_at_utc']),
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
    );
  }

  @override
  $MilestonesTable createAlias(String alias) {
    return $MilestonesTable(attachedDatabase, alias);
  }
}

class Milestone extends DataClass implements Insertable<Milestone> {
  final String id;
  final String dedupKey;
  final String type;
  final String exerciseId;
  final String logId;
  final double metricValue;
  final String createdAtUtc;
  final String? deletedAtUtc;
  final String json;
  const Milestone(
      {required this.id,
      required this.dedupKey,
      required this.type,
      required this.exerciseId,
      required this.logId,
      required this.metricValue,
      required this.createdAtUtc,
      this.deletedAtUtc,
      required this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['dedup_key'] = Variable<String>(dedupKey);
    map['type'] = Variable<String>(type);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['log_id'] = Variable<String>(logId);
    map['metric_value'] = Variable<double>(metricValue);
    map['created_at_utc'] = Variable<String>(createdAtUtc);
    if (!nullToAbsent || deletedAtUtc != null) {
      map['deleted_at_utc'] = Variable<String>(deletedAtUtc);
    }
    map['json'] = Variable<String>(json);
    return map;
  }

  MilestonesCompanion toCompanion(bool nullToAbsent) {
    return MilestonesCompanion(
      id: Value(id),
      dedupKey: Value(dedupKey),
      type: Value(type),
      exerciseId: Value(exerciseId),
      logId: Value(logId),
      metricValue: Value(metricValue),
      createdAtUtc: Value(createdAtUtc),
      deletedAtUtc: deletedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtc),
      json: Value(json),
    );
  }

  factory Milestone.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Milestone(
      id: serializer.fromJson<String>(json['id']),
      dedupKey: serializer.fromJson<String>(json['dedupKey']),
      type: serializer.fromJson<String>(json['type']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      logId: serializer.fromJson<String>(json['logId']),
      metricValue: serializer.fromJson<double>(json['metricValue']),
      createdAtUtc: serializer.fromJson<String>(json['createdAtUtc']),
      deletedAtUtc: serializer.fromJson<String?>(json['deletedAtUtc']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dedupKey': serializer.toJson<String>(dedupKey),
      'type': serializer.toJson<String>(type),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'logId': serializer.toJson<String>(logId),
      'metricValue': serializer.toJson<double>(metricValue),
      'createdAtUtc': serializer.toJson<String>(createdAtUtc),
      'deletedAtUtc': serializer.toJson<String?>(deletedAtUtc),
      'json': serializer.toJson<String>(json),
    };
  }

  Milestone copyWith(
          {String? id,
          String? dedupKey,
          String? type,
          String? exerciseId,
          String? logId,
          double? metricValue,
          String? createdAtUtc,
          Value<String?> deletedAtUtc = const Value.absent(),
          String? json}) =>
      Milestone(
        id: id ?? this.id,
        dedupKey: dedupKey ?? this.dedupKey,
        type: type ?? this.type,
        exerciseId: exerciseId ?? this.exerciseId,
        logId: logId ?? this.logId,
        metricValue: metricValue ?? this.metricValue,
        createdAtUtc: createdAtUtc ?? this.createdAtUtc,
        deletedAtUtc:
            deletedAtUtc.present ? deletedAtUtc.value : this.deletedAtUtc,
        json: json ?? this.json,
      );
  Milestone copyWithCompanion(MilestonesCompanion data) {
    return Milestone(
      id: data.id.present ? data.id.value : this.id,
      dedupKey: data.dedupKey.present ? data.dedupKey.value : this.dedupKey,
      type: data.type.present ? data.type.value : this.type,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      logId: data.logId.present ? data.logId.value : this.logId,
      metricValue:
          data.metricValue.present ? data.metricValue.value : this.metricValue,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      deletedAtUtc: data.deletedAtUtc.present
          ? data.deletedAtUtc.value
          : this.deletedAtUtc,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Milestone(')
          ..write('id: $id, ')
          ..write('dedupKey: $dedupKey, ')
          ..write('type: $type, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('logId: $logId, ')
          ..write('metricValue: $metricValue, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('deletedAtUtc: $deletedAtUtc, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dedupKey, type, exerciseId, logId,
      metricValue, createdAtUtc, deletedAtUtc, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Milestone &&
          other.id == this.id &&
          other.dedupKey == this.dedupKey &&
          other.type == this.type &&
          other.exerciseId == this.exerciseId &&
          other.logId == this.logId &&
          other.metricValue == this.metricValue &&
          other.createdAtUtc == this.createdAtUtc &&
          other.deletedAtUtc == this.deletedAtUtc &&
          other.json == this.json);
}

class MilestonesCompanion extends UpdateCompanion<Milestone> {
  final Value<String> id;
  final Value<String> dedupKey;
  final Value<String> type;
  final Value<String> exerciseId;
  final Value<String> logId;
  final Value<double> metricValue;
  final Value<String> createdAtUtc;
  final Value<String?> deletedAtUtc;
  final Value<String> json;
  final Value<int> rowid;
  const MilestonesCompanion({
    this.id = const Value.absent(),
    this.dedupKey = const Value.absent(),
    this.type = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.logId = const Value.absent(),
    this.metricValue = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.deletedAtUtc = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilestonesCompanion.insert({
    required String id,
    required String dedupKey,
    required String type,
    required String exerciseId,
    required String logId,
    required double metricValue,
    required String createdAtUtc,
    this.deletedAtUtc = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        dedupKey = Value(dedupKey),
        type = Value(type),
        exerciseId = Value(exerciseId),
        logId = Value(logId),
        metricValue = Value(metricValue),
        createdAtUtc = Value(createdAtUtc),
        json = Value(json);
  static Insertable<Milestone> custom({
    Expression<String>? id,
    Expression<String>? dedupKey,
    Expression<String>? type,
    Expression<String>? exerciseId,
    Expression<String>? logId,
    Expression<double>? metricValue,
    Expression<String>? createdAtUtc,
    Expression<String>? deletedAtUtc,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dedupKey != null) 'dedup_key': dedupKey,
      if (type != null) 'type': type,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (logId != null) 'log_id': logId,
      if (metricValue != null) 'metric_value': metricValue,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (deletedAtUtc != null) 'deleted_at_utc': deletedAtUtc,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilestonesCompanion copyWith(
      {Value<String>? id,
      Value<String>? dedupKey,
      Value<String>? type,
      Value<String>? exerciseId,
      Value<String>? logId,
      Value<double>? metricValue,
      Value<String>? createdAtUtc,
      Value<String?>? deletedAtUtc,
      Value<String>? json,
      Value<int>? rowid}) {
    return MilestonesCompanion(
      id: id ?? this.id,
      dedupKey: dedupKey ?? this.dedupKey,
      type: type ?? this.type,
      exerciseId: exerciseId ?? this.exerciseId,
      logId: logId ?? this.logId,
      metricValue: metricValue ?? this.metricValue,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      deletedAtUtc: deletedAtUtc ?? this.deletedAtUtc,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dedupKey.present) {
      map['dedup_key'] = Variable<String>(dedupKey.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (logId.present) {
      map['log_id'] = Variable<String>(logId.value);
    }
    if (metricValue.present) {
      map['metric_value'] = Variable<double>(metricValue.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<String>(createdAtUtc.value);
    }
    if (deletedAtUtc.present) {
      map['deleted_at_utc'] = Variable<String>(deletedAtUtc.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilestonesCompanion(')
          ..write('id: $id, ')
          ..write('dedupKey: $dedupKey, ')
          ..write('type: $type, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('logId: $logId, ')
          ..write('metricValue: $metricValue, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('deletedAtUtc: $deletedAtUtc, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtUtcMeta =
      const VerificationMeta('createdAtUtc');
  @override
  late final GeneratedColumn<String> createdAtUtc = GeneratedColumn<String>(
      'created_at_utc', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relativePathMeta =
      const VerificationMeta('relativePath');
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
      'relative_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailRelativePathMeta =
      const VerificationMeta('thumbnailRelativePath');
  @override
  late final GeneratedColumn<String> thumbnailRelativePath =
      GeneratedColumn<String>('thumbnail_relative_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _byteSizeMeta =
      const VerificationMeta('byteSize');
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
      'byte_size', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
      'sha256', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metaJsonMeta =
      const VerificationMeta('metaJson');
  @override
  late final GeneratedColumn<String> metaJson = GeneratedColumn<String>(
      'meta_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        mediaType,
        createdAtUtc,
        relativePath,
        thumbnailRelativePath,
        byteSize,
        sha256,
        metaJson
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<Attachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
          _createdAtUtcMeta,
          createdAtUtc.isAcceptableOrUnknown(
              data['created_at_utc']!, _createdAtUtcMeta));
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
          _relativePathMeta,
          relativePath.isAcceptableOrUnknown(
              data['relative_path']!, _relativePathMeta));
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('thumbnail_relative_path')) {
      context.handle(
          _thumbnailRelativePathMeta,
          thumbnailRelativePath.isAcceptableOrUnknown(
              data['thumbnail_relative_path']!, _thumbnailRelativePathMeta));
    }
    if (data.containsKey('byte_size')) {
      context.handle(_byteSizeMeta,
          byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta));
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(_sha256Meta,
          sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta));
    }
    if (data.containsKey('meta_json')) {
      context.handle(_metaJsonMeta,
          metaJson.isAcceptableOrUnknown(data['meta_json']!, _metaJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      createdAtUtc: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_at_utc'])!,
      relativePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}relative_path'])!,
      thumbnailRelativePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}thumbnail_relative_path']),
      byteSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}byte_size'])!,
      sha256: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sha256']),
      metaJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meta_json']),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String mediaType;
  final String createdAtUtc;
  final String relativePath;
  final String? thumbnailRelativePath;
  final int byteSize;
  final String? sha256;
  final String? metaJson;
  const Attachment(
      {required this.id,
      required this.mediaType,
      required this.createdAtUtc,
      required this.relativePath,
      this.thumbnailRelativePath,
      required this.byteSize,
      this.sha256,
      this.metaJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['media_type'] = Variable<String>(mediaType);
    map['created_at_utc'] = Variable<String>(createdAtUtc);
    map['relative_path'] = Variable<String>(relativePath);
    if (!nullToAbsent || thumbnailRelativePath != null) {
      map['thumbnail_relative_path'] = Variable<String>(thumbnailRelativePath);
    }
    map['byte_size'] = Variable<int>(byteSize);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    if (!nullToAbsent || metaJson != null) {
      map['meta_json'] = Variable<String>(metaJson);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      mediaType: Value(mediaType),
      createdAtUtc: Value(createdAtUtc),
      relativePath: Value(relativePath),
      thumbnailRelativePath: thumbnailRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailRelativePath),
      byteSize: Value(byteSize),
      sha256:
          sha256 == null && nullToAbsent ? const Value.absent() : Value(sha256),
      metaJson: metaJson == null && nullToAbsent
          ? const Value.absent()
          : Value(metaJson),
    );
  }

  factory Attachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      createdAtUtc: serializer.fromJson<String>(json['createdAtUtc']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      thumbnailRelativePath:
          serializer.fromJson<String?>(json['thumbnailRelativePath']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      metaJson: serializer.fromJson<String?>(json['metaJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mediaType': serializer.toJson<String>(mediaType),
      'createdAtUtc': serializer.toJson<String>(createdAtUtc),
      'relativePath': serializer.toJson<String>(relativePath),
      'thumbnailRelativePath':
          serializer.toJson<String?>(thumbnailRelativePath),
      'byteSize': serializer.toJson<int>(byteSize),
      'sha256': serializer.toJson<String?>(sha256),
      'metaJson': serializer.toJson<String?>(metaJson),
    };
  }

  Attachment copyWith(
          {String? id,
          String? mediaType,
          String? createdAtUtc,
          String? relativePath,
          Value<String?> thumbnailRelativePath = const Value.absent(),
          int? byteSize,
          Value<String?> sha256 = const Value.absent(),
          Value<String?> metaJson = const Value.absent()}) =>
      Attachment(
        id: id ?? this.id,
        mediaType: mediaType ?? this.mediaType,
        createdAtUtc: createdAtUtc ?? this.createdAtUtc,
        relativePath: relativePath ?? this.relativePath,
        thumbnailRelativePath: thumbnailRelativePath.present
            ? thumbnailRelativePath.value
            : this.thumbnailRelativePath,
        byteSize: byteSize ?? this.byteSize,
        sha256: sha256.present ? sha256.value : this.sha256,
        metaJson: metaJson.present ? metaJson.value : this.metaJson,
      );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      thumbnailRelativePath: data.thumbnailRelativePath.present
          ? data.thumbnailRelativePath.value
          : this.thumbnailRelativePath,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      metaJson: data.metaJson.present ? data.metaJson.value : this.metaJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('mediaType: $mediaType, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailRelativePath: $thumbnailRelativePath, ')
          ..write('byteSize: $byteSize, ')
          ..write('sha256: $sha256, ')
          ..write('metaJson: $metaJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, mediaType, createdAtUtc, relativePath,
      thumbnailRelativePath, byteSize, sha256, metaJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.mediaType == this.mediaType &&
          other.createdAtUtc == this.createdAtUtc &&
          other.relativePath == this.relativePath &&
          other.thumbnailRelativePath == this.thumbnailRelativePath &&
          other.byteSize == this.byteSize &&
          other.sha256 == this.sha256 &&
          other.metaJson == this.metaJson);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> mediaType;
  final Value<String> createdAtUtc;
  final Value<String> relativePath;
  final Value<String?> thumbnailRelativePath;
  final Value<int> byteSize;
  final Value<String?> sha256;
  final Value<String?> metaJson;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.thumbnailRelativePath = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.metaJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String mediaType,
    required String createdAtUtc,
    required String relativePath,
    this.thumbnailRelativePath = const Value.absent(),
    required int byteSize,
    this.sha256 = const Value.absent(),
    this.metaJson = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        mediaType = Value(mediaType),
        createdAtUtc = Value(createdAtUtc),
        relativePath = Value(relativePath),
        byteSize = Value(byteSize);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? mediaType,
    Expression<String>? createdAtUtc,
    Expression<String>? relativePath,
    Expression<String>? thumbnailRelativePath,
    Expression<int>? byteSize,
    Expression<String>? sha256,
    Expression<String>? metaJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mediaType != null) 'media_type': mediaType,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (relativePath != null) 'relative_path': relativePath,
      if (thumbnailRelativePath != null)
        'thumbnail_relative_path': thumbnailRelativePath,
      if (byteSize != null) 'byte_size': byteSize,
      if (sha256 != null) 'sha256': sha256,
      if (metaJson != null) 'meta_json': metaJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? id,
      Value<String>? mediaType,
      Value<String>? createdAtUtc,
      Value<String>? relativePath,
      Value<String?>? thumbnailRelativePath,
      Value<int>? byteSize,
      Value<String?>? sha256,
      Value<String?>? metaJson,
      Value<int>? rowid}) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      mediaType: mediaType ?? this.mediaType,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      relativePath: relativePath ?? this.relativePath,
      thumbnailRelativePath:
          thumbnailRelativePath ?? this.thumbnailRelativePath,
      byteSize: byteSize ?? this.byteSize,
      sha256: sha256 ?? this.sha256,
      metaJson: metaJson ?? this.metaJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<String>(createdAtUtc.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (thumbnailRelativePath.present) {
      map['thumbnail_relative_path'] =
          Variable<String>(thumbnailRelativePath.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (metaJson.present) {
      map['meta_json'] = Variable<String>(metaJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('mediaType: $mediaType, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('relativePath: $relativePath, ')
          ..write('thumbnailRelativePath: $thumbnailRelativePath, ')
          ..write('byteSize: $byteSize, ')
          ..write('sha256: $sha256, ')
          ..write('metaJson: $metaJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FitDatabase extends GeneratedDatabase {
  _$FitDatabase(QueryExecutor e) : super(e);
  $FitDatabaseManager get managers => $FitDatabaseManager(this);
  late final $WorkoutLogsTable workoutLogs = $WorkoutLogsTable(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $TaskTemplatesTable taskTemplates = $TaskTemplatesTable(this);
  late final $TaskActivationsTable taskActivations =
      $TaskActivationsTable(this);
  late final $TaskOccurrencesTable taskOccurrences =
      $TaskOccurrencesTable(this);
  late final $MilestonesTable milestones = $MilestonesTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        workoutLogs,
        exercises,
        tags,
        taskTemplates,
        taskActivations,
        taskOccurrences,
        milestones,
        attachments
      ];
}

typedef $$WorkoutLogsTableCreateCompanionBuilder = WorkoutLogsCompanion
    Function({
  required String id,
  required String date,
  Value<String?> boundTaskOccurrenceId,
  required String createdAtUtc,
  required String lastEditedAtUtc,
  required String json,
  Value<int> rowid,
});
typedef $$WorkoutLogsTableUpdateCompanionBuilder = WorkoutLogsCompanion
    Function({
  Value<String> id,
  Value<String> date,
  Value<String?> boundTaskOccurrenceId,
  Value<String> createdAtUtc,
  Value<String> lastEditedAtUtc,
  Value<String> json,
  Value<int> rowid,
});

class $$WorkoutLogsTableFilterComposer
    extends Composer<_$FitDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get boundTaskOccurrenceId => $composableBuilder(
      column: $table.boundTaskOccurrenceId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastEditedAtUtc => $composableBuilder(
      column: $table.lastEditedAtUtc,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$WorkoutLogsTableOrderingComposer
    extends Composer<_$FitDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get boundTaskOccurrenceId => $composableBuilder(
      column: $table.boundTaskOccurrenceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastEditedAtUtc => $composableBuilder(
      column: $table.lastEditedAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutLogsTableAnnotationComposer
    extends Composer<_$FitDatabase, $WorkoutLogsTable> {
  $$WorkoutLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get boundTaskOccurrenceId => $composableBuilder(
      column: $table.boundTaskOccurrenceId, builder: (column) => column);

  GeneratedColumn<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => column);

  GeneratedColumn<String> get lastEditedAtUtc => $composableBuilder(
      column: $table.lastEditedAtUtc, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$WorkoutLogsTableTableManager extends RootTableManager<
    _$FitDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, BaseReferences<_$FitDatabase, $WorkoutLogsTable, WorkoutLog>),
    WorkoutLog,
    PrefetchHooks Function()> {
  $$WorkoutLogsTableTableManager(_$FitDatabase db, $WorkoutLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String?> boundTaskOccurrenceId = const Value.absent(),
            Value<String> createdAtUtc = const Value.absent(),
            Value<String> lastEditedAtUtc = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutLogsCompanion(
            id: id,
            date: date,
            boundTaskOccurrenceId: boundTaskOccurrenceId,
            createdAtUtc: createdAtUtc,
            lastEditedAtUtc: lastEditedAtUtc,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String date,
            Value<String?> boundTaskOccurrenceId = const Value.absent(),
            required String createdAtUtc,
            required String lastEditedAtUtc,
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutLogsCompanion.insert(
            id: id,
            date: date,
            boundTaskOccurrenceId: boundTaskOccurrenceId,
            createdAtUtc: createdAtUtc,
            lastEditedAtUtc: lastEditedAtUtc,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutLogsTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $WorkoutLogsTable,
    WorkoutLog,
    $$WorkoutLogsTableFilterComposer,
    $$WorkoutLogsTableOrderingComposer,
    $$WorkoutLogsTableAnnotationComposer,
    $$WorkoutLogsTableCreateCompanionBuilder,
    $$WorkoutLogsTableUpdateCompanionBuilder,
    (WorkoutLog, BaseReferences<_$FitDatabase, $WorkoutLogsTable, WorkoutLog>),
    WorkoutLog,
    PrefetchHooks Function()>;
typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required String name,
  required int deprecated,
  required String json,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<int> deprecated,
  Value<String> json,
  Value<int> rowid,
});

class $$ExercisesTableFilterComposer
    extends Composer<_$FitDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deprecated => $composableBuilder(
      column: $table.deprecated, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$FitDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deprecated => $composableBuilder(
      column: $table.deprecated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$FitDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get deprecated => $composableBuilder(
      column: $table.deprecated, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$ExercisesTableTableManager extends RootTableManager<
    _$FitDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, BaseReferences<_$FitDatabase, $ExercisesTable, Exercise>),
    Exercise,
    PrefetchHooks Function()> {
  $$ExercisesTableTableManager(_$FitDatabase db, $ExercisesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> deprecated = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion(
            id: id,
            name: name,
            deprecated: deprecated,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required int deprecated,
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              ExercisesCompanion.insert(
            id: id,
            name: name,
            deprecated: deprecated,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ExercisesTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $ExercisesTable,
    Exercise,
    $$ExercisesTableFilterComposer,
    $$ExercisesTableOrderingComposer,
    $$ExercisesTableAnnotationComposer,
    $$ExercisesTableCreateCompanionBuilder,
    $$ExercisesTableUpdateCompanionBuilder,
    (Exercise, BaseReferences<_$FitDatabase, $ExercisesTable, Exercise>),
    Exercise,
    PrefetchHooks Function()>;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String name,
  required String json,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> json,
  Value<int> rowid,
});

class $$TagsTableFilterComposer extends Composer<_$FitDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$TagsTableOrderingComposer extends Composer<_$FitDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$TagsTableAnnotationComposer
    extends Composer<_$FitDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$TagsTableTableManager extends RootTableManager<
    _$FitDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, BaseReferences<_$FitDatabase, $TagsTable, Tag>),
    Tag,
    PrefetchHooks Function()> {
  $$TagsTableTableManager(_$FitDatabase db, $TagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion(
            id: id,
            name: name,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              TagsCompanion.insert(
            id: id,
            name: name,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TagsTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $TagsTable,
    Tag,
    $$TagsTableFilterComposer,
    $$TagsTableOrderingComposer,
    $$TagsTableAnnotationComposer,
    $$TagsTableCreateCompanionBuilder,
    $$TagsTableUpdateCompanionBuilder,
    (Tag, BaseReferences<_$FitDatabase, $TagsTable, Tag>),
    Tag,
    PrefetchHooks Function()>;
typedef $$TaskTemplatesTableCreateCompanionBuilder = TaskTemplatesCompanion
    Function({
  required String id,
  required String title,
  Value<String?> description,
  required String json,
  Value<int> rowid,
});
typedef $$TaskTemplatesTableUpdateCompanionBuilder = TaskTemplatesCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String> json,
  Value<int> rowid,
});

class $$TaskTemplatesTableFilterComposer
    extends Composer<_$FitDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$TaskTemplatesTableOrderingComposer
    extends Composer<_$FitDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$TaskTemplatesTableAnnotationComposer
    extends Composer<_$FitDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$TaskTemplatesTableTableManager extends RootTableManager<
    _$FitDatabase,
    $TaskTemplatesTable,
    TaskTemplate,
    $$TaskTemplatesTableFilterComposer,
    $$TaskTemplatesTableOrderingComposer,
    $$TaskTemplatesTableAnnotationComposer,
    $$TaskTemplatesTableCreateCompanionBuilder,
    $$TaskTemplatesTableUpdateCompanionBuilder,
    (
      TaskTemplate,
      BaseReferences<_$FitDatabase, $TaskTemplatesTable, TaskTemplate>
    ),
    TaskTemplate,
    PrefetchHooks Function()> {
  $$TaskTemplatesTableTableManager(_$FitDatabase db, $TaskTemplatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskTemplatesCompanion(
            id: id,
            title: title,
            description: description,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskTemplatesCompanion.insert(
            id: id,
            title: title,
            description: description,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TaskTemplatesTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $TaskTemplatesTable,
    TaskTemplate,
    $$TaskTemplatesTableFilterComposer,
    $$TaskTemplatesTableOrderingComposer,
    $$TaskTemplatesTableAnnotationComposer,
    $$TaskTemplatesTableCreateCompanionBuilder,
    $$TaskTemplatesTableUpdateCompanionBuilder,
    (
      TaskTemplate,
      BaseReferences<_$FitDatabase, $TaskTemplatesTable, TaskTemplate>
    ),
    TaskTemplate,
    PrefetchHooks Function()>;
typedef $$TaskActivationsTableCreateCompanionBuilder = TaskActivationsCompanion
    Function({
  required String id,
  required String templateId,
  required String startDate,
  required String createdAtUtc,
  required String json,
  Value<int> rowid,
});
typedef $$TaskActivationsTableUpdateCompanionBuilder = TaskActivationsCompanion
    Function({
  Value<String> id,
  Value<String> templateId,
  Value<String> startDate,
  Value<String> createdAtUtc,
  Value<String> json,
  Value<int> rowid,
});

class $$TaskActivationsTableFilterComposer
    extends Composer<_$FitDatabase, $TaskActivationsTable> {
  $$TaskActivationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$TaskActivationsTableOrderingComposer
    extends Composer<_$FitDatabase, $TaskActivationsTable> {
  $$TaskActivationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startDate => $composableBuilder(
      column: $table.startDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$TaskActivationsTableAnnotationComposer
    extends Composer<_$FitDatabase, $TaskActivationsTable> {
  $$TaskActivationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
      column: $table.templateId, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$TaskActivationsTableTableManager extends RootTableManager<
    _$FitDatabase,
    $TaskActivationsTable,
    TaskActivation,
    $$TaskActivationsTableFilterComposer,
    $$TaskActivationsTableOrderingComposer,
    $$TaskActivationsTableAnnotationComposer,
    $$TaskActivationsTableCreateCompanionBuilder,
    $$TaskActivationsTableUpdateCompanionBuilder,
    (
      TaskActivation,
      BaseReferences<_$FitDatabase, $TaskActivationsTable, TaskActivation>
    ),
    TaskActivation,
    PrefetchHooks Function()> {
  $$TaskActivationsTableTableManager(
      _$FitDatabase db, $TaskActivationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskActivationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskActivationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskActivationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> templateId = const Value.absent(),
            Value<String> startDate = const Value.absent(),
            Value<String> createdAtUtc = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskActivationsCompanion(
            id: id,
            templateId: templateId,
            startDate: startDate,
            createdAtUtc: createdAtUtc,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String templateId,
            required String startDate,
            required String createdAtUtc,
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskActivationsCompanion.insert(
            id: id,
            templateId: templateId,
            startDate: startDate,
            createdAtUtc: createdAtUtc,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TaskActivationsTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $TaskActivationsTable,
    TaskActivation,
    $$TaskActivationsTableFilterComposer,
    $$TaskActivationsTableOrderingComposer,
    $$TaskActivationsTableAnnotationComposer,
    $$TaskActivationsTableCreateCompanionBuilder,
    $$TaskActivationsTableUpdateCompanionBuilder,
    (
      TaskActivation,
      BaseReferences<_$FitDatabase, $TaskActivationsTable, TaskActivation>
    ),
    TaskActivation,
    PrefetchHooks Function()>;
typedef $$TaskOccurrencesTableCreateCompanionBuilder = TaskOccurrencesCompanion
    Function({
  required String id,
  required String activationId,
  required String date,
  Value<String?> boundLogId,
  Value<bool> suppressed,
  required String json,
  Value<int> rowid,
});
typedef $$TaskOccurrencesTableUpdateCompanionBuilder = TaskOccurrencesCompanion
    Function({
  Value<String> id,
  Value<String> activationId,
  Value<String> date,
  Value<String?> boundLogId,
  Value<bool> suppressed,
  Value<String> json,
  Value<int> rowid,
});

class $$TaskOccurrencesTableFilterComposer
    extends Composer<_$FitDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activationId => $composableBuilder(
      column: $table.activationId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get boundLogId => $composableBuilder(
      column: $table.boundLogId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get suppressed => $composableBuilder(
      column: $table.suppressed, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$TaskOccurrencesTableOrderingComposer
    extends Composer<_$FitDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activationId => $composableBuilder(
      column: $table.activationId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get boundLogId => $composableBuilder(
      column: $table.boundLogId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get suppressed => $composableBuilder(
      column: $table.suppressed, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$TaskOccurrencesTableAnnotationComposer
    extends Composer<_$FitDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get activationId => $composableBuilder(
      column: $table.activationId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get boundLogId => $composableBuilder(
      column: $table.boundLogId, builder: (column) => column);

  GeneratedColumn<bool> get suppressed => $composableBuilder(
      column: $table.suppressed, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$TaskOccurrencesTableTableManager extends RootTableManager<
    _$FitDatabase,
    $TaskOccurrencesTable,
    TaskOccurrence,
    $$TaskOccurrencesTableFilterComposer,
    $$TaskOccurrencesTableOrderingComposer,
    $$TaskOccurrencesTableAnnotationComposer,
    $$TaskOccurrencesTableCreateCompanionBuilder,
    $$TaskOccurrencesTableUpdateCompanionBuilder,
    (
      TaskOccurrence,
      BaseReferences<_$FitDatabase, $TaskOccurrencesTable, TaskOccurrence>
    ),
    TaskOccurrence,
    PrefetchHooks Function()> {
  $$TaskOccurrencesTableTableManager(
      _$FitDatabase db, $TaskOccurrencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskOccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskOccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskOccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> activationId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String?> boundLogId = const Value.absent(),
            Value<bool> suppressed = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskOccurrencesCompanion(
            id: id,
            activationId: activationId,
            date: date,
            boundLogId: boundLogId,
            suppressed: suppressed,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String activationId,
            required String date,
            Value<String?> boundLogId = const Value.absent(),
            Value<bool> suppressed = const Value.absent(),
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskOccurrencesCompanion.insert(
            id: id,
            activationId: activationId,
            date: date,
            boundLogId: boundLogId,
            suppressed: suppressed,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TaskOccurrencesTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $TaskOccurrencesTable,
    TaskOccurrence,
    $$TaskOccurrencesTableFilterComposer,
    $$TaskOccurrencesTableOrderingComposer,
    $$TaskOccurrencesTableAnnotationComposer,
    $$TaskOccurrencesTableCreateCompanionBuilder,
    $$TaskOccurrencesTableUpdateCompanionBuilder,
    (
      TaskOccurrence,
      BaseReferences<_$FitDatabase, $TaskOccurrencesTable, TaskOccurrence>
    ),
    TaskOccurrence,
    PrefetchHooks Function()>;
typedef $$MilestonesTableCreateCompanionBuilder = MilestonesCompanion Function({
  required String id,
  required String dedupKey,
  required String type,
  required String exerciseId,
  required String logId,
  required double metricValue,
  required String createdAtUtc,
  Value<String?> deletedAtUtc,
  required String json,
  Value<int> rowid,
});
typedef $$MilestonesTableUpdateCompanionBuilder = MilestonesCompanion Function({
  Value<String> id,
  Value<String> dedupKey,
  Value<String> type,
  Value<String> exerciseId,
  Value<String> logId,
  Value<double> metricValue,
  Value<String> createdAtUtc,
  Value<String?> deletedAtUtc,
  Value<String> json,
  Value<int> rowid,
});

class $$MilestonesTableFilterComposer
    extends Composer<_$FitDatabase, $MilestonesTable> {
  $$MilestonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dedupKey => $composableBuilder(
      column: $table.dedupKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logId => $composableBuilder(
      column: $table.logId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get metricValue => $composableBuilder(
      column: $table.metricValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deletedAtUtc => $composableBuilder(
      column: $table.deletedAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));
}

class $$MilestonesTableOrderingComposer
    extends Composer<_$FitDatabase, $MilestonesTable> {
  $$MilestonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dedupKey => $composableBuilder(
      column: $table.dedupKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logId => $composableBuilder(
      column: $table.logId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get metricValue => $composableBuilder(
      column: $table.metricValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deletedAtUtc => $composableBuilder(
      column: $table.deletedAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));
}

class $$MilestonesTableAnnotationComposer
    extends Composer<_$FitDatabase, $MilestonesTable> {
  $$MilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dedupKey =>
      $composableBuilder(column: $table.dedupKey, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<String> get logId =>
      $composableBuilder(column: $table.logId, builder: (column) => column);

  GeneratedColumn<double> get metricValue => $composableBuilder(
      column: $table.metricValue, builder: (column) => column);

  GeneratedColumn<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => column);

  GeneratedColumn<String> get deletedAtUtc => $composableBuilder(
      column: $table.deletedAtUtc, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$MilestonesTableTableManager extends RootTableManager<
    _$FitDatabase,
    $MilestonesTable,
    Milestone,
    $$MilestonesTableFilterComposer,
    $$MilestonesTableOrderingComposer,
    $$MilestonesTableAnnotationComposer,
    $$MilestonesTableCreateCompanionBuilder,
    $$MilestonesTableUpdateCompanionBuilder,
    (Milestone, BaseReferences<_$FitDatabase, $MilestonesTable, Milestone>),
    Milestone,
    PrefetchHooks Function()> {
  $$MilestonesTableTableManager(_$FitDatabase db, $MilestonesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> dedupKey = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<String> logId = const Value.absent(),
            Value<double> metricValue = const Value.absent(),
            Value<String> createdAtUtc = const Value.absent(),
            Value<String?> deletedAtUtc = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MilestonesCompanion(
            id: id,
            dedupKey: dedupKey,
            type: type,
            exerciseId: exerciseId,
            logId: logId,
            metricValue: metricValue,
            createdAtUtc: createdAtUtc,
            deletedAtUtc: deletedAtUtc,
            json: json,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String dedupKey,
            required String type,
            required String exerciseId,
            required String logId,
            required double metricValue,
            required String createdAtUtc,
            Value<String?> deletedAtUtc = const Value.absent(),
            required String json,
            Value<int> rowid = const Value.absent(),
          }) =>
              MilestonesCompanion.insert(
            id: id,
            dedupKey: dedupKey,
            type: type,
            exerciseId: exerciseId,
            logId: logId,
            metricValue: metricValue,
            createdAtUtc: createdAtUtc,
            deletedAtUtc: deletedAtUtc,
            json: json,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MilestonesTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $MilestonesTable,
    Milestone,
    $$MilestonesTableFilterComposer,
    $$MilestonesTableOrderingComposer,
    $$MilestonesTableAnnotationComposer,
    $$MilestonesTableCreateCompanionBuilder,
    $$MilestonesTableUpdateCompanionBuilder,
    (Milestone, BaseReferences<_$FitDatabase, $MilestonesTable, Milestone>),
    Milestone,
    PrefetchHooks Function()>;
typedef $$AttachmentsTableCreateCompanionBuilder = AttachmentsCompanion
    Function({
  required String id,
  required String mediaType,
  required String createdAtUtc,
  required String relativePath,
  Value<String?> thumbnailRelativePath,
  required int byteSize,
  Value<String?> sha256,
  Value<String?> metaJson,
  Value<int> rowid,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> id,
  Value<String> mediaType,
  Value<String> createdAtUtc,
  Value<String> relativePath,
  Value<String?> thumbnailRelativePath,
  Value<int> byteSize,
  Value<String?> sha256,
  Value<String?> metaJson,
  Value<int> rowid,
});

class $$AttachmentsTableFilterComposer
    extends Composer<_$FitDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailRelativePath => $composableBuilder(
      column: $table.thumbnailRelativePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get byteSize => $composableBuilder(
      column: $table.byteSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metaJson => $composableBuilder(
      column: $table.metaJson, builder: (column) => ColumnFilters(column));
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$FitDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relativePath => $composableBuilder(
      column: $table.relativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailRelativePath => $composableBuilder(
      column: $table.thumbnailRelativePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get byteSize => $composableBuilder(
      column: $table.byteSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sha256 => $composableBuilder(
      column: $table.sha256, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metaJson => $composableBuilder(
      column: $table.metaJson, builder: (column) => ColumnOrderings(column));
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$FitDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get createdAtUtc => $composableBuilder(
      column: $table.createdAtUtc, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
      column: $table.relativePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailRelativePath => $composableBuilder(
      column: $table.thumbnailRelativePath, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get metaJson =>
      $composableBuilder(column: $table.metaJson, builder: (column) => column);
}

class $$AttachmentsTableTableManager extends RootTableManager<
    _$FitDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (Attachment, BaseReferences<_$FitDatabase, $AttachmentsTable, Attachment>),
    Attachment,
    PrefetchHooks Function()> {
  $$AttachmentsTableTableManager(_$FitDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> createdAtUtc = const Value.absent(),
            Value<String> relativePath = const Value.absent(),
            Value<String?> thumbnailRelativePath = const Value.absent(),
            Value<int> byteSize = const Value.absent(),
            Value<String?> sha256 = const Value.absent(),
            Value<String?> metaJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            id: id,
            mediaType: mediaType,
            createdAtUtc: createdAtUtc,
            relativePath: relativePath,
            thumbnailRelativePath: thumbnailRelativePath,
            byteSize: byteSize,
            sha256: sha256,
            metaJson: metaJson,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String mediaType,
            required String createdAtUtc,
            required String relativePath,
            Value<String?> thumbnailRelativePath = const Value.absent(),
            required int byteSize,
            Value<String?> sha256 = const Value.absent(),
            Value<String?> metaJson = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            id: id,
            mediaType: mediaType,
            createdAtUtc: createdAtUtc,
            relativePath: relativePath,
            thumbnailRelativePath: thumbnailRelativePath,
            byteSize: byteSize,
            sha256: sha256,
            metaJson: metaJson,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$FitDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (Attachment, BaseReferences<_$FitDatabase, $AttachmentsTable, Attachment>),
    Attachment,
    PrefetchHooks Function()>;

class $FitDatabaseManager {
  final _$FitDatabase _db;
  $FitDatabaseManager(this._db);
  $$WorkoutLogsTableTableManager get workoutLogs =>
      $$WorkoutLogsTableTableManager(_db, _db.workoutLogs);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$TaskTemplatesTableTableManager get taskTemplates =>
      $$TaskTemplatesTableTableManager(_db, _db.taskTemplates);
  $$TaskActivationsTableTableManager get taskActivations =>
      $$TaskActivationsTableTableManager(_db, _db.taskActivations);
  $$TaskOccurrencesTableTableManager get taskOccurrences =>
      $$TaskOccurrencesTableTableManager(_db, _db.taskOccurrences);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db, _db.milestones);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
}
