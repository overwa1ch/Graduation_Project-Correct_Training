import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/services/config/config_sync.dart';
import 'package:aiwa_core/spec/rule_models.dart';

/// WelcomePage
/// 
/// 欢迎/模式选择页面，无底部导航
/// 
/// 功能：
/// - 显示欢迎信息
/// - 让用户选择评估模式（Relaxed/Strict）
/// - 保存选择到 ConfigSync
/// - 导航到 Home 页面

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // 当前选择的模式（默认 relaxed）
  Strictness _selectedStrictness = Strictness.relaxed;

  /// 保存配置并导航到首页
  Future<void> _onStartPressed() async {
    try {
      // 保存选择的模式到配置服务
      final config = await readAppRuntimeConfig();
      config['strictness'] = _selectedStrictness.value;
      await writeAppRuntimeConfig(config);
      
      debugPrint('[WelcomePage] Saved strictness: ${_selectedStrictness.value}');
      
      // 导航到首页
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'noAnimation': true},
        );
      }
    } catch (e) {
      debugPrint('[WelcomePage] Failed to save config: $e');
      // 即使保存失败，也继续导航（使用默认值）
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'noAnimation': true},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShellSimple(
      child: Center(
        child: PageContainer(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo 占位
                Icon(
                  Icons.fitness_center,
                  size: 100,
                  color: theme.colorScheme.primary,
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 标题
                Text(
                  'AIWA',
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                // 副标题
                Text(
                  'AI-Powered Workout Assistant',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: AppSpacing.xxxl),
                
                // 选择标题
                Text(
                  '选择评估模式',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 新手模式卡片
                _buildModeCard(
                  context: context,
                  strictness: Strictness.relaxed,
                  icon: Icons.sentiment_satisfied_rounded,
                  title: '新手模式 (Relaxed)',
                  description: '标准宽松，更容易获得反馈\n推荐给刚开始练习的用户',
                  isSelected: _selectedStrictness == Strictness.relaxed,
                  onTap: () {
                    setState(() {
                      _selectedStrictness = Strictness.relaxed;
                    });
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // 严格模式卡片
                _buildModeCard(
                  context: context,
                  strictness: Strictness.strict,
                  icon: Icons.emoji_events_rounded,
                  title: '严格模式 (Strict)',
                  description: '专业标准，挑战更高分\n推荐给已掌握基本动作的用户',
                  isSelected: _selectedStrictness == Strictness.strict,
                  onTap: () {
                    setState(() {
                      _selectedStrictness = Strictness.strict;
                    });
                  },
                ),
                
                const SizedBox(height: AppSpacing.xxxl),
                
                // 开始按钮
                ElevatedButton(
                  onPressed: _onStartPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      '开始使用 (${_selectedStrictness == Strictness.relaxed ? '新手模式' : '严格模式'})',
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

  /// 构建模式选择卡片
  Widget _buildModeCard({
    required BuildContext context,
    required Strictness strictness,
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    // 根据选中状态动态确定图标颜色
    final iconColor = isSelected 
        ? SemanticColors.success 
        : SemanticColors.warning;
    
    return GestureDetector(
      onTap: onTap,
      child: Transform.scale(
        scale: isSelected ? 1.05 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            border: Border.all(
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // 图标
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              
              const SizedBox(width: AppSpacing.lg),
              
              // 文字内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 选中标记
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

