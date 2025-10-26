import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';

/// AngleLineChart Widget (Simplified Demo)
/// 
/// ⚠️ BOUNDARY RULE: Business logic decides data visualization colors,
/// but colors come from SemanticColors or Theme.
/// NO hardcoded Color() values allowed.

class AngleLineChart extends StatelessWidget {
  final String title;
  final List<double> dataPoints;
  final double threshold;
  final bool showThreshold;
  
  const AngleLineChart({
    super.key,
    required this.title,
    required this.dataPoints,
    this.threshold = 90.0,
    this.showThreshold = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              title,
              // ✅ CORRECT: Using theme's text style
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Chart Area (simplified visualization)
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(double.infinity, 200),
                painter: _AngleLineChartPainter(
                  dataPoints: dataPoints,
                  threshold: threshold,
                  showThreshold: showThreshold,
                  // ✅ CORRECT: Passing semantic colors, not hardcoded values
                  lineColor: SemanticColors.dataHighlight,
                  thresholdColor: SemanticColors.error,
                  backgroundColor: SemanticColors.dataBackground,
                  context: context,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend
            _buildLegend(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          context,
          // ✅ CORRECT: Using semantic color
          color: SemanticColors.dataHighlight,
          label: 'Angle',
        ),
        const SizedBox(width: 24),
        if (showThreshold)
          _buildLegendItem(
            context,
            // ✅ CORRECT: Using semantic color
            color: SemanticColors.error,
            label: 'Threshold',
          ),
      ],
    );
  }
  
  Widget _buildLegendItem(BuildContext context, {required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          // ✅ CORRECT: Using passed semantic color
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          // ✅ CORRECT: Using theme's text style
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Custom Painter for the line chart
/// ⚠️ BOUNDARY RULE: Receives colors as parameters, doesn't hardcode them
class _AngleLineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final double threshold;
  final bool showThreshold;
  final Color lineColor;
  final Color thresholdColor;
  final Color backgroundColor;
  final BuildContext context;
  
  _AngleLineChartPainter({
    required this.dataPoints,
    required this.threshold,
    required this.showThreshold,
    required this.lineColor,
    required this.thresholdColor,
    required this.backgroundColor,
    required this.context,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;
    
    // ✅ CORRECT: Using passed semantic colors, not creating new ones
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final thresholdPaint = Paint()
      ..color = thresholdColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final bgPaint = Paint()
      ..color = backgroundColor.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint,
    );
    
    // Calculate scaling
    final maxValue = dataPoints.reduce((a, b) => a > b ? a : b);
    final minValue = dataPoints.reduce((a, b) => a < b ? a : b);
    final valueRange = maxValue - minValue;
    
    if (valueRange == 0) return;
    
    // Draw threshold line
    if (showThreshold) {
      final thresholdY = size.height - 
        ((threshold - minValue) / valueRange * size.height);
      canvas.drawLine(
        Offset(0, thresholdY),
        Offset(size.width, thresholdY),
        thresholdPaint,
      );
    }
    
    // Draw data line
    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = size.height - 
        ((dataPoints[i] - minValue) / valueRange * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, linePaint);
    
    // Draw data points
    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < dataPoints.length; i++) {
      final x = (i / (dataPoints.length - 1)) * size.width;
      final y = size.height - 
        ((dataPoints[i] - minValue) / valueRange * size.height);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }
  
  @override
  bool shouldRepaint(_AngleLineChartPainter oldDelegate) {
    return dataPoints != oldDelegate.dataPoints ||
      threshold != oldDelegate.threshold ||
      showThreshold != oldDelegate.showThreshold;
  }
}

