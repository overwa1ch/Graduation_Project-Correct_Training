import 'package:flutter/material.dart';

import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';

class EditorPanelLauncher extends StatelessWidget {
  const EditorPanelLauncher({
    super.key,
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? 6 : AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary.withValues(
              alpha: compact ? 0.06 : 0.08,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: compact ? 0.05 : 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 24 : 28,
                height: compact ? 24 : 28,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryVariant.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  size: compact ? 14 : 16,
                  color: AppColors.brandPrimaryVariant,
                ),
              ),
              SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: compact ? 12 : 13,
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 160),
                      crossFadeState: compact
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary.withValues(alpha: 0.66),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 4 : AppSpacing.xs),
              AnimatedRotation(
                turns: compact ? 0.0 : 0.02,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  compact
                      ? Icons.arrow_outward_rounded
                      : Icons.open_in_full_rounded,
                  size: compact ? 14 : 16,
                  color: AppColors.textPrimary.withValues(alpha: 0.48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
