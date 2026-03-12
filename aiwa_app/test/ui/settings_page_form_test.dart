import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  setupTestEnvironment();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'user_email': 'athlete@example.com',
    });
  });

  Future<void> pumpSettingsPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const TestHarness(child: SettingsPage()),
    );
    await safePumpAndSettle(tester);
  }

  group('SettingsPage', () {
    testWidgets('renders account card and minimal actions', (tester) async {
      await pumpSettingsPage(tester);

      expect(find.text('athlete@example.com'), findsOneWidget);
      expect(find.byType(AppBottomNavigationBar), findsNothing);
      expect(find.text('Clear Cache & Temp Files'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.byKey(const ValueKey('action.logout')), findsOneWidget);
    });

    testWidgets('does not show a back button when pushed from another route',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/settings': (_) => const SettingsPage(),
          },
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/settings'),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await safePumpAndSettle(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byType(BackButton), findsNothing);
    });

    testWidgets('shows clear data confirmation dialog', (tester) async {
      await pumpSettingsPage(tester);

      await tester.tap(find.byKey(const ValueKey('action.clear_data')));
      await safePumpAndSettle(tester);

      expect(find.text('Clear Data'), findsOneWidget);
      expect(
        find.textContaining('temporary videos and generated local files'),
        findsOneWidget,
      );
    });

    testWidgets('shows sign out confirmation dialog', (tester) async {
      await pumpSettingsPage(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('action.logout')));
      await tester.tap(find.byKey(const ValueKey('action.logout')));
      await safePumpAndSettle(tester);

      expect(find.text('Sign Out'), findsAtLeastNWidgets(1));
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);
    });
  });
}
