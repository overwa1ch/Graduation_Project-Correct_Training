import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/theme/spacing.dart';

/// AIWA App Theme
/// 
/// Material 3 theme configuration based on Figma design tokens
/// Source: Figma file q3hgTOdVGt42WkOfDixtsp
/// 
/// All values are derived from design tokens - no hardcoded values
/// See: lib/theme/tokens/ for raw token data

/// Light theme
ThemeData createLightTheme() {
  final colorScheme = createLightColorScheme();
  final textTheme = createTextTheme(color: colorScheme.onSurface);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    fontFamily: AppTypography.fontFamily,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: AppTypography.extraBold,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
      ),
      margin: AppSpacing.cardInsets,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.25),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: AppTypography.bodyBold,
        padding: AppSpacing.buttonInsets,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: AppTypography.bodyBold,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.dialogRadius,
      ),
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceSecondary,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: AppColors.neutralLight,
      type: BottomNavigationBarType.fixed,
      elevation: 4,
      selectedLabelStyle: AppTypography.bodyBold.copyWith(fontSize: 12),
      unselectedLabelStyle: AppTypography.bodyBase.copyWith(fontSize: 12),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.circularLg,
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      labelStyle: AppTypography.bodyBase,
      padding: AppSpacing.buttonInsets,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.circularSm,
      ),
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: colorScheme.outline,
      thickness: 1,
      space: AppSpacing.lg,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withOpacity(0.5);
        }
        return colorScheme.surfaceContainerHighest;
      }),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

/// Dark theme
ThemeData createDarkTheme() {
  final colorScheme = createDarkColorScheme();
  final textTheme = createTextTheme(color: colorScheme.onSurface);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: textTheme,
    fontFamily: AppTypography.fontFamily,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: AppTypography.extraBold,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHighest,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.cardRadius,
      ),
      margin: AppSpacing.cardInsets,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: AppTypography.button,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.25),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: AppTypography.bodyBold,
        padding: AppSpacing.buttonInsets,
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: AppTypography.bodyBold,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
        side: BorderSide(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.inputRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.dialogRadius,
      ),
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceSecondary,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: AppColors.neutralLight,
      type: BottomNavigationBarType.fixed,
      elevation: 4,
      selectedLabelStyle: AppTypography.bodyBold.copyWith(fontSize: 12),
      unselectedLabelStyle: AppTypography.bodyBase.copyWith(fontSize: 12),
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.circularLg,
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      labelStyle: AppTypography.bodyBase,
      padding: AppSpacing.buttonInsets,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.circularSm,
      ),
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: colorScheme.outline,
      thickness: 1,
      space: AppSpacing.lg,
    ),

    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withOpacity(0.5);
        }
        return colorScheme.surfaceContainerHighest;
      }),
    ),

    // Scaffold Background
    scaffoldBackgroundColor: colorScheme.surface,
  );
}

