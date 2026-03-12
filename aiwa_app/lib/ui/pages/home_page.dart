import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';

import 'package:aiwa_app/services/fit/fit_scope.dart';
import 'package:aiwa_app/services/notes/note_service.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/widgets/aiwa_inline_rich_text_codec.dart';
import 'package:aiwa_app/ui/widgets/appflowy_block_dto_codec.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FitScope.maybeOf(context)?.uiState.refreshHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = FitScope.maybeOf(context);
    final uiState = scope?.uiState;
    if (uiState == null) {
      return AppShell(
        title: 'AIWA',
        automaticallyImplyLeading: false,
        currentNavIndex: 0,
        showAppBar: true,
        showBottomNav: false,
        child: Container(
          color: AppColors.surfacePrimary,
          child: const PageContainer(
            child: Center(child: Text('加载中...')),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: uiState,
      builder: (context, _) {
        return AppShell(
          title: 'AIWA',
          automaticallyImplyLeading: false,
          currentNavIndex: 0,
          showAppBar: true,
          showBottomNav: false,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) => _onActionSelected(context, value),
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'track_trajectory',
                  child: Text('分析视频'),
                ),
                PopupMenuItem<String>(
                  value: 'add_note',
                  child: Text('添加笔记'),
                ),
              ],
            ),
          ],
          child: Container(
            color: AppColors.surfacePrimary,
            child: PageContainer(
              child: _HomeContent(dashboard: uiState.homeDashboard),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onActionSelected(BuildContext context, String value) async {
    switch (value) {
      case 'track_trajectory':
        await Navigator.pushNamed(context, '/camera');
        if (context.mounted) {
          FitScope.maybeOf(context)?.uiState.refreshHome();
        }
        break;
      case 'add_note':
        final noteService = context.read<NoteService>();
        await Navigator.pushNamed(
          context,
          '/note_editor',
          arguments: {'note': null, 'noteService': noteService},
        );
        break;
    }
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({this.dashboard});

  final HomeDashboardDTO? dashboard;

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteService>(
      builder: (context, noteService, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          children: [
            _SectionHeader(
              title: '最近笔记',
              actionLabel: '管理',
              onAction: () => Navigator.pushNamed(context, '/notes_manage'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NotesPanel(noteService: noteService),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1, color: AppColors.surfaceSecondary),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: '今日训练',
              actionLabel: '新建',
              onAction: () => _openNewLog(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TodayTrainingLogs(dashboard: dashboard),
          ],
        );
      },
    );
  }

  Future<void> _openNewLog(BuildContext context) async {
    final date = dashboard?.date.toString();
    await Navigator.pushNamed(
      context,
      '/editor',
      arguments: <String, dynamic>{if (date != null) 'date': date},
    );
    if (context.mounted) {
      await FitScope.maybeOf(context)?.uiState.refreshHome();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.brandPrimaryVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.bodyBold.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: AppTypography.caption.copyWith(
                color: AppColors.brandPrimaryVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({required this.noteService});

  final NoteService noteService;

  @override
  Widget build(BuildContext context) {
    final recentNotes = noteService.recent(3);
    if (recentNotes.isEmpty) {
      return const _EmptyHint(
        icon: Icons.note_alt_outlined,
        title: '还没有笔记',
        hint: '从右上角添加一条笔记，或者在管理页查看历史内容。',
      );
    }

    return Column(
      children: [
        for (int index = 0; index < recentNotes.length; index++) ...[
          _NotePreviewCard(
            note: recentNotes[index],
            onTap: () => _openEditor(context, recentNotes[index]),
          ),
          if (index != recentNotes.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, NoteEntry note) async {
    await Navigator.pushNamed(
      context,
      '/note_editor',
      arguments: {'note': note, 'noteService': noteService},
    );
  }
}

class _NotePreviewCard extends StatelessWidget {
  const _NotePreviewCard({
    required this.note,
    required this.onTap,
  });

  final NoteEntry note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = note.title.trim().isEmpty ? '未命名笔记' : note.title.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (note.previewText.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      note.previewText.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.62),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDateTime(note.updatedAt.toLocal()),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textPrimary.withValues(alpha: 0.36),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTrainingLogs extends StatelessWidget {
  const _TodayTrainingLogs({this.dashboard});

  final HomeDashboardDTO? dashboard;

  @override
  Widget build(BuildContext context) {
    final logs = dashboard?.logs ?? const <LogEditorDTO>[];
    if (logs.isEmpty) {
      return _EmptyHint(
        icon: Icons.fitness_center_outlined,
        title: '今天还没有训练日志',
        hint: '直接创建一条今日日志，后续从这里继续进入即可。',
        actionLabel: '开始记录',
        onAction: () => _openNewLog(context),
      );
    }

    return Column(
      children: [
        for (int index = 0; index < logs.length; index++) ...[
          _HomeEntranceReveal(
            key: ValueKey<String>('home_log_${logs[index].id}'),
            delayMs: 40 + (index * 55),
            child: _TrainingLogCard(log: logs[index]),
          ),
          if (index != logs.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  Future<void> _openNewLog(BuildContext context) async {
    final date = dashboard?.date.toString();
    await Navigator.pushNamed(
      context,
      '/editor',
      arguments: <String, dynamic>{if (date != null) 'date': date},
    );
    if (context.mounted) {
      await FitScope.maybeOf(context)?.uiState.refreshHome();
    }
  }
}

class _HomeEntranceReveal extends StatefulWidget {
  const _HomeEntranceReveal({
    super.key,
    required this.child,
    this.delayMs = 0,
  });

  final Widget child;
  final int delayMs;

  @override
  State<_HomeEntranceReveal> createState() => _HomeEntranceRevealState();
}

class _HomeEntranceRevealState extends State<_HomeEntranceReveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.delayMs <= 0) {
      _visible = true;
      return;
    }
    Future<void>.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) {
        return;
      }
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        child: widget.child,
      ),
    );
  }
}

class _TrainingLogCard extends StatefulWidget {
  const _TrainingLogCard({required this.log});

  final LogEditorDTO log;

  @override
  State<_TrainingLogCard> createState() => _TrainingLogCardState();
}

class _TrainingLogCardState extends State<_TrainingLogCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final title = _logTitle(widget.log);
    final preview = _buildLogPreview(widget.log);
    final editedAt = DateTime.parse(widget.log.lastEditedAtUtc).toLocal();

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLog(context),
          onHighlightChanged: (pressed) {
            if (_pressed == pressed) {
              return;
            }
            setState(() => _pressed = pressed);
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceSecondary,
                  AppColors.brandPrimaryVariant.withValues(
                    alpha: _pressed ? 0.22 : 0.18,
                  ),
                ],
              ),
              border: Border.all(
                color: AppColors.brandPrimaryVariant.withValues(
                  alpha: _pressed ? 0.28 : 0.18,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(
                    alpha: _pressed ? 0.04 : 0.08,
                  ),
                  blurRadius: _pressed ? 10 : 20,
                  offset: Offset(0, _pressed ? 6 : 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOutCubic,
                    width: 68,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary.withValues(
                        alpha: _pressed ? 0.32 : 0.26,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.textPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '\u4eca\u65e5',
                          style: AppTypography.caption.copyWith(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _timeOfDay(editedAt),
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyBold.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyBold.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AnimatedSlide(
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOutCubic,
                              offset: _pressed
                                  ? const Offset(0.08, 0)
                                  : Offset.zero,
                              child: Icon(
                                Icons.open_in_new_rounded,
                                color: AppColors.textPrimary.withValues(
                                  alpha: 0.42,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surfacePrimary.withValues(
                              alpha: _pressed ? 0.24 : 0.18,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '\u6700\u8fd1\u7f16\u8f91',
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  _InfoChip(
                                    label: preview.kind,
                                    dense: true,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                preview.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary.withValues(
                                    alpha: 0.8,
                                  ),
                                  height: 1.38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _InfoChip(
                              label: '${widget.log.blocks.length}项',
                              icon: Icons.layers_outlined,
                            ),
                            if (widget.log.boundTaskOccurrenceId != null)
                              const _InfoChip(
                                label: '\u4efb\u52a1\u65e5\u5fd7',
                                icon: Icons.assignment_outlined,
                              ),
                            _InfoChip(
                              label:
                                  '\u5df2\u66f4\u65b0 ${_timeOfDay(editedAt)}',
                              icon: Icons.schedule_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLog(BuildContext context) async {
    await Navigator.pushNamed(
      context,
      '/editor',
      arguments: <String, dynamic>{'logId': widget.log.id},
    );
    if (context.mounted) {
      await FitScope.maybeOf(context)?.uiState.refreshHome();
    }
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    this.icon,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.sm,
        vertical: dense ? 4 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: dense ? 12 : 14,
              color: AppColors.textPrimary.withValues(alpha: 0.76),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.icon,
    required this.title,
    required this.hint,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.42)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.62),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _LogPreviewData {
  const _LogPreviewData({
    required this.kind,
    required this.text,
  });

  final String kind;
  final String text;
}

String _logTitle(LogEditorDTO log) {
  for (final block in log.blocks) {
    if (block is HeadingBlockDTO) {
      final heading = plainTextFromAiwaRichText(block.text).trim();
      if (heading.isNotEmpty) {
        return heading;
      }
    }

    final summary = describeBlockDto(block).trim();
    if (summary.isNotEmpty) {
      return summary;
    }

    if (block is ExerciseBlockDTO &&
        block.exerciseNameSnapshot.trim().isNotEmpty) {
      return block.exerciseNameSnapshot.trim();
    }
  }

  return '训练日志';
}

_LogPreviewData _buildLogPreview(LogEditorDTO log) {
  final segments = <String>[];
  BlockDTO? latestMeaningfulBlock;

  for (final block in log.blocks.reversed) {
    final summary = describeBlockDto(block).trim();
    if (summary.isEmpty) {
      continue;
    }

    latestMeaningfulBlock ??= block;
    segments.add(summary);
    if (segments.length == 2) {
      break;
    }
  }

  if (segments.isEmpty) {
    return const _LogPreviewData(
      kind: '继续记录',
      text: '打开日志继续记录今天的训练内容。',
    );
  }

  return _LogPreviewData(
    kind: _previewKindForBlock(latestMeaningfulBlock),
    text: segments.join(' · '),
  );
}

String _previewKindForBlock(BlockDTO? block) {
  if (block == null) {
    return '最近编辑';
  }
  if (block is ExerciseBlockDTO) {
    return '动作';
  }
  if (block is ChecklistBlockDTO) {
    return '清单';
  }
  if (block is TableBlockDTO) {
    return '表格';
  }
  if (block is LinkBlockDTO) {
    return '链接';
  }
  if (block is ImageBlockDTO) {
    return '图片';
  }
  if (block is VideoBlockDTO) {
    return '视频';
  }
  if (block is ReferenceBlockDTO) {
    return '引用';
  }
  if (block is TimerMarkerBlockDTO) {
    return '计时';
  }
  if (block is HeadingBlockDTO) {
    return '标题';
  }
  return '最近编辑';
}

String _formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  if (dateTime.year == now.year &&
      dateTime.month == now.month &&
      dateTime.day == now.day) {
    return '今天 ${_timeOfDay(dateTime)}';
  }
  return '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')} '
      '${_timeOfDay(dateTime)}';
}

String _timeOfDay(DateTime dateTime) {
  return '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}';
}
