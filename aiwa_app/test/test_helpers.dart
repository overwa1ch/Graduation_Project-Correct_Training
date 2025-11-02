// test_helpers.dart
// Purpose: Unified test infrastructure for all widget tests
// Provides: TestHarness, async strategies, environment setup

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unified test wrapper: fixed environment, size, scale
/// 
/// Usage:
/// ```dart
/// await tester.pumpWidget(TestHarness(
///   child: MyWidget(),
/// ));
/// ```
class TestHarness extends StatelessWidget {
  final Widget child;
  final Locale locale;
  final ThemeData? theme;
  
  const TestHarness({
    super.key, 
    required this.child,
    this.locale = const Locale('zh', 'CN'),
    this.theme,
  });
  
  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(
        size: Size(1080, 1920),
        padding: EdgeInsets.zero, textScaler: TextScaler.linear(1.0),
        devicePixelRatio: 2.0,
      ),
      child: MaterialApp(
        locale: locale,
        theme: theme,
        home: child,
      ),
    );
  }
}

/// Unified async wait strategy with timeout fallback
/// 
/// Usage:
/// ```dart
/// await safePumpAndSettle(tester);
/// // or with custom timeout
/// await safePumpAndSettle(tester, timeout: Duration(seconds: 5));
/// ```
Future<void> safePumpAndSettle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 3),
  Duration interval = const Duration(milliseconds: 100),
}) async {
  await tester.pump();
  try {
    await tester.pumpAndSettle(timeout);
  } catch (e) {
    // Timeout fallback: at least wait fixed duration
    debugPrint('[TEST] pumpAndSettle timeout, fallback to fixed wait: $e');
    await tester.pump(interval);
  }
}

/// Global test environment setup
/// 
/// Call once in main() of test files:
/// ```dart
/// void main() {
///   setupTestEnvironment();
///   
///   group('My Tests', () {
///     // ...
///   });
/// }
/// ```
void setupTestEnvironment({bool failOnOverflow = false}) {
  // Disable shadows to prevent layout overflow warnings
  debugDisableShadows = true;
  
  // Optionally treat overflow warnings as errors (aggressive mode)
  if (failOnOverflow) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('RenderFlex overflowed') || 
          message.contains('overflowed by')) {
        throw Exception('Layout overflow detected: ${details.exception}');
      }
      originalOnError?.call(details);
    };
  }
}

/// Helper: Create a minimal scaffold for widget testing
Widget testScaffold(Widget child) {
  return Scaffold(
    body: Center(child: child),
  );
}

/// Helper: Wait for a specific duration (for animation/delay testing)
Future<void> waitFor(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
}

/// Helper: Pump multiple frames with a delay between each
Future<void> pumpFrames(
  WidgetTester tester, 
  int frameCount, {
  Duration frameDuration = const Duration(milliseconds: 16),
}) async {
  for (int i = 0; i < frameCount; i++) {
    await tester.pump(frameDuration);
  }
}

