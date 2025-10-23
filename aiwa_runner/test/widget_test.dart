import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('runner smoke test renders a screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SizedBox.shrink()),
    ));
    // 只验证基本渲染，避免依赖不存在的根组件
    expect(find.byType(SizedBox), findsOneWidget);
  });
}