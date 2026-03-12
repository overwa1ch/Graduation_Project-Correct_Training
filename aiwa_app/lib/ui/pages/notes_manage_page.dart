import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiwa_app/services/notes/note_service.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';

/// Full-screen page to browse and manage all notes.
///
/// Route: '/notes_manage'
/// No route arguments required.
class NotesManagePage extends StatelessWidget {
  const NotesManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePrimary,
        foregroundColor: AppColors.textPrimary,
        title: Text('笔记管理',
            style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textPrimary),
            tooltip: '新建笔记',
            onPressed: () => _openEditor(context, null),
          ),
        ],
      ),
      body: Consumer<NoteService>(
        builder: (context, service, _) {
          final notes = service.notes;
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_alt_outlined,
                      size: 48,
                      color: AppColors.textPrimary.withOpacity(.3)),
                  const SizedBox(height: 12),
                  Text(
                    '暂无笔记',
                    style: AppTypography.bodyBase
                        .copyWith(color: AppColors.textPrimary.withOpacity(.6)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '点击右上角 + 添加第一条笔记',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textPrimary.withOpacity(.4)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteCard(
                note: note,
                onTap: () => _openEditor(context, note),
                onDelete: () => _confirmDelete(context, service, note),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, NoteEntry? note) async {
    final service = context.read<NoteService>();
    await Navigator.pushNamed(
      context,
      '/note_editor',
      arguments: {
        'note': note,
        'noteService': service,
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, NoteService service, NoteEntry note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceSecondary,
        title: Text('删除笔记',
            style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary)),
        content: Text(
          '确定要删除「${note.title.isNotEmpty ? note.title : '无标题笔记'}」吗？此操作不可撤销。',
          style: AppTypography.bodyBase.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await service.delete(note.id);
    }
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final NoteEntry note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title =
        note.title.isNotEmpty ? note.title : '无标题笔记';
    final preview = note.previewText;
    final dateStr = _fmtDate(note.updatedAt.toLocal());

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyBold
                        .copyWith(color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary.withOpacity(.65)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary.withOpacity(.4)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right,
                color: AppColors.textPrimary.withOpacity(.35), size: 20),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
