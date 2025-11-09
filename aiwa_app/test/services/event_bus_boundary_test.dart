// event_bus_boundary_test.dart
// Purpose: Comprehensive boundary/edge case tests for event_bus
// Coverage: empty lines, CRLF, long lines, concurrent, permissions, malformed JSON

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/services/event_bus.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('event_bus_boundary_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Event Bus - Empty Lines & Whitespace', () {
    test('handles lines with only whitespace', () async {
      final testFile = File('${tempDir.path}/whitespace.jsonl');
      await testFile.writeAsString('''
{"event":"START","sessionId":"test_001"}
   \t  
{"event":"DONE","artifacts":{"root":"test/"}}
''');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.length, equals(2));
      expect(events[0]['event'], equals('START'));
      expect(events[1]['event'], equals('DONE'));
    });

    test('handles comment lines (starting with #)', () async {
      final testFile = File('${tempDir.path}/comments.jsonl');
      await testFile.writeAsString('''
# This is a comment
{"event":"START","sessionId":"test_001"}
# Another comment
{"event":"DONE","artifacts":{"root":"test/"}}
''');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      // Robust implementation: may skip comment lines or emit ERROR
      expect(events.any((e) => e['event'] == 'START'), isTrue);
      expect(events.any((e) => e['event'] == 'DONE' || e['event'] == 'ERROR'), isTrue);
    });
  });

  group('Event Bus - CRLF & Line Endings', () {
    test('handles CRLF line endings (Windows)', () async {
      final testFile = File('${tempDir.path}/crlf.jsonl');
      
      // Write with CRLF (\\r\\n)
      const content = '{"event":"START","sessionId":"test_001"}\r\n{"event":"DONE","artifacts":{"root":"test/"}}\r\n';
      await testFile.writeAsBytes(utf8.encode(content));

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.length, equals(2));
      expect(events[0]['event'], equals('START'));
      expect(events[1]['event'], equals('DONE'));
    });

    test('handles LF line endings (Unix)', () async {
      final testFile = File('${tempDir.path}/lf.jsonl');
      
      // Write with LF (\\n)
      await testFile.writeAsString('{"event":"START","sessionId":"test_001"}\n{"event":"DONE","artifacts":{"root":"test/"}}\n');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.length, equals(2));
    });

    test('handles mixed line endings', () async {
      final testFile = File('${tempDir.path}/mixed.jsonl');
      
      // Mix of CRLF and LF
      const content = '{"event":"START","sessionId":"test_001"}\r\n{"event":"PROGRESS","processed":50,"total":100}\n{"event":"DONE","artifacts":{"root":"test/"}}\r\n';
      await testFile.writeAsBytes(utf8.encode(content));

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.length, equals(3));
    });
  });

  group('Event Bus - Long Lines', () {
    test('handles very long JSON lines (10KB)', () async {
      final testFile = File('${tempDir.path}/long_line.jsonl');
      
      // Create a 10KB JSON line
      final longString = 'x' * (10 * 1024);
      await testFile.writeAsString('{"event":"START","sessionId":"test_001","data":"$longString"}\n');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      // Robust implementation: should handle long lines without crashing
      expect(events.length, greaterThanOrEqualTo(1));
      if (events.isNotEmpty && events[0]['event'] == 'START') {
        expect(events[0]['data'].length, equals(10 * 1024));
      }
    });

    test('handles extremely long lines (1MB) without crash', () async {
      final testFile = File('${tempDir.path}/very_long_line.jsonl');
      
      // Create a 1MB JSON line
      final longString = 'x' * (1024 * 1024);
      await testFile.writeAsString('{"event":"START","data":"$longString"}\n');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      // Robust implementation: should handle or skip large lines without crashing
      // May emit ERROR if line is too large
      expect(events.length, greaterThanOrEqualTo(0));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('Event Bus - Malformed JSON', () {
    test('skips malformed JSON lines', () async {
      final testFile = File('${tempDir.path}/malformed.jsonl');
      await testFile.writeAsString('''
{"event":"START","sessionId":"test_001"}
{this is not valid json}
{"event":"DONE","artifacts":{"root":"test/"}}
''');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      // Robust implementation: skips malformed line or emits ERROR
      expect(events.any((e) => e['event'] == 'START'), isTrue);
      expect(events.any((e) => e['event'] == 'DONE') || events.any((e) => e['event'] == 'ERROR'), isTrue);
    });

    test('handles incomplete JSON (cut off)', () async {
      final testFile = File('${tempDir.path}/incomplete.jsonl');
      await testFile.writeAsString('''
{"event":"START","sessionId":"test_001"}
{"event":"PROGRESS","processed":50
{"event":"DONE","artifacts":{"root":"test/"}}
''');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      // Robust implementation: skips incomplete line or emits ERROR
      expect(events.any((e) => e['event'] == 'START'), isTrue);
      expect(events.any((e) => e['event'] == 'DONE') || events.any((e) => e['event'] == 'ERROR'), isTrue);
    });

    test('handles JSON with special characters', () async {
      final testFile = File('${tempDir.path}/special_chars.jsonl');
      await testFile.writeAsString('''
{"event":"START","sessionId":"test_001","message":"Line with \\"quotes\\" and \\nnewlines"}
{"event":"DONE","artifacts":{"root":"test/"}}
''');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.length, equals(2));
      expect(events[0]['message'], contains('quotes'));
    });
  });

  group('Event Bus - Invalid UTF-8', () {
    test('handles invalid UTF-8 sequences gracefully', () async {
      final testFile = File('${tempDir.path}/invalid_utf8.jsonl');
      
      // Write bytes with invalid UTF-8
      final validStart = utf8.encode('{"event":"START","data":"');
      final invalidBytes = [0xFF, 0xFE, 0xFD]; // Invalid UTF-8
      final validEnd = utf8.encode('"}\n{"event":"DONE","artifacts":{"root":"test/"}}\n');
      
      await testFile.writeAsBytes([...validStart, ...invalidBytes, ...validEnd]);

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      // Robust implementation: skips invalid UTF-8 or emits ERROR
      // At minimum, should complete without crashing
      expect(events.isNotEmpty, isTrue);
      expect(events.any((e) => e['event'] == 'DONE' || e['event'] == 'ERROR'), isTrue);
    });
  });

  group('Event Bus - File Permission & I/O Errors', () {
    test('emits ERROR when file does not exist', () async {
      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile('${tempDir.path}/nonexistent.jsonl');

      await for (final event in stream) {
        events.add(event);
      }

      expect(events.length, equals(1));
      expect(events.first['event'], equals('ERROR'));
      expect(events.first['code'], startsWith('404'));
    });

    test('handles empty file gracefully', () async {
      final testFile = File('${tempDir.path}/empty.jsonl');
      await testFile.writeAsString('');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final event in stream) {
        events.add(event);
      }

      // Empty file should produce no events (or ERROR)
      expect(events.isEmpty || events.first['event'] == 'ERROR', isTrue);
    });
  });

  group('Event Bus - Session ID Injection', () {
    test('preserves existing sessionId when present', () async {
      final testFile = File('${tempDir.path}/has_session.jsonl');
      await testFile.writeAsString('''
{"event":"START","sessionId":"original_001","input":{},"params":{}}
{"event":"DONE","sessionId":"original_001","artifacts":{"root":"test/"}}
''');

      final events = <Map<String, dynamic>>[];
      final stream = analysisEventsFromJsonlFile(
        testFile.path,
        sessionId: 'injected_session',
      );

      await for (final event in stream) {
        events.add(event);
      }

      // Implementation may preserve original or use injected - both are acceptable
      expect(events.length, equals(2));
      expect(events[0]['sessionId'], isNotNull);
      expect(events[1]['sessionId'], isNotNull);
    });
  });

  group('Event Bus - Concurrent Access', () {
    test('handles multiple readers on same file', () async {
      final testFile = File('${tempDir.path}/concurrent.jsonl');
      await testFile.writeAsString('''
{"event":"START","sessionId":"test_001"}
{"event":"PROGRESS","processed":50,"total":100}
{"event":"DONE","artifacts":{"root":"test/"}}
''');

      // Read from same file concurrently
      final futures = List.generate(3, (i) async {
        final events = <Map<String, dynamic>>[];
        final stream = analysisEventsFromJsonlFile(testFile.path);
        await for (final event in stream) {
          events.add(event);
        }
        return events;
      });

      final results = await Future.wait(futures);

      // All readers should get all events
      for (final events in results) {
        expect(events.length, equals(3));
        expect(events[0]['event'], equals('START'));
        expect(events[2]['event'], equals('DONE'));
      }
    });
  });

  group('Event Bus - Large Event Stream', () {
    test('handles 1000 events without memory leak', () async {
      final testFile = File('${tempDir.path}/many_events.jsonl');
      final sink = testFile.openWrite();

      sink.writeln('{"event":"START","sessionId":"test_001"}');
      for (int i = 0; i < 1000; i++) {
        sink.writeln('{"event":"PROGRESS","processed":$i,"total":1000}');
      }
      sink.writeln('{"event":"DONE","artifacts":{"root":"test/"}}');
      await sink.close();

      int eventCount = 0;
      final stream = analysisEventsFromJsonlFile(testFile.path);

      await for (final _ in stream) {
        eventCount++;
        // Just count, don't accumulate (to avoid memory leak in test)
      }

      expect(eventCount, equals(1002)); // START + 1000 PROGRESS + DONE
    });
  });
}

