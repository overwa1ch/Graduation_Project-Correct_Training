import 'package:flutter/material.dart';

/// Design tokens: Colors
/// Source: Figma Variables (q3hgTOdVGt42WkOfDixtsp)
/// 
/// All color values are derived from tokens/colors.json
/// DO NOT hardcode color values - reference these constants instead
class AppColors {
  AppColors._();

  // Brand Colors
  static const Color brandPrimary = Color(0xFF5A8A2A);
  static const Color brandPrimaryVariant = Color(0xFF4A7220);

  // Surface Colors
  static const Color surfacePrimary = Color(0xFF212121);
  static const Color surfaceSecondary = Color(0xFF2B2B2B);
  static const Color surfaceTertiary = Color(0xFFF4F0EB);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textInvert = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF000000);

  // Error Colors
  static const Color errorPrimary = Color(0xFFFF5252);
  static const Color errorContainer = Color(0xFFFFCDD2);

  // Neutral Colors
  static const Color neutralLight = Color(0xFFD9D9D9);
  static const Color neutralMedium = Color(0xFFE3E3E3);
}

/// Semantic Colors for Business Logic
/// These colors represent semantic meanings (success, warning, error, etc.)
/// that UI/business logic can use WITHOUT knowing the exact color values.
/// 
/// ⚠️ BOUNDARY RULE: This class contains NO business logic.
/// UI components decide WHEN to use these colors based on business rules.
class SemanticColors {
  SemanticColors._();

  // Status Colors
  static const Color success = Color(0xFF70AB34);     // Green for good performance
  static const Color warning = Color(0xFFFFA726);     // Orange for moderate performance
  static const Color error = Color(0xFFFF5252);       // Red for poor performance
  static const Color info = Color(0xFF42A5F5);        // Blue for informational states
  
  // Cloud/AI Enhancement Indicators
  static const Color cloudEnhanced = Color(0xFF9C27B0);  // Purple for AI-enhanced features
  static const Color cloudProcessing = Color(0xFF78909C); // Gray for processing state
  
  // Action Colors
  static const Color actionPrimary = Color(0xFF70AB34);
  static const Color actionSecondary = Color(0xFF5A8A2A);
  static const Color actionDisabled = Color(0xFFD9D9D9);
  
  // State Colors
  static const Color stateActive = Color(0xFF70AB34);
  static const Color stateInactive = Color(0xFFD9D9D9);
  static const Color stateSelected = Color(0xFF5A8A2A);
  
  // Data Visualization (for charts, etc.)
  static const Color dataHighlight = Color(0xFF70AB34);
  static const Color dataSecondary = Color(0xFF42A5F5);
  static const Color dataTertiary = Color(0xFFFFA726);
  static const Color dataBackground = Color(0xFFE3E3E3);
}

/// Material 3 ColorScheme mapping
/// Maps design tokens to Material Design 3 semantic color roles
ColorScheme createLightColorScheme() {
  return ColorScheme.light(
    // Primary colors
    primary: AppColors.brandPrimary,
    onPrimary: AppColors.textInvert,
    primaryContainer: AppColors.brandPrimaryVariant,
    onPrimaryContainer: AppColors.textInvert,

    // Secondary colors (using surface variants)
    secondary: AppColors.surfaceSecondary,
    onSecondary: AppColors.textPrimary,
    secondaryContainer: AppColors.surfaceTertiary,
    onSecondaryContainer: AppColors.textOnSurface,

    // Tertiary colors (using brand variants)
    tertiary: AppColors.brandPrimaryVariant,
    onTertiary: AppColors.textInvert,
    tertiaryContainer: AppColors.brandPrimary,
    onTertiaryContainer: AppColors.textInvert,

    // Error colors
    error: AppColors.errorPrimary,
    onError: AppColors.textInvert,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.errorPrimary,

    // Surface colors
    surface: AppColors.surfaceTertiary,
    onSurface: AppColors.textOnSurface,
    surfaceContainerHighest: AppColors.surfaceSecondary,
    onSurfaceVariant: AppColors.textPrimary,

    // Background (deprecated but still used)
    background: AppColors.surfaceTertiary,
    onBackground: AppColors.textOnSurface,

    // Outline
    outline: AppColors.neutralLight,
    outlineVariant: AppColors.neutralMedium,

    // Shadow
    shadow: Colors.black,
    scrim: Colors.black54,

    // Inverse colors
    inverseSurface: AppColors.surfacePrimary,
    onInverseSurface: AppColors.textPrimary,
    inversePrimary: AppColors.brandPrimary,
  );
}

ColorScheme createDarkColorScheme() {
  return ColorScheme.dark(
    // Primary colors
    primary: AppColors.brandPrimary,
    onPrimary: AppColors.textInvert,
    primaryContainer: AppColors.brandPrimaryVariant,
    onPrimaryContainer: AppColors.textInvert,

    // Secondary colors
    secondary: AppColors.surfaceSecondary,
    onSecondary: AppColors.textPrimary,
    secondaryContainer: AppColors.surfaceTertiary,
    onSecondaryContainer: AppColors.textOnSurface,

    // Tertiary colors
    tertiary: AppColors.brandPrimaryVariant,
    onTertiary: AppColors.textInvert,
    tertiaryContainer: AppColors.brandPrimary,
    onTertiaryContainer: AppColors.textInvert,

    // Error colors
    error: AppColors.errorPrimary,
    onError: AppColors.textInvert,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.errorPrimary,

    // Surface colors
    surface: AppColors.surfacePrimary,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.surfaceSecondary,
    onSurfaceVariant: AppColors.textPrimary,

    // Background (deprecated but still used)
    background: AppColors.surfacePrimary,
    onBackground: AppColors.textPrimary,

    // Outline
    outline: AppColors.neutralLight,
    outlineVariant: AppColors.neutralMedium,

    // Shadow
    shadow: Colors.black,
    scrim: Colors.black87,

    // Inverse colors
    inverseSurface: AppColors.surfaceTertiary,
    onInverseSurface: AppColors.textOnSurface,
    inversePrimary: AppColors.brandPrimary,
  );
}


