import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';

/// 占位：Insights（PR/volume/trend 等后续接入）。
class InsightsPlaceholderPage extends StatelessWidget {
  const InsightsPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        title: const Text('洞察'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Text(
          '数据洞察（PR / 训练量 / 趋势 占位）',
          style: AppTypography.bodyBase.copyWith(
            color: AppColors.textInvert.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
