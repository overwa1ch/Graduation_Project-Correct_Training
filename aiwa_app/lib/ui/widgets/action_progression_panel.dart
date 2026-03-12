import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/widgets/task_template_payload_codec.dart';

class ActionProgressionResolvedItem {
  const ActionProgressionResolvedItem({
    required this.exerciseId,
    required this.displayName,
    required this.config,
    this.entry,
    this.linkLabel,
  });

  final String exerciseId;
  final String displayName;
  final ExerciseEntry? entry;
  final String? linkLabel;
  final TaskTemplateActionProgressionConfig config;

  bool get missingFromLibrary => entry == null;

  double? get bestRecordValue {
    final records = entry?.records ?? const <PrRecord>[];
    if (records.isEmpty) {
      return null;
    }
    var best = 0.0;
    for (final record in records) {
      if (record.value > best) {
        best = record.value;
      }
    }
    return best <= 0 ? null : normalizeExerciseWeight(best);
  }
}

List<ActionProgressionResolvedItem> resolveActionProgressionItems({
  required Iterable<String> actionIds,
  required Map<String, String> labelsById,
  required Map<String, TaskTemplateActionProgressionConfig> configsById,
  required ExerciseLibraryService library,
}) {
  final items = <ActionProgressionResolvedItem>[];
  for (final exerciseId in actionIds) {
    final entry = library.findById(exerciseId);
    final label = (labelsById[exerciseId] ?? '').trim();
    final displayName = entry?.name.trim().isNotEmpty == true
        ? entry!.name.trim()
        : (label.isNotEmpty ? label : 'Unknown action');
    final fallbackConfig = entry == null
        ? TaskTemplateActionProgressionConfig(
            exerciseId: exerciseId,
            targetWeightKg: 0,
            openingPercent:
                TaskTemplateActionProgressionConfig.defaultOpeningPercent,
            endingPercent:
                TaskTemplateActionProgressionConfig.defaultEndingPercent,
            incrementWeightKg:
                TaskTemplateActionProgressionConfig.defaultIncrementWeightKg,
          )
        : TaskTemplateActionProgressionConfig.defaultsFor(entry);
    items.add(
      ActionProgressionResolvedItem(
        exerciseId: exerciseId,
        displayName: displayName,
        linkLabel: label.isEmpty ? null : label,
        entry: entry,
        config: configsById[exerciseId] ?? fallbackConfig,
      ),
    );
  }
  return items;
}

String formatActionProgressionWeight(double value) {
  final normalized = normalizeExerciseWeight(value);
  if ((normalized - normalized.roundToDouble()).abs() < 0.001) {
    return normalized.toStringAsFixed(0);
  }
  return normalized.toStringAsFixed(1);
}

String formatActionProgressionPercent(double value) {
  final normalized = normalizeExerciseWeight(value);
  if ((normalized - normalized.roundToDouble()).abs() < 0.001) {
    return normalized.toStringAsFixed(0);
  }
  return normalized.toStringAsFixed(1);
}

Future<TaskTemplateActionProgressionConfig?> showActionProgressionConfigSheet({
  required BuildContext context,
  required String exerciseName,
  required TaskTemplateActionProgressionConfig initialConfig,
}) {
  return showModalBottomSheet<TaskTemplateActionProgressionConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _ActionProgressionConfigSheet(
        exerciseName: exerciseName,
        initialConfig: initialConfig,
      );
    },
  );
}

Future<void> copyActionProgressionToClipboard({
  required BuildContext context,
  required ActionProgressionResolvedItem item,
}) async {
  final progression = item.config.buildProgression();
  if (progression.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('请先配置动作')),
    );
    return;
  }
  await HapticFeedback.selectionClick();
  final payload = '${item.displayName}: '
      '${progression.map((value) => '${formatActionProgressionWeight(value)}kg').join(' / ')}';
  await Clipboard.setData(ClipboardData(text: payload));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已复制 ${item.displayName} 递增方案')),
  );
}

Future<void> copyAllActionProgressionsToClipboard({
  required BuildContext context,
  required Iterable<ActionProgressionResolvedItem> items,
}) async {
  final lines = <String>[];
  for (final item in items) {
    final progression = item.config.buildProgression();
    if (progression.isEmpty) {
      continue;
    }
    lines.add(
      '${item.displayName}: '
      '${progression.map((value) => '${formatActionProgressionWeight(value)}kg').join(' / ')}',
    );
  }
  if (lines.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('没有可复制的递增方案')),
    );
    return;
  }
  await HapticFeedback.selectionClick();
  await Clipboard.setData(ClipboardData(text: lines.join('\n')));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('已复制 ${lines.length} 个递增方案')),
  );
}

class ActionProgressionPanel extends StatefulWidget {
  const ActionProgressionPanel({
    super.key,
    required this.items,
    this.title = '动作递增',
    this.subtitle,
    this.loading = false,
    this.editable = false,
    this.emptyHint,
    this.onConfigure,
    this.onCopy,
    this.onCopyAll,
    this.initiallyCollapsed = false,
    this.embedded = false,
  });

  final List<ActionProgressionResolvedItem> items;
  final String title;
  final String? subtitle;
  final bool loading;
  final bool editable;
  final String? emptyHint;
  final ValueChanged<ActionProgressionResolvedItem>? onConfigure;
  final ValueChanged<ActionProgressionResolvedItem>? onCopy;
  final Future<void> Function()? onCopyAll;
  final bool initiallyCollapsed;
  final bool embedded;

  @override
  State<ActionProgressionPanel> createState() => _ActionProgressionPanelState();
}

class _ActionProgressionPanelState extends State<ActionProgressionPanel> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final configuredCount =
        widget.items.where((item) => item.config.isConfigured).length;
    final canCopyAll = widget.onCopyAll != null &&
        !widget.loading &&
        widget.items.any((item) => item.config.buildProgression().isNotEmpty);
    final effectiveCollapsed = widget.embedded ? false : _collapsed;

    return Container(
      padding: EdgeInsets.all(widget.embedded ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: widget.embedded
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceSecondary,
                  AppColors.brandPrimaryVariant.withValues(alpha: 0.18),
                ],
              ),
        color: widget.embedded
            ? AppColors.surfacePrimary.withValues(alpha: 0.16)
            : null,
        border: Border.all(
          color: AppColors.brandPrimaryVariant.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.embedded) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        AppColors.brandPrimaryVariant.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.stacked_line_chart_rounded,
                    color: AppColors.brandPrimaryVariant,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: AppTypography.bodyBold.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: AppTypography.caption.copyWith(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (canCopyAll)
                  IconButton(
                    tooltip: '复制全部递增',
                    onPressed: widget.onCopyAll,
                    icon: const Icon(Icons.copy_all_rounded, size: 18),
                  ),
                IconButton(
                  tooltip: effectiveCollapsed ? '展开递增' : '收起递增',
                  onPressed: () => setState(() => _collapsed = !_collapsed),
                  icon: Icon(
                    effectiveCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _HeaderChip(
                  icon: Icons.link_rounded,
                  label: '${widget.items.length} 个已关联',
                  active: widget.items.isNotEmpty,
                ),
                _HeaderChip(
                  icon: Icons.tune_rounded,
                  label: '已配置 $configuredCount 个',
                  active: configuredCount > 0,
                ),
                _HeaderChip(
                  icon: widget.editable
                      ? Icons.edit_outlined
                      : Icons.visibility_outlined,
                  label: widget.editable ? '可编辑' : '只读',
                  active: true,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(height: AppSpacing.lg),
              secondChild: const Padding(
                padding: EdgeInsets.only(top: AppSpacing.md),
                child: Divider(
                  height: 1,
                  color: AppColors.surfacePrimary,
                ),
              ),
              crossFadeState: effectiveCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
          if (effectiveCollapsed)
            Padding(
              padding: EdgeInsets.only(
                top: widget.embedded ? 0 : AppSpacing.md,
              ),
              child: Text(
                configuredCount == 0
                    ? '展开后可配置关联动作。'
                    : '展开后可查看 $configuredCount 个已配置方案。',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.66),
                ),
              ),
            )
          else if (widget.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          else if (widget.items.isEmpty)
            _EmptyPanelHint(
              message: widget.emptyHint ?? '先在上方编辑器插入动作库动作，关联动作会自动出现在这里。',
            )
          else
            Column(
              children: [
                for (int index = 0; index < widget.items.length; index++) ...[
                  _EntranceMotion(
                    key: ValueKey<String>(
                      'action_progression_${widget.items[index].exerciseId}',
                    ),
                    delayMs: 50 + (index * 45),
                    beginOffset: const Offset(0, 0.08),
                    child: _ActionProgressionTile(
                      item: widget.items[index],
                      editable: widget.editable,
                      onConfigure: widget.onConfigure,
                      onCopy: widget.onCopy,
                    ),
                  ),
                  if (index != widget.items.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ActionProgressionTile extends StatefulWidget {
  const _ActionProgressionTile({
    required this.item,
    required this.editable,
    required this.onConfigure,
    required this.onCopy,
  });

  final ActionProgressionResolvedItem item;
  final bool editable;
  final ValueChanged<ActionProgressionResolvedItem>? onConfigure;
  final ValueChanged<ActionProgressionResolvedItem>? onCopy;

  @override
  State<_ActionProgressionTile> createState() => _ActionProgressionTileState();
}

class _ActionProgressionTileState extends State<_ActionProgressionTile> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = false;
  }

  @override
  void didUpdateWidget(covariant _ActionProgressionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.exerciseId != widget.item.exerciseId) {
      _collapsed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final progression = item.config.buildProgression();
    final detailSummary = progression.isEmpty
        ? (item.missingFromLibrary
            ? '动作库中不存在'
            : item.config.isConfigured
                ? '未生成递增方案'
                : '待配置')
        : '${progression.length} 步 · '
            '${formatActionProgressionWeight(item.config.openingWeightKg)}kg'
            ' 到 ${formatActionProgressionWeight(item.config.endingWeightKg)}kg';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onLongPress: widget.onCopy == null ? null : () => widget.onCopy!(item),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary.withValues(
              alpha: _collapsed ? 0.2 : 0.26,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: item.config.isConfigured
                  ? AppColors.brandPrimaryVariant.withValues(
                      alpha: _collapsed ? 0.16 : 0.28,
                    )
                  : AppColors.textPrimary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(
                  alpha: _collapsed ? 0 : 0.06,
                ),
                blurRadius: _collapsed ? 0 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          style: AppTypography.bodyBold.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _MiniChip(
                              label: item.config.isConfigured ? '已配置' : '待配置',
                              tone: item.config.isConfigured
                                  ? _ChipTone.success
                                  : _ChipTone.warning,
                              emphasized: item.config.isConfigured,
                            ),
                            if (item.bestRecordValue != null)
                              _MiniChip(
                                label:
                                    'PR ${formatActionProgressionWeight(item.bestRecordValue!)}kg',
                                emphasized: true,
                              ),
                            if (item.entry?.tagIds.isNotEmpty ?? false)
                              _MiniChip(label: item.entry!.tagIds.join(' · ')),
                            if (item.missingFromLibrary)
                              const _MiniChip(
                                label: '动作库中不存在',
                                tone: _ChipTone.warning,
                              ),
                          ],
                        ),
                        if (widget.editable && widget.onConfigure != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          TextButton.icon(
                            onPressed: () => widget.onConfigure!(item),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandPrimaryVariant,
                              backgroundColor: AppColors.brandPrimaryVariant
                                  .withValues(alpha: 0.08),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 34),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: Icon(
                              item.config.isConfigured
                                  ? Icons.tune_rounded
                                  : Icons.add_circle_outline_rounded,
                              size: 16,
                            ),
                            label: Text(
                              item.config.isConfigured ? '编辑配置' : '设置递增',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.brandPrimaryVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.onCopy != null)
                    IconButton(
                      tooltip: '复制递增',
                      onPressed: () => widget.onCopy!(item),
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                    ),
                  IconButton(
                    tooltip: _collapsed ? '展开动作' : '收起动作',
                    onPressed: () => setState(() => _collapsed = !_collapsed),
                    icon: Icon(
                      _collapsed
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (item.linkLabel != null &&
                  item.linkLabel != item.displayName) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.linkLabel!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.62),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 180),
                crossFadeState: _collapsed
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    detailSummary,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.68),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _MetricPill(
                          label: '目标',
                          value:
                              '${formatActionProgressionWeight(item.config.targetWeightKg)} kg',
                        ),
                        _MetricPill(
                          label: '起始',
                          value:
                              '${formatActionProgressionPercent(item.config.openingPercent)}% · ${formatActionProgressionWeight(item.config.openingWeightKg)} kg',
                        ),
                        _MetricPill(
                          label: '结束',
                          value:
                              '${formatActionProgressionPercent(item.config.endingPercent)}% · ${formatActionProgressionWeight(item.config.endingWeightKg)} kg',
                        ),
                        _MetricPill(
                          label: '步进',
                          value:
                              '+${formatActionProgressionWeight(item.config.incrementWeightKg)} kg',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (progression.isEmpty)
                      Text(
                        item.missingFromLibrary
                            ? '这个关联动作已不在动作库中。'
                            : '设置目标和百分比后会自动生成完整递增。',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.66),
                        ),
                      )
                    else
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (int index = 0;
                              index < progression.length;
                              index++)
                            _EntranceMotion(
                              key: ValueKey<String>(
                                '${item.exerciseId}_${progression[index]}_$index',
                              ),
                              delayMs: 20 + (index * 36),
                              beginOffset: const Offset(0, 0.1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.brandPrimaryVariant
                                      .withValues(alpha: 0.16),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                  border: Border.all(
                                    color: AppColors.brandPrimaryVariant
                                        .withValues(alpha: 0.22),
                                  ),
                                ),
                                child: Text(
                                  '${formatActionProgressionWeight(progression[index])} kg',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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
    );
  }
}

class _EntranceMotion extends StatefulWidget {
  const _EntranceMotion({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.beginOffset = const Offset(0, 0.06),
  });

  final Widget child;
  final int delayMs;
  final Offset beginOffset;

  @override
  State<_EntranceMotion> createState() => _EntranceMotionState();
}

class _EntranceMotionState extends State<_EntranceMotion> {
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
        offset: _visible ? Offset.zero : widget.beginOffset,
        child: widget.child,
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final background = active
        ? AppColors.brandPrimaryVariant.withValues(alpha: 0.16)
        : AppColors.surfacePrimary.withValues(alpha: 0.26);
    final foreground = active
        ? AppColors.textPrimary
        : AppColors.textPrimary.withValues(alpha: 0.72);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ChipTone { neutral, success, warning }

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    this.emphasized = false,
    this.tone = _ChipTone.neutral,
  });

  final String label;
  final bool emphasized;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      _ChipTone.success =>
        AppColors.brandPrimaryVariant.withValues(alpha: 0.18),
      _ChipTone.warning => const Color(0x33FFB74D),
      _ChipTone.neutral when emphasized =>
        AppColors.brandPrimaryVariant.withValues(alpha: 0.16),
      _ChipTone.neutral => AppColors.surfaceSecondary.withValues(alpha: 0.34),
    };

    final foreground = switch (tone) {
      _ChipTone.success => AppColors.textPrimary,
      _ChipTone.warning => const Color(0xFFFFD08A),
      _ChipTone.neutral => AppColors.textPrimary.withValues(
          alpha: emphasized ? 0.92 : 0.72,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: foreground,
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyPanelHint extends StatelessWidget {
  const _EmptyPanelHint({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.link_off_rounded,
            color: AppColors.textPrimary.withValues(alpha: 0.36),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.66),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionProgressionConfigSheet extends StatefulWidget {
  const _ActionProgressionConfigSheet({
    required this.exerciseName,
    required this.initialConfig,
  });

  final String exerciseName;
  final TaskTemplateActionProgressionConfig initialConfig;

  @override
  State<_ActionProgressionConfigSheet> createState() =>
      _ActionProgressionConfigSheetState();
}

class _ActionProgressionConfigSheetState
    extends State<_ActionProgressionConfigSheet> {
  late final TextEditingController _targetController;
  late final TextEditingController _openingController;
  late final TextEditingController _endingController;
  late final TextEditingController _incrementController;

  @override
  void initState() {
    super.initState();
    _targetController = TextEditingController(
      text: _formatForField(widget.initialConfig.targetWeightKg),
    );
    _openingController = TextEditingController(
      text: _formatForField(widget.initialConfig.openingPercent),
    );
    _endingController = TextEditingController(
      text: _formatForField(widget.initialConfig.endingPercent),
    );
    _incrementController = TextEditingController(
      text: _formatForField(widget.initialConfig.incrementWeightKg),
    );
  }

  @override
  void dispose() {
    _targetController.dispose();
    _openingController.dispose();
    _endingController.dispose();
    _incrementController.dispose();
    super.dispose();
  }

  String _formatForField(double value) {
    if (value <= 0) {
      return '';
    }
    return formatActionProgressionWeight(value);
  }

  double _parseValue(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim()) ?? 0;
    return normalizeExerciseWeight(value);
  }

  void _restoreDefaults() {
    _openingController.text = formatActionProgressionPercent(
      TaskTemplateActionProgressionConfig.defaultOpeningPercent,
    );
    _endingController.text = formatActionProgressionPercent(
      TaskTemplateActionProgressionConfig.defaultEndingPercent,
    );
    _incrementController.text = formatActionProgressionWeight(
      TaskTemplateActionProgressionConfig.defaultIncrementWeightKg,
    );
    setState(() {});
  }

  void _clear() {
    Navigator.of(context).pop(
      widget.initialConfig.copyWith(
        targetWeightKg: 0,
        openingPercent:
            TaskTemplateActionProgressionConfig.defaultOpeningPercent,
        endingPercent: TaskTemplateActionProgressionConfig.defaultEndingPercent,
        incrementWeightKg:
            TaskTemplateActionProgressionConfig.defaultIncrementWeightKg,
      ),
    );
  }

  void _save() {
    final target = _parseValue(_targetController);
    final opening = _parseValue(_openingController);
    final ending = _parseValue(_endingController);
    final increment = _parseValue(_incrementController);

    if (target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('目标重量必须大于 0')),
      );
      return;
    }
    if (opening <= 0 || ending <= 0 || increment <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有数值都必须大于 0')),
      );
      return;
    }
    if (ending < opening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('结束百分比必须大于起始百分比'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      widget.initialConfig.copyWith(
        targetWeightKg: target,
        openingPercent: opening,
        endingPercent: ending,
        incrementWeightKg: increment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.initialConfig.copyWith(
      targetWeightKg: _parseValue(_targetController),
      openingPercent: _parseValue(_openingController),
      endingPercent: _parseValue(_endingController),
      incrementWeightKg: _parseValue(_incrementController),
    );
    final progression = draft.buildProgression();

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.brandPrimaryVariant.withValues(alpha: 0.22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    widget.exerciseName,
                    style: AppTypography.heading.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '起始和结束重量按百分比填写，实际重量会根据目标重量自动计算。',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.68),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        TextButton.icon(
                          onPressed: _restoreDefaults,
                          icon: const Icon(Icons.restart_alt_rounded, size: 18),
                          label: const Text('使用 65% / 95% 默认值'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.brandPrimaryVariant,
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                          ),
                        ),
                        if (widget.initialConfig.isConfigured)
                          TextButton.icon(
                            onPressed: _clear,
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            label: const Text('清空配置'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  AppColors.textPrimary.withValues(alpha: 0.72),
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.xs),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _ConfigField(
                          controller: _targetController,
                          label: '目标',
                          suffix: 'kg',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ConfigField(
                          controller: _incrementController,
                          label: '步进',
                          suffix: 'kg',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _ConfigField(
                          controller: _openingController,
                          label: '起始',
                          suffix: '%',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _ConfigField(
                          controller: _endingController,
                          label: '结束',
                          suffix: '%',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfacePrimary.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _MetricPill(
                          label: '起始重量',
                          value:
                              '${formatActionProgressionWeight(draft.openingWeightKg)} kg',
                        ),
                        _MetricPill(
                          label: '结束重量',
                          value:
                              '${formatActionProgressionWeight(draft.endingWeightKg)} kg',
                        ),
                        _MetricPill(
                          label: '步长',
                          value:
                              '+${formatActionProgressionWeight(draft.incrementWeightKg)} kg',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (progression.isEmpty)
                    Text(
                      '输入有效数值后会生成递增方案。',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary.withValues(alpha: 0.64),
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: progression
                          .map(
                            (value) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimaryVariant
                                    .withValues(alpha: 0.16),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                '${formatActionProgressionWeight(value)} kg',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: BorderSide(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.18),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandPrimaryVariant,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: const Text('应用'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfigField extends StatelessWidget {
  const _ConfigField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      onChanged: onChanged,
      style: AppTypography.bodyBase.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        labelStyle: AppTypography.caption.copyWith(
          color: AppColors.textPrimary.withValues(alpha: 0.68),
        ),
        filled: true,
        fillColor: AppColors.surfacePrimary.withValues(alpha: 0.52),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
