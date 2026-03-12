import 'package:aiwa_app/ui/pages/camera_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  setupTestEnvironment(failOnOverflow: true);

  testWidgets('tracking settings sheet stays scrollable on small screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(320, 480),
          padding: EdgeInsets.zero,
          devicePixelRatio: 2,
          textScaler: TextScaler.linear(1.0),
        ),
        child: MaterialApp(home: CameraPage()),
      ),
    );

    await safePumpAndSettle(tester);
    await tester.tap(find.byKey(const ValueKey('action.tracking_settings')));
    await safePumpAndSettle(tester);

    expect(find.text('Tracking settings'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
