import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/colors.dart';

/// AppShell
/// 
/// 统一的应用外壳，提供：
/// - AppBar（根据页面配置）
/// - BottomNavigationBar（主要导航页面）
/// - Scaffold 包装
/// 
/// ⚠️ BOUNDARY RULE: 无业务逻辑，仅导航结构
/// 所有样式来自 Theme.of(context) 和 tokens 常量

class AppShell extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showAppBar;
  final bool showBottomNav;
  final List<Widget>? actions;
  final int currentNavIndex;
  final FloatingActionButton? floatingActionButton;

  const AppShell({
    super.key,
    required this.child,
    this.title,
    this.showAppBar = true,
    this.showBottomNav = true,
    this.actions,
    this.currentNavIndex = 0,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ✅ 使用 theme 的 AppBar 配置
      appBar: showAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
              // 所有样式来自 theme.appBarTheme
            )
          : null,
      
      body: child,
      
      // ✅ 底部导航栏（自定义样式）
      bottomNavigationBar: showBottomNav
          ? _CustomBottomNavigationBar(
              currentIndex: currentNavIndex,
              onTap: (index) => _onNavTap(context, index),
            )
          : null,
      
      floatingActionButton: floatingActionButton,
      
      // ✅ 使用 theme 的 scaffold 背景色
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }

  void _onNavTap(BuildContext context, int index) {
    // 根据索引导航到对应页面（无动画）
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(
          context, 
          '/home',
          arguments: {'noAnimation': true},
        );
        break;
      case 1:
        Navigator.pushReplacementNamed(
          context, 
          '/camera',
          arguments: {'noAnimation': true},
        );
        break;
      case 2:
        Navigator.pushReplacementNamed(
          context, 
          '/settings',
          arguments: {'noAnimation': true},
        );
        break;
    }
  }
}

/// AppShell 变体：无底部导航（用于欢迎页、全屏页面等）
class AppShellSimple extends StatelessWidget {
  final Widget child;
  final String? title;
  final bool showAppBar;
  final List<Widget>? actions;

  const AppShellSimple({
    super.key,
    required this.child,
    this.title,
    this.showAppBar = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,
      showAppBar: showAppBar,
      showBottomNav: false,
      actions: actions,
      child: child,
    );
  }
}

/// 页面容器：提供标准的页面内边距
class PageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const PageContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // ✅ 使用 AppSpacing 常量
      padding: padding ?? AppSpacing.pageInsets,
      child: child,
    );
  }
}

/// 页面标题组件
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ 使用 theme 的文本样式
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        if (subtitle != null) ...[
          SizedBox(height: AppSpacing.sm),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// 自定义底部导航栏
/// 根据设计图实现：选中项有绿色圆角背景，未选中为白色图标
class _CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _CustomBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // 增加高度，使按钮更易点击
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.videocam_outlined,
            selectedIcon: Icons.videocam,
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            index: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isSelected ? selectedIcon : icon,
          color: AppColors.textInvert,
          size: 32,
        ),
      ),
    );
  }
}

