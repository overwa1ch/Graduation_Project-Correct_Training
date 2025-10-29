import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/result_popup_page.dart';
import 'package:aiwa_app/adapters/result_adapter.dart';

/// HomePage
/// 
/// 主页：按照 Figma 设计稿实现
/// 首屏显示两个绿色卡片，包含占位图和文案
/// 
/// ⚠️ BOUNDARY RULE: 无业务逻辑，仅 UI 占位
/// 所有样式来自 Theme 和 tokens 常量

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'AIWA',
      currentNavIndex: 0,
      showAppBar: false,
      child: Container(
        color: AppColors.surfacePrimary,
        child: PageContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.xxxl),
              
              // 一行两个绿色卡片
              Row(
                children: [
                  Expanded(
                    child: _buildGreenCard(context, theme),
                  ),
                  SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: _buildGreenCard(context, theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建绿色卡片
  /// 包含白色/浅灰占位图和 "Text" 文案
  Widget _buildGreenCard(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        // 点击卡片弹出结果页面
        // Create mock result data for demo
        final mockResult = AnalysisResultLite(
          posture: 84,
          stability: 77,
          rhythm: 71,
          total: 78,
          reps: 12,
          evidencePath: 'evidence/frame_612.jpg',
          lowConfidence: false,
          coverage: 0.76,
          templateName: 'squat',
          strictness: 'strict',
          engine: 'MoveNet',
          fps: 30,
        );

        // Mock session root (empty string since we're using relative path)
        const mockSessionRoot = 'dev';

        showResultPopup(context, mockResult, mockSessionRoot);
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandPrimaryVariant,
          borderRadius: AppRadius.cardRadius,
        ),
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 占位图（白色/浅灰背景，圆角矩形）
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceTertiary,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
            ),
            
            SizedBox(height: AppSpacing.md),
            
            // "Text" 文案（白色）
            Text(
              'Text',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textInvert,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

