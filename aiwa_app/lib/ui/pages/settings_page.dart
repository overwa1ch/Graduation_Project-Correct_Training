import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/ui/app_shell.dart';

/// SettingsPage
/// 
/// 设置页面：按照 Figma 设计稿实现
/// 包含用户卡片、分析阈值、分析引擎、数据管理、登出按钮
/// 
/// ⚠️ BOUNDARY RULE: 无业务逻辑，仅 UI 占位
/// 所有样式来自 Theme 和 tokens 常量

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 阈值模式：0=Relaxed, 1=Strict
  int _thresholdMode = 0;
  
  // 推理引擎：0=ML Kit, 1=MoveNet
  int _engineMode = 0;
  
  // 云端备份开关
  bool _cloudBackupEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppShell(
      title: 'Settings',
      currentNavIndex: 2,
      child: Container(
        color: AppColors.surfacePrimary,
        child: SingleChildScrollView(
          child: PageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.md),
                
                // 用户信息卡片（现在也可滑动）
                _buildUserCard(context),
                
                SizedBox(height: AppSpacing.xl),
                
                // Analysis Threshold
                _buildAnalysisThreshold(theme),
                
                SizedBox(height: AppSpacing.xl),
                
                // Analysis Engine
                _buildAnalysisEngine(theme),
                
                SizedBox(height: AppSpacing.xl),
                
                // Data Management
                _buildDataManagement(theme),
                
                SizedBox(height: AppSpacing.xxxl),
                
                // 登出按钮（绿色背景，白色文字）
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context, 
                        '/welcome',
                        arguments: {'noAnimation': true},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: AppColors.textInvert,
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                      ),
                    ),
                    child: const Text('退出登录'),
                  ),
                ),
                
                SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建 Analysis Threshold 板块
  Widget _buildAnalysisThreshold(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Threshold',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Relaxed / Strict 按钮
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Relaxed',
                  isSelected: _thresholdMode == 0,
                  onTap: () {
                    setState(() {
                      _thresholdMode = 0;
                    });
                  },
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _buildToggleButton(
                  label: 'Strict',
                  isSelected: _thresholdMode == 1,
                  onTap: () {
                    setState(() {
                      _thresholdMode = 1;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 构建 Analysis Engine 板块
  Widget _buildAnalysisEngine(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Engine',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.md),
          
          // ML Kit 选项
          _buildRadioOption(
            label: 'ML Kit',
            isSelected: _engineMode == 0,
            onTap: () {
              setState(() {
                _engineMode = 0;
              });
            },
          ),
          
          SizedBox(height: AppSpacing.sm),
          
          // MoveNet 选项
          _buildRadioOption(
            label: 'MoveNet',
            isSelected: _engineMode == 1,
            onTap: () {
              setState(() {
                _engineMode = 1;
              });
            },
          ),
        ],
      ),
    );
  }
  
  /// 构建 Data Management 板块
  Widget _buildDataManagement(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppRadius.cardRadius,
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Management',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Cloud Backup & Sync 开关
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cloud Backup & Sync',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Switch(
                value: _cloudBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _cloudBackupEnabled = value;
                  });
                },
              ),
            ],
          ),
          
          SizedBox(height: AppSpacing.lg),
          
          // Clear Local Data 按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 清除本地数据（占位）
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.textInvert,
                padding: EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
              child: const Text('Clear Local Data'),
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建切换按钮（Relaxed/Strict）
  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.buttonRadius,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.neutralLight,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textInvert : AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
  
  /// 构建单选选项（ML Kit/MoveNet）
  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.brandPrimary : AppColors.textPrimary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  )
                : null,
          ),
          SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建用户信息卡片
  Widget _buildUserCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // 头像
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 36,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            SizedBox(width: AppSpacing.lg),
            
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '训练者',
                    style: theme.textTheme.titleLarge,
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'user@example.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // 编辑按钮
            IconButton(
              onPressed: () {
                // 编辑个人信息（占位）
              },
              icon: const Icon(Icons.edit),
              // ✅ 样式来自 theme
            ),
          ],
        ),
      ),
    );
  }
}



