import 'package:flutter/material.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';

Future<void> showDayViewSheet({
  required BuildContext context,
  required DateOnly date,
  required List<LogEditorDTO> logs,
  required String Function(LogEditorDTO) titleOf,
  required Future<void> Function(LogEditorDTO log) onOpenLog,
  required Future<void> Function(LogEditorDTO log) onDeleteLog,
}) {
  final title = '${date.year}-${date.month}-${date.day}';
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTypography.subheading.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (logs.isEmpty)
              Text(
                '当天暂无日志',
                style: AppTypography.bodyBase.copyWith(
                  color: AppColors.textInvert.withValues(alpha: 0.72),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.45,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (itemContext, index) {
                    final log = logs[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(titleOf(log)),
                      subtitle: Text(log.date),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: '删除',
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              await onDeleteLog(log);
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await onOpenLog(log);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
