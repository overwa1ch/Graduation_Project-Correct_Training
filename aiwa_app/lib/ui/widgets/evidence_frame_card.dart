import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';

/// EvidenceFrameCard Widget
/// 
/// ⚠️ BOUNDARY RULE: Displays evidence frames with semantic state colors.
/// Business logic determines the state, colors come from SemanticColors.
/// NO hardcoded Color() values allowed.

enum EvidenceState {
  correct,
  warning,
  error,
  processing,
}

class EvidenceFrameCard extends StatelessWidget {
  final String frameName;
  final String? imageUrl;
  final EvidenceState state;
  final String? stateMessage;
  final bool isCloudProcessed;
  
  const EvidenceFrameCard({
    super.key,
    required this.frameName,
    this.imageUrl,
    required this.state,
    this.stateMessage,
    this.isCloudProcessed = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ✅ CORRECT: Business logic decides state color from semantic colors
    final stateColor = _getStateColor(state);
    final stateIcon = _getStateIcon(state);
    final stateText = stateMessage ?? _getDefaultStateMessage(state);
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Frame Image Area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                // ✅ CORRECT: Using theme's surface color
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                border: Border.all(
                  // ✅ CORRECT: Using semantic color based on state
                  color: stateColor,
                  width: 2,
                ),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholder(context, stateIcon, stateColor);
                      },
                    )
                  : _buildPlaceholder(context, stateIcon, stateColor),
            ),
          ),
          
          // Frame Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frame Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        frameName,
                        // ✅ CORRECT: Using theme's text style
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    if (isCloudProcessed) _buildCloudBadge(context),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // State Indicator
                Row(
                  children: [
                    Icon(
                      stateIcon,
                      size: 16,
                      // ✅ CORRECT: Using semantic state color
                      color: stateColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        stateText,
                        // ✅ CORRECT: Using theme's text style with semantic color
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: stateColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaceholder(
    BuildContext context,
    IconData icon,
    Color color,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            // ✅ CORRECT: Using semantic color
            color: color.withOpacity(0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            // ✅ CORRECT: Using theme's text style
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCloudBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // ✅ CORRECT: Using semantic cloud processing color
        color: SemanticColors.cloudProcessing.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_queue,
            size: 10,
            // ✅ CORRECT: Using semantic color
            color: SemanticColors.cloudProcessing,
          ),
          const SizedBox(width: 3),
          Text(
            'Cloud',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              // ✅ CORRECT: Using semantic color
              color: SemanticColors.cloudProcessing,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
  
  /// ✅ CORRECT: Business logic function returning semantic colors
  Color _getStateColor(EvidenceState state) {
    switch (state) {
      case EvidenceState.correct:
        return SemanticColors.success;
      case EvidenceState.warning:
        return SemanticColors.warning;
      case EvidenceState.error:
        return SemanticColors.error;
      case EvidenceState.processing:
        return SemanticColors.cloudProcessing;
    }
  }
  
  IconData _getStateIcon(EvidenceState state) {
    switch (state) {
      case EvidenceState.correct:
        return Icons.check_circle;
      case EvidenceState.warning:
        return Icons.warning;
      case EvidenceState.error:
        return Icons.error;
      case EvidenceState.processing:
        return Icons.hourglass_empty;
    }
  }
  
  String _getDefaultStateMessage(EvidenceState state) {
    switch (state) {
      case EvidenceState.correct:
        return 'Correct Form';
      case EvidenceState.warning:
        return 'Minor Issues';
      case EvidenceState.error:
        return 'Form Error';
      case EvidenceState.processing:
        return 'Processing...';
    }
  }
}

