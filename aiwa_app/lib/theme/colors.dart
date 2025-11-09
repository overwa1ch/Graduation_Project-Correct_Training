import 'package:flutter/material.dart';

/// Design tokens: Colors
/// Source: Figma Variables (q3hgTOdVGt42WkOfDixtsp)
/// 
/// All color values are derived from tokens/colors.json
/// DO NOT hardcode color values - reference these constants instead
class AppColors {
  AppColors._();

  // Brand Colors (简化后只保留一个绿色)
  static const Color brandPrimaryVariant = Color(0xFF4A7220);

  // Surface Colors
  static const Color surfacePrimary = Color(0xFF212121);
  static const Color surfaceSecondary = Color(0xFF2B2B2B);
  static const Color surfaceTertiary = Color(0xFFF4F0EB);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textInvert = Color(0xFFFFFFFF);
  static const Color textOnSurface = Color(0xFF000000);
  
  // Neutral Colors (保留用于UI组件)
  static const Color neutralLight = Color(0xFFD9D9D9);
}

/// Semantic Colors for Business Logic
/// These colors represent semantic meanings (success, warning, error, etc.)
/// that UI/business logic can use WITHOUT knowing the exact color values.
/// 
/// ⚠️ BOUNDARY RULE: This class contains NO business logic.
/// UI components decide WHEN to use these colors based on business rules.
class SemanticColors {
  SemanticColors._();

  // Status Colors (简化后只有两种颜色)
  static const Color success = AppColors.brandPrimaryVariant;  // 成功/高分 - 深绿色
  static const Color warning = AppColors.surfaceSecondary;      // 警告/中分 - 深灰色
  static const Color error = AppColors.surfaceSecondary;        // 错误/低分 - 深灰色
  
  // Data Visualization (保留用于图表组件)
  static const Color dataHighlight = AppColors.brandPrimaryVariant;
  static const Color dataBackground = AppColors.neutralLight;
  
  // Cloud/AI Enhancement Indicators (保留用于UI组件)
  static const Color cloudEnhanced = AppColors.brandPrimaryVariant;
  static const Color cloudProcessing = AppColors.surfaceSecondary;
}

/// Material 3 ColorScheme mapping (简化版本)
/// 不再支持主题切换，使用固定的深色主题配色
/// 
/// 注意：createLightColorScheme() 和 createLightTheme() 仅用于测试，
/// 生产环境使用 createDarkColorScheme() 和 createDarkTheme()
ColorScheme createLightColorScheme() {
  return const ColorScheme.light(
    primary: AppColors.brandPrimaryVariant,
    onPrimary: AppColors.textInvert,
    secondary: AppColors.surfaceSecondary,
    onSecondary: AppColors.textPrimary,
    error: AppColors.surfaceSecondary,
    onError: AppColors.textInvert,
    surface: AppColors.surfaceTertiary,
    onSurface: AppColors.textOnSurface,
    shadow: AppColors.surfaceSecondary,
  );
}

ColorScheme createDarkColorScheme() {
  return const ColorScheme.dark(
    primary: AppColors.brandPrimaryVariant,
    onPrimary: AppColors.textInvert,
    secondary: AppColors.surfaceSecondary,
    onSecondary: AppColors.textPrimary,
    error: AppColors.surfaceSecondary,
    onError: AppColors.textInvert,
    surface: AppColors.surfacePrimary,
    onSurface: AppColors.textPrimary,
    shadow: AppColors.surfaceSecondary,
  );
}
