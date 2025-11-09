import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/main.dart';
import 'package:aiwa_app/services/auth/auth_state.dart';
import 'package:aiwa_app/ui/pages/settings_page.dart';

/// Widget Tests
/// 
/// 测试应用的基本 Widget 渲染与导航功能

void main() {
  late AuthState authState;

  setUpAll(() async {
    // Create and initialize AuthState for all tests
    authState = AuthState();
    await authState.initialize();
  });

  testWidgets('App loads and shows welcome page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(authState: authState));

    // Verify that welcome page is shown (initial route)
    expect(find.text('AIWA'), findsOneWidget);
    expect(find.text('AI-Powered Workout Assistant'), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);
  });

  testWidgets('Navigation to home page works', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authState: authState));

    // Tap the '开始使用' button
    await tester.tap(find.text('开始使用'));
    await tester.pumpAndSettle(); // Wait for navigation animation

    // Verify that home page is shown
    expect(find.text('Text'), findsWidgets);
  });

  testWidgets('Bottom navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(authState: authState));

    // Navigate to home first
    await tester.tap(find.text('开始使用'));
    await tester.pumpAndSettle();

    // Verify we're on home page
    expect(find.text('Text'), findsWidgets);

    // Tap camera tab in bottom navigation (use stable ValueKey)
    await tester.tap(find.byKey(const ValueKey('nav.camera.icon')));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify we're on camera page (use stable ValueKey)
    expect(find.byKey(const ValueKey('action.record_video')), findsOneWidget);

    // Tap settings tab (use stable ValueKey)
    await tester.tap(find.byKey(const ValueKey('nav.settings.icon')));
    
    // Pump multiple times to allow settings page to load
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Verify we're on settings page by checking page type
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
