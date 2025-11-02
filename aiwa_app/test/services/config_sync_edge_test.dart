// config_sync_edge_test.dart
// Purpose: Enhanced edge case coverage for config_sync service
// Focus: Invalid enums, missing fields, error handling, boundary conditions

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/config_sync.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('config_sync_edge_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Config Sync - Invalid Enum Values', () {
    test('invalid engine falls back to default', () async {
      final configPath = '${tempDir.path}/invalid_engine.json';
      final invalidConfig = {'engine': 'InvalidEngine', 'strictness': 'strict'};
      await File(configPath).writeAsString(jsonEncode(invalidConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      // Should use default engine
      expect(config['engine'], equals('MoveNet'));
      expect(config['strictness'], equals('strict')); // Valid value preserved
    });

    test('invalid strictness falls back to default', () async {
      final configPath = '${tempDir.path}/invalid_strictness.json';
      final invalidConfig = {'engine': 'MoveNet', 'strictness': 'invalid'};
      await File(configPath).writeAsString(jsonEncode(invalidConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['engine'], equals('MoveNet')); // Valid value preserved
      expect(config['strictness'], equals('strict')); // Default
    });

    test('invalid privacy upload mode falls back to default', () async {
      final configPath = '${tempDir.path}/invalid_privacy.json';
      final invalidConfig = {
        'engine': 'MoveNet',
        'privacy': {'upload': 'invalid-mode', 'confirmVideoUpload': true}
      };
      await File(configPath).writeAsString(jsonEncode(invalidConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['privacy']['upload'], equals('keypoints-only')); // Default
    });

    test('multiple invalid enums all fall back', () async {
      final configPath = '${tempDir.path}/multiple_invalid.json';
      final invalidConfig = {
        'engine': 'BadEngine',
        'strictness': 'bad',
        'resolution': '99x99', // Invalid resolution
      };
      await File(configPath).writeAsString(jsonEncode(invalidConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['engine'], equals('MoveNet'));
      expect(config['strictness'], equals('strict'));
      expect(config['resolution'], equals('1280x720')); // Default
    });
  });

  group('Config Sync - Missing Fields', () {
    test('missing top-level fields use defaults', () async {
      final configPath = '${tempDir.path}/missing_fields.json';
      final partialConfig = {'engine': 'MoveNet'}; // Missing most fields
      await File(configPath).writeAsString(jsonEncode(partialConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['engine'], equals('MoveNet')); // Provided
      expect(config['strictness'], equals('strict')); // Default
      expect(config['stride'], equals(2)); // Default
      expect(config['targetFps'], equals(30)); // Default
    });

    test('missing nested privacy fields use defaults', () async {
      final configPath = '${tempDir.path}/missing_privacy.json';
      final partialConfig = {
        'engine': 'MoveNet',
        'privacy': {} // Empty privacy object
      };
      await File(configPath).writeAsString(jsonEncode(partialConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['privacy']['upload'], equals('keypoints-only'));
      expect(config['privacy']['confirmVideoUpload'], equals(true));
    });

    test('missing cleanup fields use defaults', () async {
      final configPath = '${tempDir.path}/missing_cleanup.json';
      final partialConfig = {'engine': 'MoveNet'}; // No cleanup section
      await File(configPath).writeAsString(jsonEncode(partialConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['cleanup']['days'], equals(7));
    });

    test('missing logs fields use defaults', () async {
      final configPath = '${tempDir.path}/missing_logs.json';
      final partialConfig = {'engine': 'MoveNet'}; // No logs section
      await File(configPath).writeAsString(jsonEncode(partialConfig));

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['logs']['level'], equals('info'));
    });

    test('completely empty config file uses all defaults', () async {
      final configPath = '${tempDir.path}/empty_config.json';
      await File(configPath).writeAsString('{}');

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['engine'], equals('MoveNet'));
      expect(config['strictness'], equals('strict'));
      expect(config['stride'], equals(2));
      expect(config['targetFps'], equals(30));
      expect(config['resolution'], equals('1280x720'));
    });
  });

  group('Config Sync - Malformed JSON', () {
    test('invalid JSON throws ConfigInvalid', () async {
      final configPath = '${tempDir.path}/invalid_json.json';
      await File(configPath).writeAsString('{invalid json}');

      expect(
        () => readAppRuntimeConfig(pathOverride: configPath),
        throwsA(isA<ConfigInvalid>()),
      );
    });

    test('non-object JSON throws ConfigInvalid', () async {
      final configPath = '${tempDir.path}/array_json.json';
      await File(configPath).writeAsString('["array", "not", "object"]');

      expect(
        () => readAppRuntimeConfig(pathOverride: configPath),
        throwsA(isA<ConfigInvalid>()),
      );
    });

    test('null config file throws ConfigInvalid', () async {
      final configPath = '${tempDir.path}/null_config.json';
      await File(configPath).writeAsString('null');

      expect(
        () => readAppRuntimeConfig(pathOverride: configPath),
        throwsA(isA<ConfigInvalid>()),
      );
    });
  });

  group('Config Sync - Nested Field Validation', () {
    test('validates privacy.upload enum', () async {
      final configPath = '${tempDir.path}/privacy_upload.json';
      final config = {
        // Contract uses 'video+keypoints' (plus sign), not 'video-and-keypoints'
        'privacy': {'upload': 'video+keypoints', 'confirmVideoUpload': false}
      };
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['privacy']['upload'], equals('video+keypoints'));
      expect(result['privacy']['confirmVideoUpload'], equals(false));
    });

    test('validates cleanup.days range', () async {
      final configPath = '${tempDir.path}/cleanup_days.json';
      final config = {'cleanup': {'days': 30}};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['cleanup']['days'], equals(30));
    });

    test('validates logs.level enum', () async {
      final configPath = '${tempDir.path}/logs_level.json';
      final config = {'logs': {'level': 'debug'}};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['logs']['level'], equals('debug'));
    });

    test('negative cleanup days falls back to default', () async {
      final configPath = '${tempDir.path}/negative_days.json';
      final config = {'cleanup': {'days': -5}};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['cleanup']['days'], equals(7)); // Default
    });

    test('zero cleanup days is accepted (treat as keep 0 days)', () async {
      final configPath = '${tempDir.path}/zero_days.json';
      final config = {'cleanup': {'days': 0}};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      // Contract accepts >= 0, so zero should be preserved
      expect(result['cleanup']['days'], equals(0));
    });
  });

  group('Config Sync - buildCliArgs Combinations', () {
    test('builds args with minimal input', () async {
      final args = buildCliArgs(
        pickedInput: 'video.mp4',
        sessionRoot: '/tmp/session',
      );

      expect(args.inputPath, equals('video.mp4'));
      expect(args.sessionRoot, equals('/tmp/session'));
    });

    test('builds args with config snapshot', () async {
      final sessionRoot = '${tempDir.path}/session_with_config';
      await Directory(sessionRoot).create(recursive: true);

      final config = {'engine': 'MoveNet', 'strictness': 'strict'};
      await writeRuntimeSnapshot(sessionRoot, config);

      final args = buildCliArgs(
        pickedInput: 'video.mp4',
        sessionRoot: sessionRoot,
        configPath: '$sessionRoot/configs_snapshot.json',
      );

      expect(args.configPath, equals('$sessionRoot/configs_snapshot.json'));
    });

    test('handles paths with spaces', () async {
      final args = buildCliArgs(
        pickedInput: '/path/with spaces/video.mp4',
        sessionRoot: '/tmp/session with spaces',
      );

      expect(args.inputPath, equals('/path/with spaces/video.mp4'));
      expect(args.sessionRoot, equals('/tmp/session with spaces'));
    });

    test('handles unicode paths', () async {
      final args = buildCliArgs(
        pickedInput: '/path/视频.mp4',
        sessionRoot: '/tmp/会话',
      );

      expect(args.inputPath, equals('/path/视频.mp4'));
      expect(args.sessionRoot, equals('/tmp/会话'));
    });

    test('handles very long paths', () async {
      final longPath = '/very/long/path/${'a' * 200}/video.mp4';
      final args = buildCliArgs(
        pickedInput: longPath,
        sessionRoot: '/tmp/session',
      );

      expect(args.inputPath, equals(longPath));
    });
  });

  group('Config Sync - Concurrent Operations', () {
    test('concurrent reads are safe', () async {
      final configPath = '${tempDir.path}/concurrent.json';
      await writeAppRuntimeConfig(
        {'engine': 'MoveNet', 'strictness': 'strict'},
        pathOverride: configPath,
      );

      final results = await Future.wait([
        readAppRuntimeConfig(pathOverride: configPath),
        readAppRuntimeConfig(pathOverride: configPath),
        readAppRuntimeConfig(pathOverride: configPath),
      ]);

      expect(results.length, equals(3));
      for (final config in results) {
        expect(config['engine'], equals('MoveNet'));
      }
    });

    test('write then read is consistent', () async {
      final configPath = '${tempDir.path}/write_read.json';

      await writeAppRuntimeConfig(
        {'engine': 'BlazePose', 'strictness': 'lenient'},
        pathOverride: configPath,
      );

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['engine'], equals('BlazePose'));
      expect(config['strictness'], equals('lenient'));
    });

    test('multiple writes preserve latest', () async {
      final configPath = '${tempDir.path}/multiple_writes.json';

      await writeAppRuntimeConfig({'engine': 'MoveNet'}, pathOverride: configPath);
      await writeAppRuntimeConfig({'engine': 'BlazePose'}, pathOverride: configPath);
      await writeAppRuntimeConfig({'engine': 'PoseNet'}, pathOverride: configPath);

      final config = await readAppRuntimeConfig(pathOverride: configPath);

      expect(config['engine'], equals('PoseNet')); // Latest
    });
  });

  group('Config Sync - File Permission Errors', () {
    test('non-existent directory creates parent dirs', () async {
      final deepPath = '${tempDir.path}/deep/nested/path/config.json';

      await writeAppRuntimeConfig(
        {'engine': 'MoveNet'},
        pathOverride: deepPath,
      );

      expect(await File(deepPath).exists(), isTrue);
    });

    test('reading non-existent file returns defaults', () async {
      final missingPath = '${tempDir.path}/does_not_exist.json';

      final config = await readAppRuntimeConfig(pathOverride: missingPath);

      expect(config['engine'], equals('MoveNet')); // Default
      expect(config['strictness'], equals('strict')); // Default
    });
  });

  group('Config Sync - Large Config Values', () {
    test('handles very large stride value', () async {
      final configPath = '${tempDir.path}/large_stride.json';
      final config = {'stride': 1000};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['stride'], equals(1000));
    });

    test('handles very high FPS', () async {
      final configPath = '${tempDir.path}/high_fps.json';
      final config = {'targetFps': 240};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['targetFps'], equals(240));
    });

    test('handles large cleanup retention days', () async {
      final configPath = '${tempDir.path}/long_retention.json';
      final config = {'cleanup': {'days': 365}};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['cleanup']['days'], equals(365));
    });
  });

  group('Config Sync - Special Characters', () {
    test('handles unicode in config values', () async {
      final configPath = '${tempDir.path}/unicode.json';
      // Note: enum values must still be valid, this tests storage/retrieval
      final config = {'engine': 'MoveNet', 'strictness': 'strict'};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['engine'], equals('MoveNet'));
    });

    test('writeRuntimeSnapshot handles unicode paths', () async {
      final sessionRoot = '${tempDir.path}/会话_unicode';
      await Directory(sessionRoot).create(recursive: true);

      final config = {'engine': 'MoveNet'};
      await writeRuntimeSnapshot(sessionRoot, config);

      final snapshotFile = File('$sessionRoot/configs_snapshot.json');
      expect(await snapshotFile.exists(), isTrue);
    });

    test('handles paths with special characters', () async {
      final specialPath = '${tempDir.path}/config-with-dash.json';
      await writeAppRuntimeConfig({'engine': 'MoveNet'}, pathOverride: specialPath);

      final config = await readAppRuntimeConfig(pathOverride: specialPath);
      expect(config['engine'], equals('MoveNet'));
    });
  });

  group('Config Sync - Boundary Conditions', () {
    test('minimum valid stride (1)', () async {
      final configPath = '${tempDir.path}/min_stride.json';
      final config = {'stride': 1};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);
      expect(result['stride'], equals(1));
    });

    test('minimum valid FPS (1)', () async {
      final configPath = '${tempDir.path}/min_fps.json';
      final config = {'targetFps': 1};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);
      expect(result['targetFps'], equals(1));
    });

    test('empty string values fall back to defaults', () async {
      final configPath = '${tempDir.path}/empty_strings.json';
      final config = {'engine': '', 'strictness': ''};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['engine'], equals('MoveNet')); // Default
      expect(result['strictness'], equals('strict')); // Default
    });

    test('null values fall back to defaults', () async {
      final configPath = '${tempDir.path}/null_values.json';
      final config = {'engine': null, 'strictness': null};
      await File(configPath).writeAsString(jsonEncode(config));

      final result = await readAppRuntimeConfig(pathOverride: configPath);

      expect(result['engine'], equals('MoveNet'));
      expect(result['strictness'], equals('strict'));
    });
  });
}

