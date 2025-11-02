import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/result_popup_page.dart';
import 'package:aiwa_app/services/analysis_history.dart';
import 'package:aiwa_app/ui/dialogs/edit_record_dialog.dart';

/// HomePage
/// 
/// 主页：显示分析历史记录为绿色卡片
/// 
/// 功能：
/// - 加载并显示所有历史分析记录
/// - 点击卡片查看结果详情
/// - 长按卡片编辑/删除记录
/// - 网格布局（2 列，可滚动）
/// 
/// ⚠️ BOUNDARY RULE: 最小业务逻辑，主要为数据展示和用户交互
/// 所有样式来自 Theme 和 tokens 常量

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AnalysisRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// 加载历史记录
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      final records = await AnalysisHistoryService().loadAllRecords();
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HomePage] Failed to load records: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 处理卡片点击（显示结果弹窗）
  void _onCardTap(AnalysisRecord record) {
    showResultPopup(context, record.result, record.sessionRoot);
  }

  /// 处理卡片长按（显示编辑/删除菜单）
  void _onCardLongPress(AnalysisRecord record) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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

          // 编辑选项
          ListTile(
            leading: const Icon(Icons.edit, color: AppColors.textInvert),
            title: Text(
              'Edit',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _editRecord(record);
            },
          ),

          // 删除选项
          ListTile(
            leading: const Icon(Icons.delete, color: AppColors.textInvert),
            title: Text(
              'Delete',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 16,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(record);
            },
          ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 编辑记录
  Future<void> _editRecord(AnalysisRecord record) async {
    final result = await showEditRecordDialog(
      context: context,
      initialName: record.displayName,
      initialNotes: record.notes,
    );

    if (result != null) {
      try {
        await AnalysisHistoryService().updateRecord(
          id: record.id,
          displayName: result.displayName,
          notes: result.notes,
        );

        // 重新加载记录
        await _loadRecords();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record updated'),
              backgroundColor: AppColors.brandPrimaryVariant,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('[HomePage] Failed to update record: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update record'),
              backgroundColor: AppColors.surfaceSecondary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// 确认删除记录
  Future<void> _confirmDelete(AnalysisRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        title: Text(
          'Delete Record',
          style: AppTypography.heading.copyWith(
            color: AppColors.textInvert,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${record.displayName}"? This action cannot be undone.',
          style: AppTypography.bodyBase.copyWith(
            color: AppColors.textInvert,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textInvert.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.surfaceSecondary,
              foregroundColor: AppColors.textInvert,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
            ),
            child: Text(
              'Delete',
              style: AppTypography.button.copyWith(
                color: AppColors.textInvert,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AnalysisHistoryService().deleteRecord(
          id: record.id,
          deleteSessionFiles: true,
        );

        // 重新加载记录
        await _loadRecords();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Record deleted'),
              backgroundColor: AppColors.brandPrimaryVariant,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('[HomePage] Failed to delete record: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete record'),
              backgroundColor: AppColors.surfaceSecondary,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'AIWA',
      currentNavIndex: 0,
      showAppBar: false,
      child: Container(
        color: AppColors.surfacePrimary,
        child: PageContainer(
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxxl),

              // 标题
              Text(
                'Training History',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textInvert,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // 历史记录网格
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _records.isEmpty
                        ? _buildEmptyState()
                        : _buildHistoryGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 空状态（无记录）
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: AppColors.textInvert.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No training records yet',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new analysis to see your results here',
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textInvert.withOpacity(0.4),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 历史记录网格
  Widget _buildHistoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.83, // 略高于正方形，适合显示内容
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildHistoryCard(record);
      },
    );
  }

  /// 单个历史记录卡片
  Widget _buildHistoryCard(AnalysisRecord record) {
    // 格式化日期
    final dateStr = _formatDateShort(record.timestamp);
    final timeStr = _formatTimeHM(record.timestamp);

    return GestureDetector(
      onTap: () => _onCardTap(record),
      onLongPress: () => _onCardLongPress(record),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.brandPrimaryVariant,
          borderRadius: AppRadius.cardRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 顶部：总分（右对齐）
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${record.result.total}',
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // 中部：显示名称
            Expanded(
              child: Center(
                child: Text(
                  record.displayName,
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textInvert,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // 底部：次数和日期
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 次数
                Row(
                  children: [
                    const Icon(
                      Icons.repeat,
                      color: AppColors.textInvert,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${record.result.reps} reps',
                      style: AppTypography.bodyBase.copyWith(
                        color: AppColors.textInvert,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 日期时间
                Text(
                  '$dateStr $timeStr',
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textInvert.withOpacity(0.9),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化日期（短格式：MMM dd）
  String _formatDateShort(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final mm = months[(dt.month - 1).clamp(0, 11)];
    final dd = dt.day.toString().padLeft(2, '0');
    return '$mm $dd';
  }

  /// 格式化时间（HH:mm）
  String _formatTimeHM(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
