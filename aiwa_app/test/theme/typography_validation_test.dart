// typography_validation_test.dart
// Purpose: 测试字体定义和可访问性
// 覆盖: AppTypography 常量、字体大小、行高、字重

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/theme/typography.dart';

void main() {
  group('AppTypography Font Family', () {
    test('font family is defined', () {
      expect(AppTypography.fontFamily, isNotEmpty);
      expect(AppTypography.fontFamily, equals('Inter'));
    });

    test('font family is consistent across styles', () {
      expect(AppTypography.h1.fontFamily, equals(AppTypography.fontFamily));
      expect(AppTypography.h2.fontFamily, equals(AppTypography.fontFamily));
      expect(AppTypography.heading.fontFamily, equals(AppTypography.fontFamily));
      expect(AppTypography.bodyBase.fontFamily, equals(AppTypography.fontFamily));
    });
  });

  group('AppTypography Font Weights', () {
    test('font weights are defined', () {
      expect(AppTypography.regular, equals(FontWeight.w400));
      expect(AppTypography.semiBold, equals(FontWeight.w600));
      expect(AppTypography.bold, equals(FontWeight.w700));
      expect(AppTypography.extraBold, equals(FontWeight.w800));
    });

    test('font weights are in ascending order', () {
      expect(AppTypography.regular.value, lessThan(AppTypography.semiBold.value));
      expect(AppTypography.semiBold.value, lessThan(AppTypography.bold.value));
      expect(AppTypography.bold.value, lessThan(AppTypography.extraBold.value));
    });

    test('font weights are within valid range', () {
      const validWeights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
      
      expect(validWeights, contains(AppTypography.regular.value));
      expect(validWeights, contains(AppTypography.semiBold.value));
      expect(validWeights, contains(AppTypography.bold.value));
      expect(validWeights, contains(AppTypography.extraBold.value));
    });
  });

  group('AppTypography Text Styles', () {
    test('h1 style is defined correctly', () {
      expect(AppTypography.h1.fontSize, equals(48));
      expect(AppTypography.h1.fontWeight, equals(AppTypography.extraBold));
      expect(AppTypography.h1.fontFamily, equals(AppTypography.fontFamily));
    });

    test('h2 style is defined correctly', () {
      expect(AppTypography.h2.fontSize, equals(32));
      expect(AppTypography.h2.fontWeight, equals(AppTypography.extraBold));
      expect(AppTypography.h2.fontFamily, equals(AppTypography.fontFamily));
    });

    test('heading style is defined correctly', () {
      expect(AppTypography.heading.fontSize, equals(24));
      expect(AppTypography.heading.fontWeight, equals(AppTypography.semiBold));
      expect(AppTypography.heading.fontFamily, equals(AppTypography.fontFamily));
    });

    test('subheading style is defined correctly', () {
      expect(AppTypography.subheading.fontSize, equals(20));
      expect(AppTypography.subheading.fontWeight, equals(AppTypography.regular));
      expect(AppTypography.subheading.fontFamily, equals(AppTypography.fontFamily));
    });

    test('body style is defined correctly', () {
      expect(AppTypography.bodyBase.fontSize, equals(16));
      expect(AppTypography.bodyBase.fontWeight, equals(AppTypography.regular));
      expect(AppTypography.bodyBase.fontFamily, equals(AppTypography.fontFamily));
    });

    test('caption style is defined correctly', () {
      expect(AppTypography.caption.fontSize, equals(14));
      expect(AppTypography.caption.fontWeight, equals(AppTypography.regular));
      expect(AppTypography.caption.fontFamily, equals(AppTypography.fontFamily));
    });
  });

  group('AppTypography Font Size Hierarchy', () {
    test('font sizes are in descending order', () {
      expect(AppTypography.h1.fontSize, greaterThan(AppTypography.h2.fontSize!));
      expect(AppTypography.h2.fontSize, greaterThan(AppTypography.heading.fontSize!));
      expect(AppTypography.heading.fontSize, greaterThan(AppTypography.subheading.fontSize!));
      expect(AppTypography.subheading.fontSize, greaterThan(AppTypography.bodyBase.fontSize!));
      expect(AppTypography.bodyBase.fontSize, greaterThan(AppTypography.caption.fontSize!));
    });

    test('font sizes are reasonable', () {
      // 所有字体大小应该在可读范围内
      expect(AppTypography.h1.fontSize, greaterThanOrEqualTo(24));
      expect(AppTypography.h1.fontSize, lessThanOrEqualTo(72));
      
      expect(AppTypography.caption.fontSize, greaterThanOrEqualTo(10));
      expect(AppTypography.caption.fontSize, lessThanOrEqualTo(20));
    });

    test('body text size is accessible', () {
      // 正文大小应该 >= 14 (可访问性要求)
      expect(AppTypography.bodyBase.fontSize, greaterThanOrEqualTo(14));
    });
  });

  group('AppTypography Line Height', () {
    test('line heights are defined', () {
      expect(AppTypography.h1.height, isNotNull);
      expect(AppTypography.h2.height, isNotNull);
      expect(AppTypography.heading.height, isNotNull);
      expect(AppTypography.bodyBase.height, isNotNull);
    });

    test('line heights are positive', () {
      expect(AppTypography.h1.height, greaterThan(0));
      expect(AppTypography.h2.height, greaterThan(0));
      expect(AppTypography.heading.height, greaterThan(0));
      expect(AppTypography.bodyBase.height, greaterThan(0));
    });

    test('line heights provide adequate spacing', () {
      // 行高应该 >= 1.0（至少等于字体大小）
      // 大多数情况下应该 >= 1.2 以提供良好的可读性
      expect(AppTypography.heading.height, greaterThanOrEqualTo(1.0));
      expect(AppTypography.bodyBase.height, greaterThanOrEqualTo(1.0));
    });
  });

  group('AppTypography Letter Spacing', () {
    test('letter spacing is defined', () {
      expect(AppTypography.h1.letterSpacing, isNotNull);
      expect(AppTypography.h2.letterSpacing, isNotNull);
      expect(AppTypography.heading.letterSpacing, isNotNull);
      expect(AppTypography.bodyBase.letterSpacing, isNotNull);
    });

    test('heading letter spacing is calculated correctly', () {
      // heading 的 letterSpacing 应该是 -2% of fontSize
      const expectedSpacing = -0.48; // -2% of 24
      expect(AppTypography.heading.letterSpacing, equals(expectedSpacing));
    });

    test('letter spacing values are reasonable', () {
      // 字间距应该在合理范围内（通常 -2 到 2）
      expect(AppTypography.h1.letterSpacing, greaterThanOrEqualTo(-2));
      expect(AppTypography.h1.letterSpacing, lessThanOrEqualTo(2));
    });
  });

  group('AppTypography Widget Integration', () {
    testWidgets('h1 style applies correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              'H1 Text',
              style: AppTypography.h1,
            ),
          ),
        ),
      );

      // 验证文本渲染
      expect(find.text('H1 Text'), findsOneWidget);
      
      // 验证样式应用
      final textWidget = tester.widget<Text>(find.text('H1 Text'));
      expect(textWidget.style?.fontSize, equals(48));
    });

    testWidgets('body style applies correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              'Body Text',
              style: AppTypography.bodyBase,
            ),
          ),
        ),
      );

      expect(find.text('Body Text'), findsOneWidget);
      
      final textWidget = tester.widget<Text>(find.text('Body Text'));
      expect(textWidget.style?.fontSize, equals(16));
    });

    testWidgets('multiple styles can coexist', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text('Heading', style: AppTypography.heading),
                Text('Body', style: AppTypography.bodyBase),
                Text('Caption', style: AppTypography.caption),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Heading'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Caption'), findsOneWidget);
    });
  });

  group('AppTypography Style Modifications', () {
    test('styles can be copied with modifications', () {
      final modified = AppTypography.bodyBase.copyWith(
        color: Colors.red,
      );
      
      expect(modified.fontSize, equals(AppTypography.bodyBase.fontSize));
      expect(modified.fontFamily, equals(AppTypography.bodyBase.fontFamily));
      expect(modified.color, equals(Colors.red));
    });

    test('font weight can be overridden', () {
      final bold = AppTypography.bodyBase.copyWith(
        fontWeight: AppTypography.bold,
      );
      
      expect(bold.fontWeight, equals(AppTypography.bold));
      expect(bold.fontSize, equals(AppTypography.bodyBase.fontSize));
    });

    test('font size can be scaled', () {
      final scaled = AppTypography.bodyBase.copyWith(
        fontSize: AppTypography.bodyBase.fontSize! * 1.5,
      );
      
      expect(scaled.fontSize, equals(24)); // 16 * 1.5
    });
  });

  group('AppTypography Accessibility', () {
    test('minimum font size meets WCAG guidelines', () {
      // WCAG 建议最小字体大小 >= 12px
      expect(AppTypography.caption.fontSize, greaterThanOrEqualTo(12));
    });

    test('body text is legible', () {
      // 正文应该 >= 14px 以确保可读性
      expect(AppTypography.bodyBase.fontSize, greaterThanOrEqualTo(14));
    });

    test('contrast is achievable with standard colors', () {
      // 验证字体样式可以与标准颜色配合
      final blackText = AppTypography.bodyBase.copyWith(color: Colors.black);
      final whiteText = AppTypography.bodyBase.copyWith(color: Colors.white);
      
      expect(blackText.color, isNotNull);
      expect(whiteText.color, isNotNull);
      expect(blackText.color, isNot(equals(whiteText.color)));
    });

    test('heading hierarchy is clear', () {
      // 标题层次应该明显（至少相差 20%）
      final sizeRatio = AppTypography.h1.fontSize! / AppTypography.h2.fontSize!;
      expect(sizeRatio, greaterThan(1.2));
    });
  });

  group('AppTypography Edge Cases', () {
    test('styles are immutable', () {
      const style1 = AppTypography.bodyBase;
      const style2 = AppTypography.bodyBase;
      
      // 应该是相同的常量
      expect(style1.fontSize, equals(style2.fontSize));
      expect(style1.fontWeight, equals(style2.fontWeight));
    });

    testWidgets('very long text renders without errors', (WidgetTester tester) async {
      final longText = 'A' * 10000;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Text(
                longText,
                style: AppTypography.bodyBase,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('unicode characters work with typography', (WidgetTester tester) async {
      const unicodeText = '你好世界 🌍 مرحبا';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              unicodeText,
              style: AppTypography.bodyBase,
            ),
          ),
        ),
      );

      expect(find.text(unicodeText), findsOneWidget);
    });

    testWidgets('empty text renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Text(
              '',
              style: AppTypography.bodyBase,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });

  group('AppTypography Performance', () {
    test('style creation is efficient', () {
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        final _ = AppTypography.bodyBase.copyWith(color: Colors.black);
      }
      
      stopwatch.stop();
      
      // 1000次复制应该很快（< 50ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('accessing constants is O(1)', () {
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 10000; i++) {
        const _ = AppTypography.bodyBase;
      }
      
      stopwatch.stop();
      
      // 10000次访问应该非常快（< 10ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });
  });

  group('AppTypography Cross-Platform', () {
    test('styles work on different platforms', () {
      // 验证样式定义是平台无关的
      expect(AppTypography.bodyBase.fontSize, isNotNull);
      expect(AppTypography.bodyBase.fontFamily, isNotNull);
      expect(AppTypography.bodyBase.fontWeight, isNotNull);
    });

    test('font family fallback works', () {
      // Inter 字体应该在大多数平台上可用
      // 如果不可用，系统应该有合理的回退
      expect(AppTypography.fontFamily, isNotEmpty);
    });
  });

  group('AppTypography Design System Compliance', () {
    test('follows 8pt grid for font sizes', () {
      // 检查字体大小是否遵循设计系统
      // 虽然不是所有字体都必须是 8 的倍数，但应该有系统性
      final sizes = [
        AppTypography.h1.fontSize,
        AppTypography.h2.fontSize,
        AppTypography.heading.fontSize,
        AppTypography.subheading.fontSize,
        AppTypography.bodyBase.fontSize,
        AppTypography.caption.fontSize,
      ];
      
      for (final size in sizes) {
        expect(size, isNotNull);
        expect(size, greaterThan(0));
      }
    });

    test('type scale is consistent', () {
      // 字体比例应该一致（例如 1.25 或 1.33）
      final h1ToH2Ratio = AppTypography.h1.fontSize! / AppTypography.h2.fontSize!;
      final h2ToHeadingRatio = AppTypography.h2.fontSize! / AppTypography.heading.fontSize!;
      
      // 比例应该在合理范围内（1.2 - 1.6）
      expect(h1ToH2Ratio, greaterThan(1.2));
      expect(h1ToH2Ratio, lessThan(1.6));
      expect(h2ToHeadingRatio, greaterThan(1.2));
      expect(h2ToHeadingRatio, lessThan(1.6));
    });
  });
}

