// fake_analysis.dart
// Purpose: Fake event replay for E2E testing without real CLI process
// Usage: Replay events from fixture JSONL files for deterministic testing

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Replay events from a fixture JSONL file
/// 
/// This provides a controlled, deterministic event stream for E2E testing
/// without needing to spawn actual CLI processes.
/// 
/// Usage:
/// ```dart
/// final stream = replayEventsFromFixture('scenario_success');
/// await for (final event in stream) {
///   // Handle event
/// }
/// ```
Stream<Map<String, dynamic>> replayEventsFromFixture(
  String scenarioName, {
  Duration? delayBetweenEvents,
  bool throwOnError = false,
}) async* {
  final fixturePath = 'test/fixtures/e2e_scenarios/$scenarioName.jsonl';
  final file = File(fixturePath);
  
  if (!await file.exists()) {
    if (throwOnError) {
      throw FileSystemException('Fixture not found', fixturePath);
    }
    yield {
      'event': 'ERROR',
      'code': '404_FIXTURE_NOT_FOUND',
      'message': 'Fixture file not found: $fixturePath',
    };
    return;
  }
  
  try {
    final lines = await file.readAsLines();
    
    for (final line in lines) {
      // Skip empty lines and comments (support '#' and '//')
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#') || trimmed.startsWith('//')) {
        continue;
      }
      
      try {
        final event = Map<String, dynamic>.from(jsonDecode(line) as Map);
        
        // Optional delay to simulate real-time behavior
        if (delayBetweenEvents != null) {
          await Future<void>.delayed(delayBetweenEvents);
        }
        
        yield event;
      } catch (e) {
        if (throwOnError) {
          throw FormatException('Invalid JSON in fixture: $line');
        }
        yield {
          'event': 'ERROR',
          'code': '400_PARSE_ERROR',
          'message': 'Failed to parse fixture line: $e',
        };
      }
    }
  } catch (e) {
    if (throwOnError) {
      rethrow;
    }
    yield {
      'event': 'ERROR',
      'code': '500_READ_ERROR',
      'message': 'Failed to read fixture file: $e',
    };
  }
}

/// Create a StreamController that can be manually controlled
/// 
/// Useful for testing specific event sequences or timing scenarios.
/// 
/// Usage:
/// ```dart
/// final controller = createControlledEventStream();
/// controller.add({'event': 'START'});
/// controller.add({'event': 'DONE'});
/// controller.close();
/// ```
StreamController<Map<String, dynamic>> createControlledEventStream() {
  return StreamController<Map<String, dynamic>>();
}

/// Replay events with custom speed multiplier
/// 
/// Speed up or slow down event replay for testing different scenarios:
/// - speed = 0.5: Replay at half speed (2x slower)
/// - speed = 2.0: Replay at double speed (2x faster)
/// - speed = 0: No delay between events
Stream<Map<String, dynamic>> replayEventsWithSpeed(
  String scenarioName,
  double speed,
) {
  if (speed <= 0) {
    return replayEventsFromFixture(scenarioName);
  }
  
  // Base delay of 50ms per event
  const baseDelay = Duration(milliseconds: 50);
  final adjustedDelay = Duration(
    milliseconds: (baseDelay.inMilliseconds / speed).round(),
  );
  
  return replayEventsFromFixture(
    scenarioName,
    delayBetweenEvents: adjustedDelay,
  );
}

/// Replay a specific subset of events for targeted testing
Stream<Map<String, dynamic>> replayEventSubset(
  String scenarioName, {
  int? maxEvents,
  bool Function(Map<String, dynamic>)? filter,
}) async* {
  int count = 0;
  final stream = replayEventsFromFixture(scenarioName);
  
  await for (final event in stream) {
    // Apply filter if provided
    if (filter != null && !filter(event)) {
      continue;
    }
    
    yield event;
    
    count++;
    if (maxEvents != null && count >= maxEvents) {
      break;
    }
  }
}

/// Wait for a specific event type in the stream
/// 
/// Returns the first event matching the predicate, or null if stream ends.
Future<Map<String, dynamic>?> waitForEvent(
  Stream<Map<String, dynamic>> stream,
  bool Function(Map<String, dynamic>) predicate, {
  Duration? timeout,
}) async {
  final completer = Completer<Map<String, dynamic>?>();
  StreamSubscription<Map<String, dynamic>>? subscription;
  
  subscription = stream.listen(
    (event) {
      if (predicate(event)) {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.complete(event);
        }
      }
    },
    onDone: () {
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    },
    onError: (Object error) {
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    },
  );
  
  if (timeout != null) {
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        subscription?.cancel();
        return null;
      },
    );
  }
  
  return completer.future;
}

/// Collect all events from a stream into a list
Future<List<Map<String, dynamic>>> collectEvents(
  Stream<Map<String, dynamic>> stream, {
  Duration? timeout,
}) async {
  final events = <Map<String, dynamic>>[];
  
  final future = stream.forEach((event) => events.add(event));
  
  if (timeout != null) {
    await future.timeout(timeout, onTimeout: () {
      // Timeout - return events collected so far
    });
  } else {
    await future;
  }
  
  return events;
}

