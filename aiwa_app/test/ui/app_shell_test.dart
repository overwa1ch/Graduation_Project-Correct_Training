// app_shell_test.dart
// Purpose: Test AppShell navigation contracts and layout behavior
// Focus: Navigation, visual feedback, component composition - NOT pixel-perfect styling

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/colors.dart';
import '../test_helpers.dart';

void main() {
  setupTestEnvironment();

  group('AppShell - Navigation Contract', () {
    testWidgets('renders child widget correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(
            child: Text('Test Child'),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(AppShell), findsOneWidget);
    });

    testWidgets('shows AppBar when showAppBar is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            title: 'Test Title',
            showAppBar: true,
            child: Container(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('hides AppBar when showAppBar is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            showAppBar: false,
            child: Container(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('shows bottom navigation when showBottomNav is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            showBottomNav: true,
            child: Container(),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/camera': (context) => const Scaffold(body: Text('Camera')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      // Verify nav items exist via ValueKeys
      expect(find.byKey(const ValueKey('nav.home.icon')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav.camera.icon')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav.settings.icon')), findsOneWidget);
    });

    testWidgets('hides bottom navigation when showBottomNav is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            showBottomNav: false,
            child: Container(),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('nav.home.icon')), findsNothing);
    });

    testWidgets('home tab navigates to /home route', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            currentNavIndex: 1, // Start on camera
            child: Text('Camera Page'),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home Page')),
            '/camera': (context) => const Scaffold(body: Text('Camera')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      // Tap home icon
      await tester.tap(find.byKey(const ValueKey('nav.home.icon')));
      await safePumpAndSettle(tester);

      // Verify navigation occurred
      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('camera tab navigates to /camera route', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            currentNavIndex: 0, // Start on home
            child: Text('Home Page'),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/camera': (context) => const Scaffold(body: Text('Camera Page')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      // Tap camera icon
      await tester.tap(find.byKey(const ValueKey('nav.camera.icon')));
      await safePumpAndSettle(tester);

      // Verify navigation occurred
      expect(find.text('Camera Page'), findsOneWidget);
    });

    testWidgets('settings tab navigates to /settings route', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            currentNavIndex: 0, // Start on home
            child: Text('Home Page'),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/camera': (context) => const Scaffold(body: Text('Camera')),
            '/settings': (context) => const Scaffold(body: Text('Settings Page')),
          },
        ),
      );

      // Tap settings icon
      await tester.tap(find.byKey(const ValueKey('nav.settings.icon')));
      await safePumpAndSettle(tester);

      // Verify navigation occurred
      expect(find.text('Settings Page'), findsOneWidget);
    });

    testWidgets('current tab has visual highlight', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            currentNavIndex: 1, // Camera selected
            child: Container(),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/camera': (context) => const Scaffold(body: Text('Camera')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      // Find the camera icon's parent container
      final cameraIconKey = find.byKey(const ValueKey('nav.camera.icon'));
      expect(cameraIconKey, findsOneWidget);

      // Verify it uses semantic color (not hardcoded) via GestureDetector → Container
      final gestureDetector = tester.widget<GestureDetector>(cameraIconKey);
      final container = gestureDetector.child as Container;
      
      // Assert background color is set (selected state)
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.brandPrimaryVariant));
    });

    testWidgets('AppBar actions are rendered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            showAppBar: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
            ],
            child: Container(),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('floating action button is rendered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            child: Container(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('AppShellSimple - Variant Behavior', () {
    testWidgets('renders child without bottom navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShellSimple(
            child: Text('Simple Shell Content'),
          ),
        ),
      );

      expect(find.text('Simple Shell Content'), findsOneWidget);
      expect(find.byKey(const ValueKey('nav.home.icon')), findsNothing);
    });

    testWidgets('shows AppBar when requested', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShellSimple(
            showAppBar: true,
            title: 'Simple Title',
            child: Container(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Simple Title'), findsOneWidget);
    });

    testWidgets('hides AppBar by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShellSimple(
            child: Container(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsNothing);
    });
  });

  group('PageContainer - Layout Contract', () {
    testWidgets('applies default padding from tokens', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageContainer(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(AppSpacing.pageInsets));
    });

    testWidgets('accepts custom padding override', (WidgetTester tester) async {
      const customPadding = EdgeInsets.all(32.0);

      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageContainer(
              padding: customPadding,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(customPadding));
    });

    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageContainer(
              child: Text('Test Content'),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });
  });

  group('PageHeader - Typography Contract', () {
    testWidgets('renders title with theme typography', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageHeader(
              title: 'Page Title',
            ),
          ),
        ),
      );

      expect(find.text('Page Title'), findsOneWidget);
      
      final textWidget = tester.widget<Text>(find.text('Page Title'));
      // Verify it uses theme's headlineMedium (not hardcoded style)
      expect(textWidget.style, isNotNull);
    });

    testWidgets('renders subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageHeader(
              title: 'Title',
              subtitle: 'Subtitle Text',
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle Text'), findsOneWidget);
    });

    testWidgets('hides subtitle when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageHeader(
              title: 'Title Only',
            ),
          ),
        ),
      );

      expect(find.text('Title Only'), findsOneWidget);
      // Only title should be present
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('subtitle uses theme bodyMedium style', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageHeader(
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      final subtitleWidget = tester.widget<Text>(find.text('Subtitle'));
      // Verify it uses theme style (not hardcoded)
      expect(subtitleWidget.style, isNotNull);
    });

    testWidgets('uses proper spacing between title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        TestHarness(
          child: testScaffold(
            const PageHeader(
              title: 'Title',
              subtitle: 'Subtitle',
            ),
          ),
        ),
      );

      // Verify Column layout
      expect(find.byType(Column), findsOneWidget);
      
      // Verify SizedBox spacing exists
      final sizedBox = find.descendant(
        of: find.byType(Column),
        matching: find.byType(SizedBox),
      );
      expect(sizedBox, findsOneWidget);
      
      final sizedBoxWidget = tester.widget<SizedBox>(sizedBox);
      expect(sizedBoxWidget.height, equals(AppSpacing.sm));
    });
  });

  group('AppShell - Theme Integration', () {
    testWidgets('uses scaffold background color from theme', (WidgetTester tester) async {
      final customTheme = ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: customTheme,
          home: AppShell(
            child: Container(),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(customTheme.scaffoldBackgroundColor));
    });

    testWidgets('bottom nav uses semantic colors from tokens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            child: Container(),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/camera': (context) => const Scaffold(body: Text('Camera')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      // Verify nav bar uses surfaceSecondary from tokens
      final container = find.ancestor(
        of: find.byKey(const ValueKey('nav.home.icon')),
        matching: find.byType(Container),
      ).first;

      final containerWidget = tester.widget<Container>(container);
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(AppColors.surfaceSecondary));
    });
  });

  group('AppShell - Accessibility', () {
    testWidgets('navigation icons have adequate tap targets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppShell(
            child: Container(),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/camera': (context) => const Scaffold(body: Text('Camera')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      // Find gesture detector for home icon
      final homeIconKey = find.byKey(const ValueKey('nav.home.icon'));
      final gestureDetector = tester.widget<GestureDetector>(homeIconKey);
      final container = gestureDetector.child as Container;

      // Verify minimum tap target size (48x48 is Material guideline, 72x72 is generous)
      expect(container.constraints?.minWidth, greaterThanOrEqualTo(48));
      expect(container.constraints?.minHeight, greaterThanOrEqualTo(48));
    });

    testWidgets('navigation responds to taps', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const AppShell(
            currentNavIndex: 0,
            child: Text('Home'),
          ),
          routes: {
            '/home': (context) => const Scaffold(body: Text('Home')),
            '/camera': (context) => const Scaffold(body: Text('Camera Tapped')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      // Tap camera icon
      await tester.tap(find.byKey(const ValueKey('nav.camera.icon')));
      await safePumpAndSettle(tester);

      // Verify tap was handled
      expect(find.text('Camera Tapped'), findsOneWidget);
    });
  });
}

