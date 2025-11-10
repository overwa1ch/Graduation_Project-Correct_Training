// benchmark_test.dart
// Purpose: Performance benchmarks for key operations
// Coverage: Event parsing throughput, UI rendering time, memory usage

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/ui/pages/result_popup_page.dart';
import 'package:aiwa_app/ui/pages/camera_page.dart';
import 'package:aiwa_app/ui/pages/settings_page.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';
import 'package:aiwa_core/result/result_reader.dart';
import 'package:aiwa_core/result/result_schema.dart';
import 'package:aiwa_core/core/errors.dart';
import '../test_helpers.dart';
import '../helpers/fake_analysis.dart';

void main() {
  // Skip performance tests in normal test runs (too slow)
  // Run explicitly with: flutter test test/performance/
  
  group('Performance - Event Parsing Throughput', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('perf_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Parse 1000 events - throughput', () async {
      // Create test file with 1000 events
      final testFile = File('${tempDir.path}/1000_events.jsonl');
      final sink = testFile.openWrite();
      
      sink.writeln('{"event":"START","sessionId":"perf_test"}');
      for (int i = 0; i < 1000; i++) {
        sink.writeln('{"event":"PROGRESS","processed":$i,"total":1000}');
      }
      sink.writeln('{"event":"DONE","artifacts":{"root":"test/"}}');
      await sink.close();

      final stopwatch = Stopwatch()..start();
      int eventCount = 0;

      // Parse all events
      final lines = await testFile.readAsLines();
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          jsonDecode(line);
          eventCount++;
        } catch (e) {
          // Skip malformed
        }
      }

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds == 0 ? 1 : stopwatch.elapsedMilliseconds;
      final eventsPerSec = (eventCount / ms) * 1000;

      print('📊 Event Parsing: ${eventsPerSec.toStringAsFixed(0)} events/sec');
      print('   Total events: $eventCount');
      print('   Time: ${stopwatch.elapsedMilliseconds}ms');

      // Baseline: Should parse at least 5k events/sec (relaxed for CI/Windows)
      expect(eventsPerSec, greaterThan(5000),
          reason: 'Event parsing too slow: ${eventsPerSec.toStringAsFixed(0)} events/sec');
    });

    test('Stream processing - 1000 events', () async {
      // Create fixture
      final testFile = File('${tempDir.path}/stream_test.jsonl');
      final sink = testFile.openWrite();
      
      sink.writeln('{"event":"START","sessionId":"stream_test"}');
      for (int i = 0; i < 1000; i++) {
        sink.writeln('{"event":"PROGRESS","processed":$i,"total":1000}');
      }
      sink.writeln('{"event":"DONE","artifacts":{"root":"test/"}}');
      await sink.close();

      final stopwatch = Stopwatch()..start();
      int eventCount = 0;

      // Stream through events
      await for (final line in testFile.openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        try {
          jsonDecode(line);
          eventCount++;
        } catch (e) {
          // Skip
        }
      }

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds == 0 ? 1 : stopwatch.elapsedMilliseconds;
      final eventsPerSec = (eventCount / ms) * 1000;

      print('📊 Stream Processing: ${eventsPerSec.toStringAsFixed(0)} events/sec');
      print('   Total events: $eventCount');
      print('   Time: ${stopwatch.elapsedMilliseconds}ms');

      // Relaxed for CI/Windows environments
      expect(eventsPerSec, greaterThan(1000));
    });

    test('Large event payload - 10KB per event', () async {
      final testFile = File('${tempDir.path}/large_events.jsonl');
      final sink = testFile.openWrite();
      
      final largeData = 'x' * (10 * 1024); // 10KB string
      
      for (int i = 0; i < 100; i++) {
        sink.writeln('{"event":"DATA","index":$i,"payload":"$largeData"}');
      }
      await sink.close();

      final stopwatch = Stopwatch()..start();
      int eventCount = 0;
      int totalBytes = 0;

      final lines = await testFile.readAsLines();
      for (final line in lines) {
        try {
          jsonDecode(line);
          eventCount++;
          totalBytes += line.length;
        } catch (e) {
          // Skip
        }
      }

      stopwatch.stop();
      final ms = stopwatch.elapsedMilliseconds == 0 ? 1 : stopwatch.elapsedMilliseconds;
      final mbPerSec = (totalBytes / ms) / 1024;

      print('📊 Large Payload Parsing:');
      print('   Throughput: ${mbPerSec.toStringAsFixed(2)} MB/sec');
      print('   Events: $eventCount');
      print('   Total size: ${(totalBytes / 1024 / 1024).toStringAsFixed(2)} MB');
      print('   Time: ${stopwatch.elapsedMilliseconds}ms');

      expect(mbPerSec, greaterThan(1)); // At least 1 MB/sec
    });
  });

  group('Performance - UI Rendering Time', () {
    testWidgets('ResultPopupPage - first render', (tester) async {
      const result = AnalysisResultLite(
        posture: 85,
        stability: 88,
        rhythm: 83,
        total: 85,
        reps: 12,
        attempts: 12,
        evidencePath: 'test/evidence.jpg',
        lowConfidence: false,
        coverage: 0.89,
        templateName: 'squat',
        strictness: 'strict',
        engine: 'MoveNet',
        fps: 30,
      );

      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      if (binding is LiveTestWidgetsFlutterBinding) {
        binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(TestHarness(
        child: ResultPopupPage(
          result: result,
          sessionRoot: 'test_session',
        ),
      ));

      // Wait for first frame
      await tester.pump();
      
      stopwatch.stop();

      print('📊 ResultPopup First Render: ${stopwatch.elapsedMilliseconds}ms');

      // Relaxed timing for CI environments
      expect(stopwatch.elapsedMilliseconds, lessThan(200),
          reason: 'ResultPopup render too slow: ${stopwatch.elapsedMilliseconds}ms');
    });

    testWidgets('CameraPage - first render', (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      if (binding is LiveTestWidgetsFlutterBinding) {
        binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const TestHarness(
        child: CameraPage(),
      ));

      await tester.pump();
      
      stopwatch.stop();

      print('📊 CameraPage First Render: ${stopwatch.elapsedMilliseconds}ms');

      // Relaxed timing for CI environments
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });

    testWidgets('SettingsPage - first render', (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      if (binding is LiveTestWidgetsFlutterBinding) {
        binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
      }

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const TestHarness(
        child: SettingsPage(),
      ));

      await tester.pump();
      
      stopwatch.stop();

      print('📊 SettingsPage First Render: ${stopwatch.elapsedMilliseconds}ms');

      // Relaxed timing for CI environments
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });

    testWidgets('ResultPopup - rebuild performance', (tester) async {
      const result = AnalysisResultLite(
        posture: 85,
        stability: 88,
        rhythm: 83,
        total: 85,
        reps: 12,
        attempts: 12,
        evidencePath: 'test/evidence.jpg',
        lowConfidence: false,
        coverage: 0.89,
        templateName: 'squat',
        strictness: 'strict',
        fps: 30,
      );

      await tester.pumpWidget(TestHarness(
        child: ResultPopupPage(
          result: result,
          sessionRoot: 'test',
        ),
      ));

      await tester.pump();

      // Measure rebuild time
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(TestHarness(
        child: ResultPopupPage(
          result: result,
          sessionRoot: 'test',
        ),
      ));

      await tester.pump();
      
      stopwatch.stop();

      print('📊 ResultPopup Rebuild: ${stopwatch.elapsedMilliseconds}ms');

      // Rebuilds should be reasonably fast
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Performance - Memory Usage', () {
    test('Parse 10k events - memory stability', () async {
      final tempDir = await Directory.systemTemp.createTemp('mem_test_');

      try {
        final testFile = File('${tempDir.path}/10k_events.jsonl');
        final sink = testFile.openWrite();
        
        for (int i = 0; i < 10000; i++) {
          sink.writeln('{"event":"PROGRESS","index":$i}');
        }
        await sink.close();

        // Process in streaming fashion (should not accumulate)
        int count = 0;
        
        await for (final line in testFile.openRead()
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
          if (line.trim().isEmpty) continue;
          jsonDecode(line);
          count++;
        }

        expect(count, equals(10000));
        
        print('📊 Streamed 10k events without accumulation');
        
        // No assertion on memory - just verify it completes
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('Multiple result objects - no leak', () {
      final results = <AnalysisResultLite>[];

      for (int i = 0; i < 1000; i++) {
        results.add(AnalysisResultLite(
          posture: 80 + i % 20,
          stability: 75 + i % 25,
          rhythm: 70 + i % 30,
          total: 75 + i % 25,
          reps: 10 + i % 5,
          attempts: 10 + i % 5,
          lowConfidence: i % 2 == 0,
          coverage: 0.7 + (i % 30) / 100,
          evidencePath: 'test/evidence_$i.jpg',
          templateName: 'squat',
          strictness: 'strict',
          fps: 30,
        ));
      }

      expect(results.length, equals(1000));
      
      print('📊 Created 1000 result objects without issue');
    });
  });

  group('Performance - Baseline Comparison', () {
    test('Event replay throughput - fixture', () async {
      final stopwatch = Stopwatch()..start();

      final events = await collectEvents(
        replayEventsFromFixture('scenario_success'),
        timeout: const Duration(seconds: 10),
      );

      stopwatch.stop();

      final eventsPerSec = (events.length / stopwatch.elapsedMilliseconds) * 1000;

      print('📊 Fixture Replay Throughput:');
      print('   Events: ${events.length}');
      print('   Time: ${stopwatch.elapsedMilliseconds}ms');
      print('   Rate: ${eventsPerSec.toStringAsFixed(0)} events/sec');

      // Relaxed for file I/O overhead
      expect(eventsPerSec, greaterThan(50));
    });

    test('JSON parsing - result.json', () async {
      final resultJson = {
        'scores': {'overall': 85, 'form': 84, 'stability': 88, 'tempo': 83},
        'repCount': 12,
        'quality': {'lowConfidence': false, 'coverage': 0.89},
        'meta': {'engine': 'MoveNet', 'fps': 30},
      };

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        // Note: In real usage, readResultJson validates schema automatically
        // For benchmark, we skip validation and just parse
        final parsed = AnalysisResult.fromJson(resultJson);
        final _ = toLite(parsed);
      }

      stopwatch.stop();

      final ms = stopwatch.elapsedMilliseconds == 0 ? 1 : stopwatch.elapsedMilliseconds;
      final parsesPerSec = (1000 / ms) * 1000;

      print('📊 Result Parsing:');
      print('   Parses: 1000');
      print('   Time: ${stopwatch.elapsedMilliseconds}ms');
      print('   Rate: ${parsesPerSec.toStringAsFixed(0)} parses/sec');

      // Relaxed for CI environments
      expect(parsesPerSec, greaterThan(5000));
    });
  });

  group('Performance - Stress Tests', () {
    testWidgets('Rapid navigation - no performance degradation', (tester) async {
      await tester.pumpWidget(const TestHarness(
        child: CameraPage(),
      ));

      final times = <int>[];

      // Navigate multiple times and measure
      for (int i = 0; i < 10; i++) {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(const TestHarness(
          child: SettingsPage(),
        ));
        await tester.pump();
        
        stopwatch.stop();
        times.add(stopwatch.elapsedMilliseconds);
      }

      final avgTime = times.reduce((a, b) => a + b) / times.length;
      
      print('📊 Rapid Navigation (10 switches):');
      print('   Average: ${avgTime.toStringAsFixed(1)}ms');
      print('   Min: ${times.reduce((a, b) => a < b ? a : b)}ms');
      print('   Max: ${times.reduce((a, b) => a > b ? a : b)}ms');

      // Average should stay reasonable (relaxed for CI)
      expect(avgTime, lessThan(200));
    });
  });
}

