import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/result_popup_page.dart';

/// CameraPage
/// 
/// 相机页面：实时姿态检测与训练
/// 基于 Figma 设计：https://www.figma.com/design/q3hgTOdVGt42WkOfDixtsp/Graduation-Project?node-id=14-8
/// 
/// ⚠️ BOUNDARY RULE: 无业务逻辑，仅 UI 占位
/// 所有样式来自 Theme 和 tokens 常量

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      showAppBar: false,
      currentNavIndex: 1,
      child: Container(
        color: AppColors.surfacePrimary,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // 主要内容区域
                Column(
                  children: [
                    // 标题区域
                    _buildTitle(context),
                    
                    const SizedBox(height: 32),
                    
                    // Record New Video 按钮
                    _buildRecordButton(context),
                    
                    const SizedBox(height: 30),
                    
                    // Import Videos 按钮
                    _buildImportButton(context),
                  ],
                ),
                
                const Spacer(),
                
                // 进度条区域
                _buildProgressSection(context),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 标题区域："Welcome to MoveAnalyzer!"
  Widget _buildTitle(BuildContext context) {
    return Column(
      children: [
        Text(
          'Welcome to',
          style: AppTypography.h2.copyWith(
            color: AppColors.textInvert,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 0.875,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'MoveAnalyzer!',
          style: AppTypography.h2.copyWith(
            color: AppColors.textInvert,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 0.875,
          ),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  /// Record New Video 按钮（绿色大按钮）
  Widget _buildRecordButton(BuildContext context) {
    return Container(
      width: 250,
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.brandPrimary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 录制新视频后弹出结果页面
            showResultPopup(context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 视频图标
                Icon(
                  Icons.videocam,
                  color: AppColors.textInvert,
                  size: 30,
                ),
                const SizedBox(width: 8),
                // 文本
                SizedBox(
                  width: 200,
                  child: Text(
                    'Record New Video',
                    style: AppTypography.button.copyWith(
                      color: AppColors.textInvert,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Import Videos 按钮（深灰色按钮）
  Widget _buildImportButton(BuildContext context) {
    return Container(
      width: 200,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 导入视频后弹出结果页面
            showResultPopup(context);
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 上传图标
              Icon(
                Icons.upload,
                color: AppColors.textInvert,
                size: 24,
              ),
              const SizedBox(width: 8),
              // 文本
              Text(
                'Import Videos',
                style: AppTypography.button.copyWith(
                  color: AppColors.textInvert,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 进度条区域（静态 UI，不含动画）
  Widget _buildProgressSection(BuildContext context) {
    return Column(
      children: [
        // 进度条容器
        SizedBox(
          height: 40,
          child: Stack(
            children: [
              // 背景进度条（灰色）
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neutralLight,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 4),
                      blurRadius: 4,
                      spreadRadius: 0,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
              ),
              
              // 前景进度条（绿色，占位50%宽度）
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 172, // 静态宽度，约50%
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        offset: const Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 进度文本
        Text(
          'Analyzing...',
          style: AppTypography.bodyBold.copyWith(
            color: AppColors.textInvert,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

