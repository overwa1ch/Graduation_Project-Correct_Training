import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';

/// ResultPopupPage
/// 
/// 结果展示弹窗页面：显示训练结果
/// 基于 Figma 设计：https://www.figma.com/design/q3hgTOdVGt42WkOfDixtsp/Graduation-Project?node-id=40-6
/// 
/// 包含三个板块：
/// 1. 视频占位（顶部）
/// 2. 打分卡片（中部）
/// 3. 评估详情（底部，可滚动）
/// 
/// ⚠️ BOUNDARY RULE: 无业务逻辑，仅 UI 占位
/// 所有样式来自 Theme 和 tokens 常量

/// 显示结果弹窗的方法
/// 使用方式：showResultPopup(context);
void showResultPopup(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ResultPopupPage(),
  );
}

class ResultPopupPage extends StatelessWidget {
  const ResultPopupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context), // 点击空白处关闭
      behavior: HitTestBehavior.opaque,
      child: GestureDetector(
        onTap: () {}, // 阻止点击内容时关闭
        child: DraggableScrollableSheet(
          initialChildSize: 0.67, // 初始占 2/3 高度
          minChildSize: 0.5,      // 最小 1/2 高度
          maxChildSize: 0.9,      // 最大 9/10 高度
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfacePrimary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // 拖拽指示器
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutralLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // 可滚动内容
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            
                            // 1. 视频占位区域
                            _buildVideoPlaceholder(context),
                            
                            const SizedBox(height: 37),
                            
                            // 2. 打分卡片区域
                            _buildScoreCards(context),
                            
                            const SizedBox(height: 37),
                            
                            // 3. 评估详情区域
                            _buildEvaluationPanel(context),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 视频占位区域（顶部）
  Widget _buildVideoPlaceholder(BuildContext context) {
    return Container(
      width: 343,
      height: 200,
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
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 64,
          color: AppColors.textInvert.withOpacity(0.6),
        ),
      ),
    );
  }

  /// 打分卡片区域（中部）
  Widget _buildScoreCards(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildScoreCard('Posture', '85'),
        const SizedBox(width: 20),
        _buildScoreCard('Stability', '90'),
        const SizedBox(width: 20),
        _buildScoreCard('Rhythm', '88'),
      ],
    );
  }

  /// 单个打分卡片
  Widget _buildScoreCard(String label, String score) {
    return Container(
      width: 100,
      height: 80,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textInvert,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            score,
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textInvert,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 评估详情区域（底部，包含图片和文本）
  Widget _buildEvaluationPanel(BuildContext context) {
    return Container(
      width: 343,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 22),
      child: Column(
        children: [
          // 标题（绝对定位效果，放在顶部）
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Heading',
              style: AppTypography.heading.copyWith(
                color: AppColors.textInvert,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 图片占位
          Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.neutralMedium,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: AppColors.textInvert.withOpacity(0.4),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 文本内容区域
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading
                Text(
                  'Heading',
                  style: AppTypography.heading.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subheading
                Text(
                  'Subheading',
                  style: AppTypography.subheading.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Body text 1
                Text(
                  'Body text for your whole article or post. We\'ll put in some lorem ipsum to show how a filled-out page might look:',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Body text 2
                Text(
                  'Excepteur efficient emerging, minim veniam anim aute carefully curated Ginza conversation exquisite perfect nostrud nisi intricate Content. Qui international first-class nulla ut. Punctual adipisicing, essential lovely queen tempor eiusmod irure. Exclusive izakaya charming Scandinavian impeccable aute quality of life soft power pariatur Melbourne occaecat discerning. Qui wardrobe aliquip, et Porter destination Toto remarkable officia Helsinki excepteur Basset hound. Zürich sleepy perfect consectetur.',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

