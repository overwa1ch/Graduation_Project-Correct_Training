// services_integration_test.dart
// Purpose: End-to-end service orchestration without UI
// Focus: config_sync → session_manager → event_bus → result_adapter flow

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/config_sync.dart';
import 'package:aiwa_app/services/session_manager.dart';
import 'package:aiwa_app/services/event_bus.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('services_integration_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Services Integration - Full Flow', () {
    test('config → session → event playback → result parsing', () async {
      // Step 1: Configure runtime settings
      final configPath = '${tempDir.path}/app_runtime.json';
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'strictness': 'strict'},
        pathOverride: configPath,
      );

      // Step 2: Read config back
      final config = await readAppRuntimeConfig(pathOverride: configPath);
      expect(config['engine'], equals('MoveNet'));
      expect(config['strictness'], equals('strict'));

      // Step 3: Create session
      final sessionRoot = '${tempDir.path}/session_001';
      await Directory(sessionRoot).create(recursive: true);

      // Step 4: Write session snapshot
      await writeRuntimeSnapshot(sessionRoot, config);

      final snapshotFile = File('$sessionRoot/configs_snapshot.json');
      expect(await snapshotFile.exists(), isTrue);

      final snapshot = jsonDecode(await snapshotFile.readAsString());
      expect(snapshot['engine'], equals('MoveNet'));

      // Step 5: Create fake event stream
      final jsonlPath = '$sessionRoot/stdout.jsonl';
      final jsonlFile = File(jsonlPath);
      await jsonlFile.writeAsString([
        jsonEncode({'event': 'START', 'input': {'path': 'test.mp4'}, 'params': <String, dynamic>{}}),
        jsonEncode({'event': 'PROGRESS', 'processed': 50, 'total': 100}),
        jsonEncode({
          'event': 'DONE',
          'artifacts': {'root': sessionRoot, 'result': '$sessionRoot/result.json'}
        }),
      ].join('\n'));

      // Step 6: Stream events
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.length, equals(3));
      expect(events[0]['event'], equals('START'));
      expect(events[1]['event'], equals('PROGRESS'));
      expect(events[2]['event'], equals('DONE'));

      // Step 7: Create result.json
      final resultPath = '${tempDir.path}/session_001/result.json';
      final resultJson = {
        'scores': {'overall': 85, 'form': 84, 'stability': 88, 'tempo': 83},
        'repCount': 12,
        'quality': {'lowConfidence': false, 'coverage': 0.89},
        'meta': {'engine': 'MoveNet', 'fps': 30},
      };
      await File(resultPath).writeAsString(jsonEncode(resultJson));

      // Step 8: Parse result via adapter
      final resultFile = File(resultPath);
      final parsedJson = jsonDecode(await resultFile.readAsString()) as Map<String, dynamic>;
      assertResultContract(parsedJson);
      final result = mapToLite(parsedJson);

      expect(result.total, equals(85));
      expect(result.reps, equals(12));
    });

    test('config changes do not affect active session snapshot', () async {
      // Create initial config
      final configPath = '${tempDir.path}/app_runtime.json';
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'strictness': 'strict'},
        pathOverride: configPath,
      );

      // Create session with snapshot
      final sessionRoot = '${tempDir.path}/session_001';
      await Directory(sessionRoot).create(recursive: true);

      final config1 = await readAppRuntimeConfig(pathOverride: configPath);
      await writeRuntimeSnapshot(sessionRoot, config1);

      // Modify config
      await writeAppRuntimeConfig(
        {'engine': 'BlazePose', 'strictness': 'lenient'},
        pathOverride: configPath,
      );

      // Verify snapshot is immutable
      final snapshotFile = File('$sessionRoot/configs_snapshot.json');
      final snapshot = jsonDecode(await snapshotFile.readAsString());
      expect(snapshot['engine'], equals('MoveNet')); // Original value
      expect(snapshot['strictness'], equals('strict')); // Original value
    });

    test('multiple sessions maintain isolation', () async {
      // Create two sessions with different configs
      final configPath1 = '${tempDir.path}/config1.json';
      final configPath2 = '${tempDir.path}/config2.json';

      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'strictness': 'strict'},
        pathOverride: configPath1,
      );

      await writeAppRuntimeConfig(
        {'engine': 'BlazePose', 'strictness': 'lenient'},
        pathOverride: configPath2,
      );

      // Create session 1
      final session1Root = '${tempDir.path}/session_001';
      await Directory(session1Root).create(recursive: true);
      final config1 = await readAppRuntimeConfig(pathOverride: configPath1);
      await writeRuntimeSnapshot(session1Root, config1);

      // Create session 2
      final session2Root = '${tempDir.path}/session_002';
      await Directory(session2Root).create(recursive: true);
      final config2 = await readAppRuntimeConfig(pathOverride: configPath2);
      await writeRuntimeSnapshot(session2Root, config2);

      // Verify isolation
      final snapshot1 = jsonDecode(
        await File('$session1Root/configs_snapshot.json').readAsString(),
      );
      final snapshot2 = jsonDecode(
        await File('$session2Root/configs_snapshot.json').readAsString(),
      );

      expect(snapshot1['engine'], equals('MoveNet'));
      expect(snapshot2['engine'], equals('BlazePose'));
    });
  });

  group('Services Integration - Error Propagation', () {
    test('bad config prevents session creation', () async {
      // Invalid config with bad enum
      final configPath = '${tempDir.path}/bad_config.json';
      final badConfig = {'engine': 'InvalidEngine', 'strictness': 'invalid'};
      await File(configPath).writeAsString(jsonEncode(badConfig));

      // Read should merge with defaults
      final config = await readAppRuntimeConfig(pathOverride: configPath);
      
      // Invalid values should fallback to defaults
      expect(config['engine'], equals('MoveNet')); // Default
      expect(config['strictness'], equals('strict')); // Default
    });

    test('event stream errors are surfaced', () async {
      // Create JSONL with error event
      final jsonlPath = '${tempDir.path}/error.jsonl';
      await File(jsonlPath).writeAsString([
        jsonEncode({'event': 'START', 'input': {'path': 'test.mp4'}, 'params': <String, dynamic>{}}),
        jsonEncode({'event': 'ERROR', 'code': '500_ANALYSIS', 'message': 'Analysis failed'}),
      ].join('\n'));

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(jsonlPath);

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.any((e) => e['event'] == 'ERROR'), isTrue);
      final errorEvent = events.firstWhere((e) => e['event'] == 'ERROR');
      expect(errorEvent['code'], equals('500_ANALYSIS'));
    });

    test('missing result.json is caught by adapter', () async {
      final sessionRoot = '${tempDir.path}/missing_session';
      await Directory(sessionRoot).create(recursive: true);
      expect(await File('$sessionRoot/result.json').exists(), isFalse);
      await expectLater(
        readResultJson(sessionRoot),
        throwsA(isA<ResultReadException>()),
      );
    });

    test('malformed result.json violates contract', () async {
      final resultPath = '${tempDir.path}/bad_result.json';
      final badResult = {'scores': {'overall': 85}}; // Missing required fields
      await File(resultPath).writeAsString(jsonEncode(badResult));

      final resultJson = jsonDecode(await File(resultPath).readAsString()) as Map<String, dynamic>;

      // Contract assertion should fail
      expect(
        () => assertResultContract(resultJson),
      throwsA(isA<SchemaMismatch>()),
      );
    });
  });

  group('Services Integration - Session Lifecycle', () {
    test('session cleanup preserves recent sessions', () async {
      // Create recent session using static method
      final recentSession = await SessionManager.createSessionRoot();
      expect(await Directory(recentSession).exists(), isTrue);

      // Cleanup with 7-day retention
      await SessionManager.cleanupExpired(days: 7);

      // Recent session should still exist
      expect(await Directory(recentSession).exists(), isTrue);
    });

    test('session contains required artifacts', () async {
      final sessionRoot = '${tempDir.path}/complete_session';
      await Directory(sessionRoot).create(recursive: true);

      // Write config snapshot
      final config = {'engine': 'MoveNet', 'strictness': 'strict'};
      await writeRuntimeSnapshot(sessionRoot, config);

      // Write stdout.jsonl
      final jsonlPath = '$sessionRoot/stdout.jsonl';
      await File(jsonlPath).writeAsString(
        jsonEncode({'event': 'START', 'input': {'path': 'test.mp4'}, 'params': <String, dynamic>{}}),
      );

      // Write result.json
      final resultPath = '$sessionRoot/result.json';
      final resultJson = {
        'scores': {'overall': 85, 'form': 84, 'stability': 88, 'tempo': 83},
        'repCount': 12,
        'quality': {'lowConfidence': false, 'coverage': 0.89},
        'meta': {'engine': 'MoveNet', 'fps': 30},
      };
      await File(resultPath).writeAsString(jsonEncode(resultJson));

      // Verify all artifacts exist
      expect(await File('$sessionRoot/configs_snapshot.json').exists(), isTrue);
      expect(await File(jsonlPath).exists(), isTrue);
      expect(await File(resultPath).exists(), isTrue);
    });
  });

  group('Services Integration - CLI Args Generation', () {
    test('buildCliArgs produces valid arguments', () async {
      final videoPath = '${tempDir.path}/test_video.mp4';
      final sessionRoot = '${tempDir.path}/session_cli';
      await Directory(sessionRoot).create(recursive: true);

      final args = buildCliArgs(
        pickedInput: videoPath,
        sessionRoot: sessionRoot,
      );

      expect(args.inputPath, equals(videoPath));
      expect(args.sessionRoot, equals(sessionRoot));
      expect(args.configPath, isNotEmpty);
    });

    test('CLI args include config snapshot path', () async {
      final sessionRoot = '${tempDir.path}/session_with_config';
      await Directory(sessionRoot).create(recursive: true);

      final config = {'engine': 'MoveNet', 'strictness': 'strict'};
      await writeRuntimeSnapshot(sessionRoot, config);

      final args = buildCliArgs(
        pickedInput: 'test.mp4',
        sessionRoot: sessionRoot,
        configPath: '$sessionRoot/configs_snapshot.json',
      );

      expect(args.configPath, equals('$sessionRoot/configs_snapshot.json'));
    });
  });

  group('Services Integration - Concurrent Operations', () {
    test('concurrent config reads are safe', () async {
      final configPath = '${tempDir.path}/concurrent_config.json';
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet'},
        pathOverride: configPath,
      );

      // Read concurrently
      final results = await Future.wait([
        readAppRuntimeConfig(pathOverride: configPath),
        readAppRuntimeConfig(pathOverride: configPath),
        readAppRuntimeConfig(pathOverride: configPath),
      ]);

      expect(results.length, equals(3));
      expect(results[0]['engine'], equals('MoveNet'));
      expect(results[1]['engine'], equals('MoveNet'));
      expect(results[2]['engine'], equals('MoveNet'));
    });

    test('concurrent session creation maintains uniqueness', () async {
      // Create sessions concurrently using static method
      final sessions = await Future.wait<String>([
        SessionManager.createSessionRoot(),
        SessionManager.createSessionRoot(),
        SessionManager.createSessionRoot(),
      ]);

      // All sessions should be unique
      expect(sessions.toSet().length, equals(3));

      // All should exist
      for (final session in sessions) {
        expect(await Directory(session).exists(), isTrue);
      }
    });
  });

  group('Services Integration - Real-World Patterns', () {
    test('complete analysis workflow', () async {
      // 1. User opens settings and changes config
      final configPath = '${tempDir.path}/user_config.json';
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'strictness': 'lenient', 'stride': 3},
        pathOverride: configPath,
      );

      // 2. User starts analysis - system creates session
      final sessionRoot = await SessionManager.createSessionRoot();

      // 3. System snapshots config
      final config = await readAppRuntimeConfig(pathOverride: configPath);
      await writeRuntimeSnapshot(sessionRoot, config);

      // 4. System builds CLI args
      final args = buildCliArgs(
        pickedInput: '/path/to/workout.mp4',
        sessionRoot: sessionRoot,
      );
      expect(args.inputPath, equals('/path/to/workout.mp4'));
      expect(args.sessionRoot, equals(sessionRoot));

      // 5. Analysis runs (simulated via JSONL)
      final jsonlPath = '$sessionRoot/stdout.jsonl';
      await File(jsonlPath).writeAsString([
        jsonEncode({'event': 'START', 'input': {'path': '/path/to/workout.mp4'}, 'params': <String, dynamic>{}}),
        jsonEncode({'event': 'PHASE', 'phase': 'load'}),
        jsonEncode({'event': 'PROGRESS', 'processed': 100, 'total': 200}),
        jsonEncode({'event': 'PROGRESS', 'processed': 200, 'total': 200}),
        jsonEncode({
          'event': 'DONE',
          'artifacts': {'root': sessionRoot, 'result': '$sessionRoot/result.json'}
        }),
      ].join('\n'));

      // 6. UI streams events
      final events = <Map<String, dynamic>>[];
      await for (final event in analysisEventsFromJsonlFile(jsonlPath)) {
        events.add(event);
      }

      expect(events.first['event'], equals('START'));
      expect(events.last['event'], equals('DONE'));

      // 7. UI parses result
      final resultPath = '$sessionRoot/result.json';
      final resultJson = {
        'scores': {'overall': 92, 'form': 90, 'stability': 95, 'tempo': 91},
        'repCount': 15,
        'quality': {'lowConfidence': false, 'coverage': 0.95},
        'meta': {'engine': 'MoveNet', 'fps': 30},
      };
      await File(resultPath).writeAsString(jsonEncode(resultJson));

      final parsed = jsonDecode(await File(resultPath).readAsString()) as Map<String, dynamic>;
      assertResultContract(parsed);
      final result = mapToLite(parsed);

      expect(result.total, equals(92));
      expect(result.reps, equals(15));

      // 8. User can start new analysis - old session preserved
      final sessionRoot2 = await SessionManager.createSessionRoot();
      expect(sessionRoot2, isNot(equals(sessionRoot)));
      expect(await Directory(sessionRoot).exists(), isTrue);
    });

    test('config sync after app restart', () async {
      final configPath = '${tempDir.path}/persistent_config.json';

      // First run: write config
      await writeAppRuntimeConfig(
        {'engine': 'BlazePose', 'strictness': 'strict'},
        pathOverride: configPath,
      );

      // Simulate app restart: read config
      final config = await readAppRuntimeConfig(pathOverride: configPath);
      expect(config['engine'], equals('BlazePose'));
      expect(config['strictness'], equals('strict'));

      // Config should persist across restarts
      final config2 = await readAppRuntimeConfig(pathOverride: configPath);
      expect(config2['engine'], equals('BlazePose'));
    });
  });
}

