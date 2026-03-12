import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';

EditorStyle buildAiwaMobileEditorStyle({
  required EdgeInsets padding,
}) {
  final baseTextStyle = AppTypography.bodyBase.copyWith(
    color: AppColors.textPrimary,
  );

  return EditorStyle.mobile(
    cursorColor: AppColors.brandPrimaryVariant,
    dragHandleColor: AppColors.brandPrimaryVariant,
    selectionColor: const Color.fromARGB(80, 74, 114, 32),
    padding: padding,
    textStyleConfiguration: TextStyleConfiguration(
      text: baseTextStyle,
      lineHeight: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
      bold: baseTextStyle.copyWith(
        fontWeight: FontWeight.w700,
      ),
      italic: baseTextStyle.copyWith(
        fontStyle: FontStyle.italic,
      ),
      underline: baseTextStyle.copyWith(
        decoration: TextDecoration.underline,
      ),
      strikethrough: baseTextStyle.copyWith(
        decoration: TextDecoration.lineThrough,
      ),
      href: baseTextStyle.copyWith(
        color: Colors.lightBlueAccent,
        decoration: TextDecoration.underline,
      ),
      code: baseTextStyle.copyWith(
        color: const Color(0xFFFFD166),
        backgroundColor: const Color(0x332B2B2B),
      ),
    ),
  );
}
