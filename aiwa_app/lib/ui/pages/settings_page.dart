import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/services/storage/session_manager.dart';
import 'package:aiwa_app/services/auth/auth_state.dart';
import 'package:aiwa_app/services/auth/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = AuthService();
      final email = await authService.getCurrentUserEmail();
      if (mounted) {
        setState(() {
          _userEmail = email;
        });
      }
    } catch (e) {
      debugPrint('[SettingsPage] Failed to load user info: $e');
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('退出登录',
            style: AppTypography.h2
                .copyWith(color: AppColors.textInvert, fontSize: 20)),
        content: Text(
          '确定退出当前账号吗？',
          style: AppTypography.bodyBase.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消',
                style: AppTypography.button
                    .copyWith(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.redAccent,
              elevation: 0,
            ),
            child:
                const Text('退出', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final authState = AuthState();
      await authState.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('退出失败：$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 8),
            Text('清理数据',
                style: AppTypography.h2
                    .copyWith(color: AppColors.textInvert, fontSize: 20)),
          ],
        ),
        content: Text(
          '这会删除本机缓存视频和临时文件，云端数据不会受影响。\n\n是否继续？',
          style: AppTypography.bodyBase.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('取消',
                style: AppTypography.button
                    .copyWith(color: AppColors.textPrimary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.orangeAccent,
              elevation: 0,
            ),
            child: const Text('全部清理',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SessionManager.cleanupExpired(days: 0);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('本地数据已清理'),
            backgroundColor: AppColors.brandPrimaryVariant,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[Settings] Failed to cleanup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清理失败：$e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ─── UI Builders ────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.bodyBold.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.6),
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.surfaceSecondary, Color(0xFF2A2A35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.brandPrimaryVariant.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.brandPrimaryVariant.withValues(alpha: 0.5),
                  width: 2),
            ),
            child: const Center(
              child: Icon(Icons.person,
                  color: AppColors.brandPrimaryVariant, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userEmail ?? '未登录',
                  style: AppTypography.h2
                      .copyWith(color: AppColors.textInvert, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimaryVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '云端账号',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.brandPrimaryVariant,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    Key? key,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showArrow = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyBold.copyWith(
                        color: isDestructive
                            ? Colors.redAccent
                            : AppColors.textInvert,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.bodyBase.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (showArrow && !isDestructive)
                const Icon(Icons.chevron_right,
                    color: AppColors.textPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: children.expand((widget) {
          final isLast = widget == children.last;
          return [
            widget,
            if (!isLast)
              const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 60,
                  endIndent: 16,
                  color: AppColors.surfacePrimary),
          ];
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: '设置',
      currentNavIndex: 3,
      showBottomNav: false,
      automaticallyImplyLeading: false, // Ensures no back button
      child: Container(
        color: AppColors.surfacePrimary,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileCard(),

              const SizedBox(height: 8),

              _buildSectionHeader('存储与数据'),
              _buildGroup([
                _buildListTile(
                  key: const ValueKey('action.clear_data'),
                  icon: Icons.cleaning_services_rounded,
                  iconColor: Colors.orangeAccent,
                  title: '清理缓存',
                  subtitle: '释放本地空间',
                  onTap: _clearAllData,
                ),
              ]),

              _buildSectionHeader('关于'),
              _buildGroup([
                _buildListTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.cyanAccent,
                  title: '版本',
                  subtitle: 'v1.0.0 (Build 3)',
                  onTap: () {}, // Decorative
                  showArrow: false,
                ),
                _buildListTile(
                  icon: Icons.description_outlined,
                  iconColor: Colors.amberAccent,
                  title: '服务条款',
                  onTap: () {}, // Placeholder
                ),
                _buildListTile(
                  icon: Icons.privacy_tip_rounded,
                  iconColor: Colors.purpleAccent,
                  title: '隐私政策',
                  onTap: () {}, // Decorative
                ),
              ]),

              const SizedBox(height: 48),

              // Prominent Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    key: const ValueKey('action.logout'),
                    onPressed: _handleLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      foregroundColor: Colors.redAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            width: 1),
                      ),
                    ),
                    child: Text(
                      '退出登录',
                      style: AppTypography.button.copyWith(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 64), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
