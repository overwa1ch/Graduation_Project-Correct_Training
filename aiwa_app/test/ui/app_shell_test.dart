import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setupTestEnvironment();

  group('AppShell', () {
    testWidgets('renders child and app bar title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(
            title: 'Shell Title',
            child: Text('Shell Body'),
          ),
        ),
      );

      expect(find.text('Shell Title'), findsOneWidget);
      expect(find.text('Shell Body'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('shows four-tab navigation keys', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(child: SizedBox.shrink()),
        ),
      );

      expect(find.byKey(const ValueKey('nav.home.icon')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav.plan.icon')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav.library.icon')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav.settings.icon')), findsOneWidget);
    });

    testWidgets('plan tab navigates to /plan', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            currentNavIndex: 0,
            child: Text('Home Page'),
          ),
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home Page')),
            '/plan': (_) => const Scaffold(body: Text('Plan Page')),
            '/library': (_) => const Scaffold(body: Text('Library Page')),
            '/settings': (_) => const Scaffold(body: Text('Settings Page')),
          },
        ),
      );

      await tester.tap(find.byKey(const ValueKey('nav.plan.icon')));
      await safePumpAndSettle(tester);

      expect(find.text('Plan Page'), findsOneWidget);
    });

    testWidgets('library tab navigates to /library', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            currentNavIndex: 0,
            child: Text('Home Page'),
          ),
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home Page')),
            '/plan': (_) => const Scaffold(body: Text('Plan Page')),
            '/library': (_) => const Scaffold(body: Text('Library Page')),
            '/settings': (_) => const Scaffold(body: Text('Settings Page')),
          },
        ),
      );

      await tester.tap(find.byKey(const ValueKey('nav.library.icon')));
      await safePumpAndSettle(tester);

      expect(find.text('Library Page'), findsOneWidget);
    });

    testWidgets('selected nav item uses brand color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(
            currentNavIndex: 2,
            child: SizedBox.shrink(),
          ),
        ),
      );

      final navGesture = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('nav.library.icon')),
      );
      final container = navGesture.child! as Container;
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.brandPrimaryVariant);
    });
  });

  group('PageContainer', () {
    testWidgets('uses default page padding', (tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageContainer(child: Text('Body')),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, AppSpacing.pageInsets);
    });
  });

  group('PageHeader', () {
    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageHeader(
              title: 'Header',
              subtitle: 'Subheader',
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Subheader'), findsOneWidget);
    });
  });
}
