import 'dart:io';

import 'package:aiwa_core/fit_storage.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  group('Task storage migration', () {
    late Directory tempDir;
    late FitStoragePaths paths;

    setUp(() async {
      tempDir =
          await Directory.systemTemp.createTemp('task_storage_migration_');
      paths = FitStoragePaths.fromAppDocumentsDir(tempDir);
      await paths.ensureInitialized();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('drops legacy plan schema and preserves task schema', () async {
      final legacyDb = sqlite.sqlite3.open(paths.dbFile.path);
      legacyDb.execute('PRAGMA user_version = 2;');
      legacyDb.execute('''
        CREATE TABLE workout_logs (
          id TEXT PRIMARY KEY NOT NULL,
          date TEXT NOT NULL,
          bound_task_occurrence_id TEXT,
          bound_plan_entry_id TEXT,
          created_at_utc TEXT NOT NULL,
          last_edited_at_utc TEXT NOT NULL,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE exercises (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          deprecated INTEGER NOT NULL,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE tags (
          id TEXT PRIMARY KEY NOT NULL,
          name TEXT NOT NULL,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE task_templates (
          id TEXT PRIMARY KEY NOT NULL,
          title TEXT NOT NULL,
          description TEXT,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE task_activations (
          id TEXT PRIMARY KEY NOT NULL,
          template_id TEXT NOT NULL,
          start_date TEXT NOT NULL,
          created_at_utc TEXT NOT NULL,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE task_occurrences (
          id TEXT PRIMARY KEY NOT NULL,
          activation_id TEXT NOT NULL,
          date TEXT NOT NULL,
          bound_log_id TEXT,
          suppressed INTEGER NOT NULL DEFAULT 0,
          json TEXT NOT NULL,
          UNIQUE(activation_id, date)
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE plan_templates (
          id TEXT PRIMARY KEY NOT NULL,
          title TEXT NOT NULL,
          type TEXT NOT NULL,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE plan_instances (
          id TEXT PRIMARY KEY NOT NULL,
          template_id TEXT NOT NULL,
          start_date TEXT NOT NULL,
          created_at_utc TEXT NOT NULL,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE plan_entries (
          id TEXT PRIMARY KEY NOT NULL,
          plan_instance_id TEXT NOT NULL,
          date TEXT NOT NULL,
          bound_log_id TEXT,
          json TEXT NOT NULL,
          UNIQUE(plan_instance_id, date)
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE milestones (
          id TEXT PRIMARY KEY NOT NULL,
          dedup_key TEXT NOT NULL UNIQUE,
          type TEXT NOT NULL,
          exercise_id TEXT NOT NULL,
          log_id TEXT NOT NULL,
          metric_value REAL NOT NULL,
          created_at_utc TEXT NOT NULL,
          deleted_at_utc TEXT,
          json TEXT NOT NULL
        )
      ''');
      legacyDb.execute('''
        CREATE TABLE attachments (
          id TEXT PRIMARY KEY NOT NULL,
          media_type TEXT NOT NULL,
          created_at_utc TEXT NOT NULL,
          relative_path TEXT NOT NULL,
          thumbnail_relative_path TEXT,
          byte_size INTEGER NOT NULL,
          sha256 TEXT,
          meta_json TEXT
        )
      ''');

      legacyDb.execute(
        '''
        INSERT INTO task_templates (id, title, description, json)
        VALUES (?, ?, ?, ?)
        ''',
        <Object?>[
          'task_tpl_1',
          'Upper day',
          null,
          '{"id":"task_tpl_1","title":"Upper day"}',
        ],
      );
      legacyDb.execute(
        '''
        INSERT INTO task_activations (id, template_id, start_date, created_at_utc, json)
        VALUES (?, ?, ?, ?, ?)
        ''',
        <Object?>[
          'task_activation_1',
          'task_tpl_1',
          '2026-03-10',
          '2026-03-10T08:00:00.000Z',
          '{"id":"task_activation_1","templateId":"task_tpl_1","startDate":"2026-03-10"}',
        ],
      );
      legacyDb.execute(
        '''
        INSERT INTO task_occurrences (id, activation_id, date, bound_log_id, suppressed, json)
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          'task_occ_1',
          'task_activation_1',
          '2026-03-11',
          'log_1',
          0,
          '{"id":"task_occ_1","activationId":"task_activation_1","date":"2026-03-11","boundLogId":"log_1","suppressed":false}',
        ],
      );
      legacyDb.execute(
        '''
        INSERT INTO plan_templates (id, title, type, json)
        VALUES (?, ?, ?, ?)
        ''',
        <Object?>[
          'plan_tpl_ignored',
          'Legacy plan',
          'training_plan',
          '{"id":"plan_tpl_ignored","title":"Legacy plan"}',
        ],
      );
      legacyDb.execute(
        '''
        INSERT INTO workout_logs (id, date, bound_task_occurrence_id, bound_plan_entry_id, created_at_utc, last_edited_at_utc, json)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
        <Object?>[
          'log_1',
          '2026-03-11',
          'task_occ_1',
          'legacy_plan_entry_1',
          '2026-03-11T08:00:00.000Z',
          '2026-03-11T08:00:00.000Z',
          '{"id":"log_1","date":"2026-03-11","boundTaskOccurrenceId":"task_occ_1","createdAtUtc":"2026-03-11T08:00:00.000Z","lastEditedAtUtc":"2026-03-11T08:00:00.000Z","blocks":[]}',
        ],
      );
      legacyDb.dispose();

      final db = FitDatabase.openFile(paths.dbFile);
      addTearDown(() => db.close());
      await db.customSelect('SELECT 1').get();

      expect(db.schemaVersion, 3);

      final templates = await db.select(db.taskTemplates).get();
      expect(templates, hasLength(1));
      expect(templates.single.id, 'task_tpl_1');

      final activations = await db.select(db.taskActivations).get();
      expect(activations, hasLength(1));
      expect(activations.single.id, 'task_activation_1');

      final occurrences = await db.select(db.taskOccurrences).get();
      expect(occurrences, hasLength(1));
      expect(occurrences.single.id, 'task_occ_1');
      expect(occurrences.single.boundLogId, 'log_1');

      final tables = await db
          .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
          .get();
      final tableNames = tables.map((row) => row.read<String>('name')).toSet();
      expect(tableNames, isNot(contains('plan_templates')));
      expect(tableNames, isNot(contains('plan_instances')));
      expect(tableNames, isNot(contains('plan_entries')));

      final columns =
          await db.customSelect('PRAGMA table_info(workout_logs)').get();
      final columnNames =
          columns.map((row) => row.read<String>('name')).toSet();
      expect(columnNames, contains('bound_task_occurrence_id'));
      expect(columnNames, isNot(contains('bound_plan_entry_id')));

      final logs = await (db.select(db.workoutLogs)
            ..where((t) => t.id.equals('log_1')))
          .getSingle();
      expect(logs.boundTaskOccurrenceId, 'task_occ_1');
    });
  });
}
