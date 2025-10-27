import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/main.dart';

/// Widget Tests
/// 
/// 测试应用的基本 Widget 渲染与导航功能

void main() {
  testWidgets('App loads and shows welcome page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that welcome page is shown (initial route)
    expect(find.text('AIWA'), findsOneWidget);
    expect(find.text('AI-Powered Workout Assistant'), findsOneWidget);
    expect(find.text('开始使用'), findsOneWidget);
  });

  testWidgets('Navigation to home page works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap the '开始使用' button
    await tester.tap(find.text('开始使用'));
    await tester.pumpAndSettle(); // Wait for navigation animation

    // Verify that home page is shown
    expect(find.text('欢迎回来'), findsOneWidget);
  });

  testWidgets('Bottom navigation works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Navigate to home first
    await tester.tap(find.text('开始使用'));
    await tester.pumpAndSettle();

    // Verify we're on home page
    expect(find.text('欢迎回来'), findsOneWidget);

    // Tap camera tab in bottom navigation
    await tester.tap(find.text('相机'));
    await tester.pumpAndSettle();

    // Verify we're on camera page
    expect(find.text('训练中'), findsOneWidget);

    // Tap settings tab
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    // Verify we're on settings page
    expect(find.text('训练配置'), findsOneWidget);
  });
}
