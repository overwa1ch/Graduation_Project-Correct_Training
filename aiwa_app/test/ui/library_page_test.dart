import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/ui/pages/library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  setupTestEnvironment();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  Widget wrapWithProvider(Widget child) {
    return ChangeNotifierProvider<ExerciseLibraryService>.value(
      value: ExerciseLibraryService(),
      child: child,
    );
  }

  testWidgets('LibraryPage does not show a back button on root tab page',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/library': (_) => wrapWithProvider(const LibraryPage()),
        },
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/library'),
            child: const Text('Open Library'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Library'));
    await safePumpAndSettle(tester);

    expect(find.text('Library'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byType(BackButton), findsNothing);
  });
}
