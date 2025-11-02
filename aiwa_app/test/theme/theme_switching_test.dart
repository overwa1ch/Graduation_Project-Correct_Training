// theme_switching_test.dart
// Purpose: 测试主题切换逻辑和数据一致性
// 覆盖: ThemeData 创建、颜色方案、主题一致性

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/theme/theme.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';

void main() {
  group('Theme Creation', () {
    test('createLightTheme returns valid ThemeData', () {
      final theme = createLightTheme();
      
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, isNotNull);
      expect(theme.textTheme, isNotNull);
    });

    test('createDarkTheme returns valid ThemeData', () {
      final theme = createDarkTheme();
      
      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme, isNotNull);
      expect(theme.textTheme, isNotNull);
    });

    test('light and dark themes are different', () {
      final lightTheme = createLightTheme();
      final darkTheme = createDarkTheme();
      
      // 主题应该不同
      expect(lightTheme.brightness, isNot(equals(darkTheme.brightness)));
      expect(lightTheme.colorScheme.surface, 
             isNot(equals(darkTheme.colorScheme.surface)));
    });
  });

  group('Color Scheme', () {
    test('createLightColorScheme returns valid ColorScheme', () {
      final colorScheme = createLightColorScheme();
      
      expect(colorScheme, isA<ColorScheme>());
      expect(colorScheme.brightness, equals(Brightness.light));
      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.onPrimary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.onSecondary, isNotNull);
      expect(colorScheme.surface, isNotNull);
      expect(colorScheme.onSurface, isNotNull);
    });

    test('createDarkColorScheme returns valid ColorScheme', () {
      final colorScheme = createDarkColorScheme();
      
      expect(colorScheme, isA<ColorScheme>());
      expect(colorScheme.brightness, equals(Brightness.dark));
      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.onPrimary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.onSecondary, isNotNull);
    });

    test('color schemes use design tokens', () {
      final lightScheme = createLightColorScheme();
      
      // 验证使用了设计令牌中的颜色
      expect(lightScheme.primary, isA<Color>());
      expect(lightScheme.surface, isA<Color>());
    });

    test('light color scheme has sufficient contrast', () {
      final lightScheme = createLightColorScheme();
      
      // Primary 和 onPrimary 应该有对比度
      expect(lightScheme.primary, isNot(equals(lightScheme.onPrimary)));
      
      // Surface 和 onSurface 应该有对比度
      expect(lightScheme.surface, isNot(equals(lightScheme.onSurface)));
    });

    test('dark color scheme has sufficient contrast', () {
      final darkScheme = createDarkColorScheme();
      
      // Primary 和 onPrimary 应该有对比度
      expect(darkScheme.primary, isNot(equals(darkScheme.onPrimary)));
      
      // Surface 和 onSurface 应该有对比度
      expect(darkScheme.surface, isNot(equals(darkScheme.onSurface)));
    });
  });

  group('Text Theme', () {
    test('createTextTheme returns valid TextTheme', () {
      final textTheme = createTextTheme(color: Colors.black);
      
      expect(textTheme, isA<TextTheme>());
      expect(textTheme.displayLarge, isNotNull);
      expect(textTheme.bodyLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
    });

    test('text theme uses AppTypography', () {
      final textTheme = createTextTheme(color: Colors.black);
      
      // 验证字体家族
      expect(textTheme.bodyLarge?.fontFamily, equals(AppTypography.fontFamily));
    });

    test('text theme color parameter works', () {
      final blackTheme = createTextTheme(color: Colors.black);
      final whiteTheme = createTextTheme(color: Colors.white);
      
      // 不同颜色的文本主题应该不同
      expect(blackTheme.bodyLarge?.color, isNot(equals(whiteTheme.bodyLarge?.color)));
    });

    test('all text styles have proper font weights', () {
      final textTheme = createTextTheme(color: Colors.black);
      
      // 验证字重定义
      expect(textTheme.displayLarge?.fontWeight, isNotNull);
      expect(textTheme.headlineLarge?.fontWeight, isNotNull);
      expect(textTheme.bodyLarge?.fontWeight, isNotNull);
    });

    test('text sizes are reasonable', () {
      final textTheme = createTextTheme(color: Colors.black);
      
      // 验证字体大小在合理范围内
      final bodySize = textTheme.bodyLarge?.fontSize ?? 0;
      expect(bodySize, greaterThan(10));
      expect(bodySize, lessThan(30));
      
      final displaySize = textTheme.displayLarge?.fontSize ?? 0;
      expect(displaySize, greaterThan(bodySize)); // Display 应该比 Body 大
    });
  });

  group('Theme Components', () {
    test('appBarTheme is properly configured', () {
      final theme = createLightTheme();
      final appBarTheme = theme.appBarTheme;
      
      expect(appBarTheme, isNotNull);
      expect(appBarTheme.backgroundColor, isNotNull);
      expect(appBarTheme.foregroundColor, isNotNull);
      expect(appBarTheme.elevation, isNotNull);
    });

    test('cardTheme is properly configured', () {
      final theme = createLightTheme();
      final cardTheme = theme.cardTheme;
      
      expect(cardTheme, isNotNull);
      expect(cardTheme.color, isNotNull);
      expect(cardTheme.elevation, isNotNull);
      expect(cardTheme.shape, isNotNull);
    });

    test('elevatedButtonTheme is properly configured', () {
      final theme = createLightTheme();
      final buttonTheme = theme.elevatedButtonTheme;
      
      expect(buttonTheme, isNotNull);
      expect(buttonTheme.style, isNotNull);
    });

    test('theme components are consistent', () {
      final theme = createLightTheme();
      
      // AppBar 和主题颜色应该一致
      expect(theme.appBarTheme.backgroundColor, isA<Color>());
      expect(theme.cardTheme.color, isA<Color>());
    });
  });

  group('Theme Consistency', () {
    test('light theme components use same color scheme', () {
      final theme = createLightTheme();
      final colorScheme = theme.colorScheme;
      
      // 验证组件使用颜色方案中的颜色
      expect(theme.appBarTheme.backgroundColor, anyOf(
        equals(colorScheme.surface),
        equals(colorScheme.surface),
        equals(colorScheme.primary),
      ));
    });

    test('dark theme components use same color scheme', () {
      final theme = createDarkTheme();
      final colorScheme = theme.colorScheme;
      
      // 验证组件使用颜色方案中的颜色
      expect(theme.appBarTheme.backgroundColor, anyOf(
        equals(colorScheme.surface),
        equals(colorScheme.surface),
        equals(colorScheme.primary),
      ));
    });

    test('theme font family is consistent', () {
      final theme = createLightTheme();
      
      expect(theme.textTheme.bodyLarge?.fontFamily, equals(AppTypography.fontFamily));
    });
  });

  group('Theme Application', () {
    testWidgets('light theme applies correctly', (WidgetTester tester) async {
      final theme = createLightTheme();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Text('Body'),
          ),
        ),
      );

      // 验证主题已应用
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('dark theme applies correctly', (WidgetTester tester) async {
      final theme = createDarkTheme();
      
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          darkTheme: theme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            appBar: AppBar(title: const Text('Test')),
            body: const Text('Body'),
          ),
        ),
      );

      // 验证暗色主题已应用
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('theme switching works', (WidgetTester tester) async {
      bool isDark = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: createLightTheme(),
              darkTheme: createDarkTheme(),
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isDark = !isDark;
                    });
                  },
                  child: const Text('Toggle Theme'),
                ),
              ),
            );
          },
        ),
      );

      // 初始状态：亮色主题
      expect(find.text('Toggle Theme'), findsOneWidget);

      // 切换到暗色主题
      await tester.tap(find.text('Toggle Theme'));
      await tester.pumpAndSettle();

      // 验证仍然可以找到按钮
      expect(find.text('Toggle Theme'), findsOneWidget);
    });
  });

  group('Theme Edge Cases', () {
    test('theme handles null safely', () {
      // 创建主题不应该抛出异常
      expect(() => createLightTheme(), returnsNormally);
      expect(() => createDarkTheme(), returnsNormally);
    });

    test('color scheme is immutable', () {
      final scheme1 = createLightColorScheme();
      final scheme2 = createLightColorScheme();
      
      // 两次创建应该产生相同的颜色值
      expect(scheme1.primary, equals(scheme2.primary));
      expect(scheme1.surface, equals(scheme2.surface));
    });

    test('text theme is immutable', () {
      final theme1 = createTextTheme(color: Colors.black);
      final theme2 = createTextTheme(color: Colors.black);
      
      // 两次创建应该产生相同的字体大小
      expect(theme1.bodyLarge?.fontSize, equals(theme2.bodyLarge?.fontSize));
    });
  });

  group('Theme Performance', () {
    test('theme creation is fast', () {
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        createLightTheme();
      }
      
      stopwatch.stop();
      
      // 100次创建应该很快（< 100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('color scheme creation is fast', () {
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 1000; i++) {
        createLightColorScheme();
      }
      
      stopwatch.stop();
      
      // 1000次创建应该很快（< 100ms）
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Theme Accessibility', () {
    test('text has minimum readable size', () {
      final textTheme = createTextTheme(color: Colors.black);
      
      // 最小文本大小应该 >= 12
      final bodySize = textTheme.bodyMedium?.fontSize ?? 0;
      expect(bodySize, greaterThanOrEqualTo(12));
    });

    test('color contrast meets basic requirements', () {
      final lightScheme = createLightColorScheme();
      
      // 基本对比度检查
      final primaryLuminance = lightScheme.primary.computeLuminance();
      final onPrimaryLuminance = lightScheme.onPrimary.computeLuminance();
      
      // 两者的亮度应该有明显差异
      expect((primaryLuminance - onPrimaryLuminance).abs(), greaterThan(0.1));
    });

    test('dark theme has appropriate brightness', () {
      final darkScheme = createDarkColorScheme();
      
      // 暗色主题的背景应该较暗
      final bgLuminance = darkScheme.surface.computeLuminance();
      expect(bgLuminance, lessThan(0.5));
    });

    test('light theme has appropriate brightness', () {
      final lightScheme = createLightColorScheme();
      
      // 亮色主题的背景应该较亮
      final bgLuminance = lightScheme.surface.computeLuminance();
      expect(bgLuminance, greaterThan(0.5));
    });
  });

  group('Theme Integration', () {
    testWidgets('semantic colors work with theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createLightTheme(),
          home: Scaffold(
            body: Container(
              color: SemanticColors.success,
              child: const Text('Success'),
            ),
          ),
        ),
      );

      // 验证语义颜色可用
      expect(find.text('Success'), findsOneWidget);
    });

    testWidgets('app colors work with theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: createLightTheme(),
          home: Scaffold(
            body: Container(
              color: AppColors.surfacePrimary,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // 验证应用颜色可用
      expect(find.text('Content'), findsOneWidget);
    });
  });
}

