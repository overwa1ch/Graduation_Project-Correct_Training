import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';

/// ScoreCard Widget
/// 
/// ⚠️ BOUNDARY RULE: This widget contains business logic to DECIDE colors,
/// but the colors themselves come from SemanticColors or Theme.
/// NO hardcoded Color() values allowed here.
/// 
/// Example: Business logic decides "if score >= 90 use success color",
/// but SemanticColors.success provides the actual color value.

class ScoreCard extends StatelessWidget {
  final String title;
  final double score;
  final bool isCloudEnhanced;
  final String? subtitle;
  
  const ScoreCard({
    super.key,
    required this.title,
    required this.score,
    this.isCloudEnhanced = false,
    this.subtitle,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ✅ CORRECT: Business logic decides WHICH semantic color to use
    final scoreColor = _getScoreColor(score);
    final scoreBgColor = _getScoreBackgroundColor(score);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row with optional cloud badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  // ✅ CORRECT: Using theme's text style
                  style: theme.textTheme.titleMedium,
                ),
                if (isCloudEnhanced) _buildCloudBadge(context),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                // ✅ CORRECT: Using theme's text style with semantic color
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Score Display
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                // ✅ CORRECT: Using semantic color from business logic
                color: scoreBgColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: scoreColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Score',
                    // ✅ CORRECT: Using theme's text style
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    score.toStringAsFixed(1),
                    // ✅ CORRECT: Using semantic color from business logic
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Score Level Indicator
            _buildScoreLevelIndicator(context, score, scoreColor),
          ],
        ),
      ),
    );
  }
  
  /// ✅ CORRECT: Business logic function that returns semantic colors
  /// This function contains the IF logic, but returns colors from SemanticColors
  Color _getScoreColor(double score) {
    if (score >= 90) return SemanticColors.success;
    if (score >= 70) return SemanticColors.warning;
    return SemanticColors.error;
  }
  
  Color _getScoreBackgroundColor(double score) {
    if (score >= 90) return SemanticColors.success;
    if (score >= 70) return SemanticColors.warning;
    return SemanticColors.error;
  }
  
  Widget _buildCloudBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // ✅ CORRECT: Using semantic color for cloud enhancement
        color: SemanticColors.cloudEnhanced.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: SemanticColors.cloudEnhanced,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_done,
            size: 14,
            // ✅ CORRECT: Using semantic color
            color: SemanticColors.cloudEnhanced,
          ),
          const SizedBox(width: 4),
          Text(
            'AI Enhanced',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              // ✅ CORRECT: Using semantic color
              color: SemanticColors.cloudEnhanced,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreLevelIndicator(
    BuildContext context,
    double score,
    Color scoreColor,
  ) {
    final level = _getScoreLevel(score);
    return Row(
      children: [
        Icon(
          _getScoreIcon(score),
          size: 16,
          // ✅ CORRECT: Using color from semantic decision
          color: scoreColor,
        ),
        const SizedBox(width: 8),
        Text(
          level,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            // ✅ CORRECT: Using color from semantic decision
            color: scoreColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  String _getScoreLevel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Needs Improvement';
  }
  
  IconData _getScoreIcon(double score) {
    if (score >= 90) return Icons.check_circle;
    if (score >= 70) return Icons.info;
    return Icons.error;
  }
}

