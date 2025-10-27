import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/ui/app_shell.dart';

/// WelcomePage
/// 
/// 欢迎/启动页面，无底部导航
/// 
/// ⚠️ BOUNDARY RULE: 无业务逻辑，仅 UI 占位
/// 所有样式来自 Theme 和 tokens 常量

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShellSimple(
      child: Center(
        child: PageContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo 占位
              Icon(
                Icons.fitness_center,
                size: 120,
                color: theme.colorScheme.primary,
              ),
              
              SizedBox(height: AppSpacing.xl),
              
              // 标题
              Text(
                'AIWA',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              
              SizedBox(height: AppSpacing.md),
              
              // 副标题
              Text(
                'AI-Powered Workout Assistant',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppSpacing.xxxl),
              
              // 开始按钮
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context, 
                    '/home',
                    arguments: {'noAnimation': true},
                  );
                },
                // ✅ 样式来自 theme.elevatedButtonTheme
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text('开始使用'),
                ),
              ),
              
              SizedBox(height: AppSpacing.lg),
              
              // 跳过按钮
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context, 
                    '/home',
                    arguments: {'noAnimation': true},
                  );
                },
                // ✅ 样式来自 theme.textButtonTheme
                child: const Text('跳过介绍'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

