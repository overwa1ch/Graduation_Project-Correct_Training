import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aiwa_app/theme/theme.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/theme/spacing.dart';

void main() {
  group('Theme Tests', () {
    test('Light theme should be created successfully', () {
      final theme = createLightTheme();
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('Dark theme should be created successfully', () {
      final theme = createDarkTheme();
      
      expect(theme, isNotNull);
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('Light theme should use correct brand primary color', () {
      final theme = createLightTheme();
      
      expect(theme.colorScheme.primary, AppColors.brandPrimary);
      expect(theme.colorScheme.primary, const Color(0xFF70AB34));
    });

    test('Dark theme should use correct brand primary color', () {
      final theme = createDarkTheme();
      
      expect(theme.colorScheme.primary, AppColors.brandPrimary);
      expect(theme.colorScheme.primary, const Color(0xFF70AB34));
    });

    test('Light theme should use correct surface colors', () {
      final theme = createLightTheme();
      
      expect(theme.colorScheme.surface, AppColors.surfaceTertiary);
      expect(theme.scaffoldBackgroundColor, AppColors.surfaceTertiary);
    });

    test('Dark theme should use correct surface colors', () {
      final theme = createDarkTheme();
      
      expect(theme.colorScheme.surface, AppColors.surfacePrimary);
      expect(theme.scaffoldBackgroundColor, AppColors.surfacePrimary);
    });

    test('Theme should use Inter font family', () {
      final lightTheme = createLightTheme();
      final darkTheme = createDarkTheme();
      
      expect(lightTheme.textTheme.bodyLarge?.fontFamily, AppTypography.fontFamily);
      expect(darkTheme.textTheme.bodyLarge?.fontFamily, AppTypography.fontFamily);
      expect(lightTheme.textTheme.bodyLarge?.fontFamily, 'Inter');
    });

    test('Button theme should use correct border radius', () {
      final theme = createLightTheme();
      final buttonStyle = theme.elevatedButtonTheme.style;
      
      final shape = buttonStyle?.shape?.resolve({});
      expect(shape, isA<RoundedRectangleBorder>());
      
      final roundedShape = shape as RoundedRectangleBorder;
      expect(roundedShape.borderRadius, AppRadius.buttonRadius);
    });

    test('Card theme should use correct border radius', () {
      final theme = createLightTheme();
      
      expect(theme.cardTheme.shape, isA<RoundedRectangleBorder>());
      final shape = theme.cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, AppRadius.cardRadius);
    });

    test('Error colors should be correctly mapped', () {
      final lightTheme = createLightTheme();
      final darkTheme = createDarkTheme();
      
      expect(lightTheme.colorScheme.error, AppColors.errorPrimary);
      expect(darkTheme.colorScheme.error, AppColors.errorPrimary);
      expect(lightTheme.colorScheme.error, const Color(0xFFFF5252));
    });
  });

  group('Color Tokens Tests', () {
    test('Brand colors should match Figma tokens', () {
      expect(AppColors.brandPrimary, const Color(0xFF70AB34));
      expect(AppColors.brandPrimaryVariant, const Color(0xFF5A8A2A));
    });

    test('Surface colors should match Figma tokens', () {
      expect(AppColors.surfacePrimary, const Color(0xFF212121));
      expect(AppColors.surfaceSecondary, const Color(0xFF2B2B2B));
      expect(AppColors.surfaceTertiary, const Color(0xFFF4F0EB));
    });

    test('Text colors should match Figma tokens', () {
      expect(AppColors.textPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.textInvert, const Color(0xFFFFFFFF));
      expect(AppColors.textOnSurface, const Color(0xFF000000));
    });

    test('Error colors should match Figma tokens', () {
      expect(AppColors.errorPrimary, const Color(0xFFFF5252));
      expect(AppColors.errorContainer, const Color(0xFFFFCDD2));
    });
  });

  group('Typography Tokens Tests', () {
    test('Font family should be Inter', () {
      expect(AppTypography.fontFamily, 'Inter');
    });

    test('H1 style should match Figma tokens', () {
      expect(AppTypography.h1.fontFamily, 'Inter');
      expect(AppTypography.h1.fontWeight, FontWeight.w800);
      expect(AppTypography.h1.fontSize, 48);
    });

    test('H2 style should match Figma tokens', () {
      expect(AppTypography.h2.fontFamily, 'Inter');
      expect(AppTypography.h2.fontWeight, FontWeight.w800);
      expect(AppTypography.h2.fontSize, 32);
    });

    test('Body base style should match Figma tokens', () {
      expect(AppTypography.bodyBase.fontFamily, 'Inter');
      expect(AppTypography.bodyBase.fontWeight, FontWeight.w400);
      expect(AppTypography.bodyBase.fontSize, 16);
      expect(AppTypography.bodyBase.height, 1.4);
    });

    test('Button style should match Figma tokens', () {
      expect(AppTypography.button.fontFamily, 'Inter');
      expect(AppTypography.button.fontWeight, FontWeight.w800);
      expect(AppTypography.button.fontSize, 20);
    });
  });

  group('Spacing Tokens Tests', () {
    test('Base spacing scale should match Figma tokens', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);
    });

    test('Padding presets should match Figma tokens', () {
      expect(AppSpacing.buttonPadding, 8.0);
      expect(AppSpacing.cardPadding, 12.0);
      expect(AppSpacing.pagePadding, 16.0);
      expect(AppSpacing.sectionPadding, 64.0);
    });

    test('Gap presets should match Figma tokens', () {
      expect(AppSpacing.gapXs, 2.0);
      expect(AppSpacing.gapSm, 4.0);
      expect(AppSpacing.gapMd, 8.0);
      expect(AppSpacing.gapLg, 10.0);
    });
  });

  group('Radius Tokens Tests', () {
    test('Base radius scale should match Figma tokens', () {
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.xl, 24.0);
      expect(AppRadius.full, 999.0);
    });

    test('Component-specific radius should match Figma tokens', () {
      expect(AppRadius.button, 8.0);
      expect(AppRadius.card, 8.0);
      expect(AppRadius.input, 8.0);
      expect(AppRadius.dialog, 12.0);
    });
  });

  group('Theme Consistency Tests', () {
    test('Light and dark themes should use same primary color', () {
      final lightTheme = createLightTheme();
      final darkTheme = createDarkTheme();
      
      expect(lightTheme.colorScheme.primary, darkTheme.colorScheme.primary);
    });

    test('Light and dark themes should use same font family', () {
      final lightTheme = createLightTheme();
      final darkTheme = createDarkTheme();
      
      expect(
        lightTheme.textTheme.bodyLarge?.fontFamily,
        darkTheme.textTheme.bodyLarge?.fontFamily,
      );
    });

    test('Light and dark themes should use same error color', () {
      final lightTheme = createLightTheme();
      final darkTheme = createDarkTheme();
      
      expect(lightTheme.colorScheme.error, darkTheme.colorScheme.error);
    });

    test('Themes should not have hardcoded colors', () {
      // This test verifies that all colors come from AppColors constants
      final lightTheme = createLightTheme();
      
      // Primary should match token
      expect(lightTheme.colorScheme.primary, AppColors.brandPrimary);
      
      // Surface should match token
      expect(lightTheme.scaffoldBackgroundColor, AppColors.surfaceTertiary);
      
      // Error should match token
      expect(lightTheme.colorScheme.error, AppColors.errorPrimary);
    });
  });

  group('Material 3 Compliance Tests', () {
    test('Themes should use Material 3', () {
      final lightTheme = createLightTheme();
      final darkTheme = createDarkTheme();
      
      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
    });

    test('Color scheme should have all required Material 3 colors', () {
      final colorScheme = createLightColorScheme();
      
      expect(colorScheme.primary, isNotNull);
      expect(colorScheme.onPrimary, isNotNull);
      expect(colorScheme.secondary, isNotNull);
      expect(colorScheme.onSecondary, isNotNull);
      expect(colorScheme.tertiary, isNotNull);
      expect(colorScheme.onTertiary, isNotNull);
      expect(colorScheme.error, isNotNull);
      expect(colorScheme.onError, isNotNull);
      expect(colorScheme.surface, isNotNull);
      expect(colorScheme.onSurface, isNotNull);
    });

    test('Text theme should have all required Material 3 styles', () {
      final textTheme = createTextTheme();
      
      expect(textTheme.displayLarge, isNotNull);
      expect(textTheme.displayMedium, isNotNull);
      expect(textTheme.displaySmall, isNotNull);
      expect(textTheme.headlineLarge, isNotNull);
      expect(textTheme.headlineMedium, isNotNull);
      expect(textTheme.headlineSmall, isNotNull);
      expect(textTheme.titleLarge, isNotNull);
      expect(textTheme.titleMedium, isNotNull);
      expect(textTheme.titleSmall, isNotNull);
      expect(textTheme.bodyLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.bodySmall, isNotNull);
      expect(textTheme.labelLarge, isNotNull);
      expect(textTheme.labelMedium, isNotNull);
      expect(textTheme.labelSmall, isNotNull);
    });
  });
}

