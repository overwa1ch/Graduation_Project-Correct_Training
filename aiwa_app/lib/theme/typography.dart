import 'package:flutter/material.dart';

/// Design tokens: Typography
/// Source: Figma Variables (q3hgTOdVGt42WkOfDixtsp)
/// 
/// All typography values are derived from tokens/typography.json
/// DO NOT hardcode font values - reference these constants instead
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Inter';

  // Font Weights
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;

  // Text Styles
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: extraBold,
    fontSize: 48,
    height: 0.583,
    letterSpacing: 0,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontWeight: extraBold,
    fontSize: 32,
    height: 0.875,
    letterSpacing: 0,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontWeight: semiBold,
    fontSize: 24,
    height: 1.2,
    letterSpacing: -0.48, // -2% of 24
  );

  static const TextStyle subheading = TextStyle(
    fontFamily: fontFamily,
    fontWeight: regular,
    fontSize: 20,
    height: 1.2,
    letterSpacing: 0,
  );

  static const TextStyle bodyBase = TextStyle(
    fontFamily: fontFamily,
    fontWeight: regular,
    fontSize: 16,
    height: 1.4,
    letterSpacing: 0,
  );

  static const TextStyle bodyBold = TextStyle(
    fontFamily: fontFamily,
    fontWeight: bold,
    fontSize: 16,
    height: 1.5,
    letterSpacing: 0,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontWeight: extraBold,
    fontSize: 20,
    height: 1.4,
    letterSpacing: 0,
  );
}

/// Material 3 TextTheme mapping
/// Maps design tokens to Material Design 3 text styles
TextTheme createTextTheme({Color? color}) {
  return TextTheme(
    // Display styles (largest)
    displayLarge: AppTypography.h1.copyWith(color: color),
    displayMedium: AppTypography.h1.copyWith(
      fontSize: 45,
      color: color,
    ),
    displaySmall: AppTypography.h2.copyWith(
      fontSize: 36,
      color: color,
    ),

    // Headline styles
    headlineLarge: AppTypography.h2.copyWith(color: color),
    headlineMedium: AppTypography.heading.copyWith(
      fontSize: 28,
      color: color,
    ),
    headlineSmall: AppTypography.heading.copyWith(color: color),

    // Title styles
    titleLarge: AppTypography.subheading.copyWith(
      fontSize: 22,
      fontWeight: AppTypography.semiBold,
      color: color,
    ),
    titleMedium: AppTypography.subheading.copyWith(color: color),
    titleSmall: AppTypography.bodyBold.copyWith(
      fontSize: 14,
      color: color,
    ),

    // Body styles
    bodyLarge: AppTypography.bodyBase.copyWith(
      fontSize: 16,
      color: color,
    ),
    bodyMedium: AppTypography.bodyBase.copyWith(
      fontSize: 14,
      color: color,
    ),
    bodySmall: AppTypography.bodyBase.copyWith(
      fontSize: 12,
      color: color,
    ),

    // Label styles (buttons, chips, etc.)
    labelLarge: AppTypography.button.copyWith(color: color),
    labelMedium: AppTypography.bodyBold.copyWith(
      fontSize: 14,
      color: color,
    ),
    labelSmall: AppTypography.bodyBold.copyWith(
      fontSize: 12,
      color: color,
    ),
  );
}


