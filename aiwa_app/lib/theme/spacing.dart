import 'package:flutter/material.dart';

/// Design tokens: Spacing, Padding, Gap, and Border Radius
/// Source: Figma Variables (q3hgTOdVGt42WkOfDixtsp)
/// 
/// All spacing values are derived from tokens/spacing.json and tokens/radius.json
/// DO NOT hardcode spacing values - reference these constants instead
class AppSpacing {
  AppSpacing._();

  // Base Spacing Scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double huge = 64.0;

  // Padding Presets
  static const double buttonPadding = 8.0;
  static const double cardPadding = 12.0;
  static const double pagePadding = 16.0;
  static const double sectionPadding = 64.0;

  // Gap Presets
  static const double gapXs = 2.0;
  static const double gapSm = 4.0;
  static const double gapMd = 8.0;
  static const double gapLg = 10.0;
  static const double gapXl = 20.0;
  static const double gapXxl = 28.0;
  static const double gapXxxl = 30.0;
  static const double gapHuge = 40.0;

  // Edge Insets Presets
  static const EdgeInsets buttonInsets = EdgeInsets.all(buttonPadding);
  static const EdgeInsets cardInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets pageInsets = EdgeInsets.all(pagePadding);
  static const EdgeInsets sectionInsets = EdgeInsets.all(sectionPadding);

  // Horizontal/Vertical Insets
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

/// Border Radius tokens
class AppRadius {
  AppRadius._();

  // Base Radius Scale
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  // Component-specific Radius
  static const double button = 8.0;
  static const double card = 8.0;
  static const double input = 8.0;
  static const double dialog = 12.0;

  // BorderRadius Presets
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(input));
  static const BorderRadius dialogRadius = BorderRadius.all(Radius.circular(dialog));

  // Circular Radius Presets
  static const BorderRadius circularSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius circularMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius circularLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius circularXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius circularFull = BorderRadius.all(Radius.circular(full));
}

/// Shadow tokens
class AppShadows {
  AppShadows._();

  // Standard shadow from Figma (0px 4px 4px 0px rgba(0, 0, 0, 0.25))
  static const BoxShadow standard = BoxShadow(
    color: Color(0x40000000), // rgba(0, 0, 0, 0.25)
    offset: Offset(0, 4),
    blurRadius: 4,
    spreadRadius: 0,
  );

  // Inset shadow (inset 0px 4px 4px 0px rgba(0, 0, 0, 0.25))
  static const BoxShadow inset = BoxShadow(
    color: Color(0x40000000), // rgba(0, 0, 0, 0.25)
    offset: Offset(0, 4),
    blurRadius: 4,
    spreadRadius: 0,
  );

  // Text shadow (0px 4px 4px 0px rgba(0, 0, 0, 0.25))
  static const Shadow textShadow = Shadow(
    color: Color(0x40000000), // rgba(0, 0, 0, 0.25)
    offset: Offset(0, 4),
    blurRadius: 4,
  );

  // Elevation presets
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> elevation3 = [standard];

  static const List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
}


