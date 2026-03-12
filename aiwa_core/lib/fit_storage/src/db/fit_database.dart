import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../errors/storage_exception.dart';

part 'fit_database.g.dart';

class WorkoutLogs extends Table {
  @override
  String get tableName => 'workout_logs';

  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get boundTaskOccurrenceId =>
      text().named('bound_task_occurrence_id').nullable()();
  TextColumn get createdAtUtc => text().named('created_at_utc')();
  TextColumn get lastEditedAtUtc => text().named('last_edited_at_utc')();
  TextColumn get json => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class Exercises extends Table {
  @override
  String get tableName => 'exercises';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get deprecated => integer()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class Tags extends Table {
  @override
  String get tableName => 'tags';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class TaskTemplates extends Table {
  @override
  String get tableName => 'task_templates';

  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class TaskActivations extends Table {
  @override
  String get tableName => 'task_activations';

  TextColumn get id => text()();
  TextColumn get templateId => text().named('template_id')();
  TextColumn get startDate => text().named('start_date')();
  TextColumn get createdAtUtc => text().named('created_at_utc')();
  TextColumn get json => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class TaskOccurrences extends Table {
  @override
  String get tableName => 'task_occurrences';

  TextColumn get id => text()();
  TextColumn get activationId => text().named('activation_id')();
  TextColumn get date => text()();
  TextColumn get boundLogId => text().named('bound_log_id').nullable()();
  BoolColumn get suppressed =>
      boolean().named('suppressed').withDefault(const Constant(false))();
  TextColumn get json => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
        <Column<Object>>{activationId, date},
      ];
}

class Milestones extends Table {
  @override
  String get tableName => 'milestones';

  TextColumn get id => text()();
  TextColumn get dedupKey => text().named('dedup_key').unique()();
  TextColumn get type => text()();
  TextColumn get exerciseId => text().named('exercise_id')();
  TextColumn get logId => text().named('log_id')();
  RealColumn get metricValue => real().named('metric_value')();
  TextColumn get createdAtUtc => text().named('created_at_utc')();
  TextColumn get deletedAtUtc => text().named('deleted_at_utc').nullable()();
  TextColumn get json => text()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

class Attachments extends Table {
  @override
  String get tableName => 'attachments';

  TextColumn get id => text()();
  TextColumn get mediaType => text().named('media_type')();
  TextColumn get createdAtUtc => text().named('created_at_utc')();
  TextColumn get relativePath => text().named('relative_path')();
  TextColumn get thumbnailRelativePath =>
      text().named('thumbnail_relative_path').nullable()();
  IntColumn get byteSize => integer().named('byte_size')();
  TextColumn get sha256 => text().nullable()();
  TextColumn get metaJson => text().named('meta_json').nullable()();

  @override
  Set<Column<Object>>? get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(
  tables: <Type>[
    WorkoutLogs,
    Exercises,
    Tags,
    TaskTemplates,
    TaskActivations,
    TaskOccurrences,
    Milestones,
    Attachments,
  ],
)
class FitDatabase extends _$FitDatabase {
  FitDatabase(super.e);

  factory FitDatabase.openFile(File file) {
    try {
      return FitDatabase(NativeDatabase(file));
    } catch (error) {
      throw StorageException(
        errorCode: StorageException.dbOpenFailed,
        message: 'Failed to open fit.sqlite',
        context: <String, Object?>{
          'path': file.path,
          'error': error.toString(),
        },
      );
    }
  }

  factory FitDatabase.inMemory() => FitDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          try {
            if (from < 3) {
              await _ensureTaskSchema(m);
              await _dropLegacyPlanIndexes();
              await _dropLegacyPlanTables();
              await _rebuildWorkoutLogsWithoutLegacyPlanBinding();
            }
            await _createIndexes();
          } catch (error) {
            throw StorageException(
              errorCode: StorageException.dbMigrationFailed,
              message: 'Failed to migrate fit.sqlite schema',
              context: <String, Object?>{
                'from': from,
                'to': to,
                'error': error.toString(),
              },
            );
          }
        },
      );

  Future<void> _ensureTaskSchema(Migrator m) async {
    if (!await _columnExists('workout_logs', 'bound_task_occurrence_id')) {
      await m.addColumn(workoutLogs, workoutLogs.boundTaskOccurrenceId);
    }
    if (!await _tableExists('task_templates')) {
      await m.createTable(taskTemplates);
    }
    if (!await _tableExists('task_activations')) {
      await m.createTable(taskActivations);
    }
    if (!await _tableExists('task_occurrences')) {
      await m.createTable(taskOccurrences);
    }
  }

  Future<void> _dropLegacyPlanIndexes() async {
    const statements = <String>[
      'DROP INDEX IF EXISTS idx_workout_logs_bound_plan_entry_id',
      'DROP INDEX IF EXISTS idx_plan_templates_title',
      'DROP INDEX IF EXISTS idx_plan_templates_type',
      'DROP INDEX IF EXISTS idx_plan_instances_template_id',
      'DROP INDEX IF EXISTS idx_plan_instances_start_date',
      'DROP INDEX IF EXISTS idx_plan_entries_date',
      'DROP INDEX IF EXISTS idx_plan_entries_plan_instance_id',
      'DROP INDEX IF EXISTS idx_plan_entries_bound_log_id',
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }

  Future<void> _dropLegacyPlanTables() async {
    const statements = <String>[
      'DROP TABLE IF EXISTS plan_entries',
      'DROP TABLE IF EXISTS plan_instances',
      'DROP TABLE IF EXISTS plan_templates',
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }

  Future<void> _rebuildWorkoutLogsWithoutLegacyPlanBinding() async {
    final hasLegacyBindingColumn =
        await _columnExists('workout_logs', 'bound_plan_entry_id');
    final hasTaskBindingColumn =
        await _columnExists('workout_logs', 'bound_task_occurrence_id');
    if (!hasLegacyBindingColumn && hasTaskBindingColumn) {
      return;
    }

    await customStatement('''
      CREATE TABLE workout_logs_new (
        id TEXT PRIMARY KEY NOT NULL,
        date TEXT NOT NULL,
        bound_task_occurrence_id TEXT,
        created_at_utc TEXT NOT NULL,
        last_edited_at_utc TEXT NOT NULL,
        json TEXT NOT NULL
      )
    ''');

    await customStatement('''
      INSERT INTO workout_logs_new (
        id,
        date,
        bound_task_occurrence_id,
        created_at_utc,
        last_edited_at_utc,
        json
      )
      SELECT
        id,
        date,
        ${hasTaskBindingColumn ? 'bound_task_occurrence_id' : 'NULL'},
        created_at_utc,
        last_edited_at_utc,
        json
      FROM workout_logs
    ''');

    await customStatement('DROP TABLE workout_logs');
    await customStatement(
        'ALTER TABLE workout_logs_new RENAME TO workout_logs');
  }

  Future<bool> _tableExists(String tableName) async {
    final row = await customSelect(
      '''
      SELECT 1
      FROM sqlite_master
      WHERE type = 'table' AND name = ?
      LIMIT 1
      ''',
      variables: <Variable<Object>>[Variable<String>(tableName)],
    ).getSingleOrNull();
    return row != null;
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.any((row) => row.read<String>('name') == columnName);
  }

  Future<void> _createIndexes() async {
    const statements = <String>[
      'CREATE INDEX IF NOT EXISTS idx_workout_logs_date ON workout_logs(date)',
      'CREATE INDEX IF NOT EXISTS idx_workout_logs_bound_task_occurrence_id ON workout_logs(bound_task_occurrence_id)',
      'CREATE INDEX IF NOT EXISTS idx_workout_logs_last_edited_at_utc ON workout_logs(last_edited_at_utc)',
      'CREATE INDEX IF NOT EXISTS idx_exercises_deprecated ON exercises(deprecated)',
      'CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name)',
      'CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name)',
      'CREATE INDEX IF NOT EXISTS idx_task_templates_title ON task_templates(title)',
      'CREATE INDEX IF NOT EXISTS idx_task_activations_template_id ON task_activations(template_id)',
      'CREATE INDEX IF NOT EXISTS idx_task_activations_start_date ON task_activations(start_date)',
      'CREATE INDEX IF NOT EXISTS idx_task_occurrences_activation_id ON task_occurrences(activation_id)',
      'CREATE INDEX IF NOT EXISTS idx_task_occurrences_date ON task_occurrences(date)',
      'CREATE INDEX IF NOT EXISTS idx_task_occurrences_bound_log_id ON task_occurrences(bound_log_id)',
      'CREATE INDEX IF NOT EXISTS idx_attachments_relative_path ON attachments(relative_path)',
      'CREATE INDEX IF NOT EXISTS idx_attachments_thumbnail_relative_path ON attachments(thumbnail_relative_path)',
    ];

    for (final statement in statements) {
      await customStatement(statement);
    }
  }
}
