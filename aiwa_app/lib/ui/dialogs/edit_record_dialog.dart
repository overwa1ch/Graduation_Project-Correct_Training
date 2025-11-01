import 'package:flutter/material.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/theme/spacing.dart';

/// EditRecordDialog
///
/// 编辑分析记录的对话框
/// 
/// 功能:
/// - 编辑显示名称（必填）
/// - 编辑备注（可选）
/// - 保存/取消操作
///
/// 使用方式：
/// ```dart
/// final result = await showEditRecordDialog(
///   context: context,
///   initialName: 'Squat #1',
///   initialNotes: 'Morning workout',
/// );
/// if (result != null) {
///   print('New name: ${result.displayName}');
///   print('New notes: ${result.notes}');
/// }
/// ```

/// 编辑结果
class EditRecordResult {
  final String displayName;
  final String? notes;

  EditRecordResult({
    required this.displayName,
    this.notes,
  });
}

/// 显示编辑记录对话框
Future<EditRecordResult?> showEditRecordDialog({
  required BuildContext context,
  required String initialName,
  String? initialNotes,
}) async {
  return showDialog<EditRecordResult>(
    context: context,
    builder: (context) => _EditRecordDialog(
      initialName: initialName,
      initialNotes: initialNotes,
    ),
  );
}

class _EditRecordDialog extends StatefulWidget {
  final String initialName;
  final String? initialNotes;

  const _EditRecordDialog({
    required this.initialName,
    this.initialNotes,
  });

  @override
  State<_EditRecordDialog> createState() => _EditRecordDialogState();
}

class _EditRecordDialogState extends State<_EditRecordDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 验证并保存
  void _save() {
    final name = _nameController.text.trim();

    // 验证名称不为空
    if (name.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }

    // 返回结果
    final result = EditRecordResult(
      displayName: name,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      title: Text(
        'Edit Record',
        style: AppTypography.heading.copyWith(
          color: AppColors.textInvert,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    content: SingleChildScrollView(
      child: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名称输入框
            Text(
              'Name',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfacePrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                errorText: _nameError,
                errorStyle: AppTypography.bodyBase.copyWith(
                  color: AppColors.surfaceSecondary,
                  fontSize: 12,
                ),
              ),
              onChanged: (value) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),

            const SizedBox(height: 16),

            // 备注输入框
            Text(
              'Notes (optional)',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textInvert,
                fontSize: 14,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfacePrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                hintText: 'Add notes...',
                hintStyle: AppTypography.bodyBase.copyWith(
                  color: AppColors.textInvert.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
      actions: [
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(
              color: AppColors.textInvert.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),

        // 保存按钮
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandPrimaryVariant,
            foregroundColor: AppColors.textInvert,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
          ),
          child: Text(
            'Save',
            style: AppTypography.button.copyWith(
              color: AppColors.textInvert,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

