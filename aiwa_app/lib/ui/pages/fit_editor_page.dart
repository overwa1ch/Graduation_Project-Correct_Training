import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/services/fit/fit_scope.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/widgets/action_progression_panel.dart';
import 'package:aiwa_app/ui/widgets/aiwa_inline_rich_text_codec.dart';
import 'package:aiwa_app/ui/widgets/editor_panel_launcher.dart';
import 'package:aiwa_app/ui/widgets/inline_log_appflowy_editor.dart';
import 'package:aiwa_app/ui/widgets/task_template_payload_codec.dart';

class FitEditorPage extends StatefulWidget {
  const FitEditorPage({super.key});

  @override
  State<FitEditorPage> createState() => _FitEditorPageState();
}

class _FitEditorPageState extends State<FitEditorPage> {
  final TextEditingController _titleController = TextEditingController();

  LogEditorDTO? _logDto;
  String? _logId;
  String _date = '';
  String? _taskOccurrenceId;
  String _draftTitle = '';
  List<BlockDTO> _editorSeedBlocks = <BlockDTO>[];
  List<BlockDTO> _draftBlocks = <BlockDTO>[];
  final List<String> _templateActionIds = const <String>[];
  final Map<String, TaskTemplateActionProgressionConfig>
      _actionProgressionConfigs =
      <String, TaskTemplateActionProgressionConfig>{};
  int _editorRevision = 0;
  bool _busy = false;
  bool _ignoreTitleChanges = false;
  _LogEditorSnapshot _currentSnapshot = const _LogEditorSnapshot(
    title: '',
    blocks: <BlockDTO>[],
  );
  final List<_LogEditorSnapshot> _undoStack = <_LogEditorSnapshot>[];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_handleTitleChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyArguments());
  }

  void _applyArguments() {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      setState(() {
        _date = _todayDateString();
        _draftTitle = '';
        _editorSeedBlocks = <BlockDTO>[];
        _draftBlocks = <BlockDTO>[];
        _actionProgressionConfigs.clear();
        _resetHistory(title: _draftTitle, blocks: _draftBlocks);
      });
      _setTitleControllerText(_draftTitle);
      return;
    }

    final logId = args['logId'] as String?;
    final date = args['date'] as String?;
    _taskOccurrenceId =
        (args['taskOccurrenceId'] ?? args['planEntryId']) as String?;

    if (logId != null) {
      _logId = logId;
      _loadLog(logId);
      return;
    }

    setState(() {
      _date = date ?? _todayDateString();
      _draftTitle = '';
      _editorSeedBlocks = <BlockDTO>[];
      _draftBlocks = <BlockDTO>[];
      _actionProgressionConfigs.clear();
      _editorRevision += 1;
      _resetHistory(title: _draftTitle, blocks: _draftBlocks);
    });
    _setTitleControllerText(_draftTitle);
  }

  String _todayDateString() {
    final now = DateTime.now();
    return DateOnly(now.year, now.month, now.day).toString();
  }

  String _extractLogTitle(List<BlockDTO> blocks) {
    if (blocks.isNotEmpty && blocks.first is HeadingBlockDTO) {
      final heading = blocks.first as HeadingBlockDTO;
      return plainTextFromAiwaRichText(heading.text).trim();
    }
    return '';
  }

  List<BlockDTO> _extractLogBodyBlocks(List<BlockDTO> blocks) {
    if (blocks.isNotEmpty && blocks.first is HeadingBlockDTO) {
      return blocks.skip(1).toList(growable: false);
    }
    return List<BlockDTO>.from(blocks);
  }

  List<BlockDTO> _composeLogBlocks(String title, List<BlockDTO> bodyBlocks) {
    final blocks = <BlockDTO>[];
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) {
      blocks.add(
        HeadingBlockDTO(
          id: 'heading_${DateTime.now().microsecondsSinceEpoch}',
          text: trimmedTitle,
          level: 1,
        ),
      );
    }
    blocks.addAll(bodyBlocks);
    return blocks;
  }

  void _handleTitleChanged() {
    if (_ignoreTitleChanges) {
      return;
    }
    final value = _titleController.text;
    if (value == _draftTitle) {
      return;
    }
    final nextSnapshot = _LogEditorSnapshot(
      title: value,
      blocks: List<BlockDTO>.from(_draftBlocks),
    );
    if (nextSnapshot.signature == _currentSnapshot.signature) {
      setState(() => _draftTitle = value);
      return;
    }
    setState(() {
      _undoStack.add(_currentSnapshot);
      _currentSnapshot = nextSnapshot;
      _draftTitle = value;
    });
  }

  void _setTitleControllerText(String value) {
    _ignoreTitleChanges = true;
    _titleController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _ignoreTitleChanges = false;
  }

  List<ActionProgressionResolvedItem> _resolveActionProgressionItems(
    ExerciseLibraryService library,
  ) {
    final labelsById = extractExerciseLibraryActionLabels(_draftBlocks);
    return resolveActionProgressionItems(
      actionIds: labelsById.keys,
      labelsById: labelsById,
      configsById: _actionProgressionConfigs,
      library: library,
    );
  }

  List<ActionProgressionResolvedItem> _resolveTemplateActionItems(
    ExerciseLibraryService library,
  ) {
    return _resolveActionProgressionItems(library);
  }

  Map<String, dynamic> _buildLogMetadata() {
    final metadata = Map<String, dynamic>.from(
      _logDto?.metadata ?? const <String, dynamic>{},
    );
    final linkedActionIds = extractExerciseLibraryActionIds(_draftBlocks);
    final actionProgressions = linkedActionIds
        .map((exerciseId) => _actionProgressionConfigs[exerciseId])
        .whereType<TaskTemplateActionProgressionConfig>()
        .where((config) => config.isConfigured)
        .map((config) => config.toJson())
        .toList(growable: false);
    if (actionProgressions.isEmpty) {
      metadata.remove('actionProgressions');
    } else {
      metadata['actionProgressions'] = actionProgressions;
    }
    return metadata;
  }

  Future<void> _saveLogMetadata(
    FitScope scope,
    String logId,
    Map<String, dynamic> metadata,
  ) async {
    final log = await scope.hub.workoutLogRepository.findById(logId);
    if (log == null) {
      return;
    }
    log.replaceMetadata(metadata, DateTime.now().toUtc());
    await scope.hub.workoutLogRepository.save(log);
  }

  Future<void> _editActionProgression(
    ActionProgressionResolvedItem item,
  ) async {
    final result = await showActionProgressionConfigSheet(
      context: context,
      exerciseName: item.displayName,
      initialConfig: item.config,
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _actionProgressionConfigs[item.exerciseId] =
          result.copyWith(exerciseId: item.exerciseId);
    });
  }

  Future<void> _loadLog(String logId) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    try {
      final log = await scope.hub.workoutLogRepository.findById(logId);
      if (!mounted || log == null) {
        return;
      }
      final dto = ApplicationMappers.toLogEditorDTO(log);
      final title = _extractLogTitle(dto.blocks);
      final actionConfigs = <String, TaskTemplateActionProgressionConfig>{};
      for (final config in parseTaskTemplateActionProgressions(dto.metadata)) {
        actionConfigs[config.exerciseId] = config;
      }
      setState(() {
        _logDto = dto;
        _date = dto.date;
        _draftTitle = title;
        _editorSeedBlocks = _extractLogBodyBlocks(dto.blocks);
        _draftBlocks = List<BlockDTO>.from(dto.blocks);
        _actionProgressionConfigs
          ..clear()
          ..addAll(actionConfigs);
        _editorRevision += 1;
        _resetHistory(title: _draftTitle, blocks: _draftBlocks);
      });
      _setTitleControllerText(title);
    } catch (_) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _save() async {
    final scope = FitScope.maybeOf(context);
    if (scope == null || _busy) {
      return;
    }

    final blocksToSave =
        _composeLogBlocks(_draftTitle, _extractLogBodyBlocks(_draftBlocks));
    final metadata = _buildLogMetadata();

    try {
      setState(() => _busy = true);
      if (_logId != null) {
        await _syncExistingLog(scope, blocksToSave);
        await _saveLogMetadata(scope, _logId!, metadata);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        return;
      }

      await scope.hub.createWorkoutLogUseCase.execute(
        CreateWorkoutLogInput(
          date: _date,
          boundTaskOccurrenceId: _taskOccurrenceId,
          metadata: metadata,
          blocks: blocksToSave,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存失败')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _syncExistingLog(
    FitScope scope,
    List<BlockDTO> nextBlocks,
  ) async {
    final logId = _logId;
    if (logId == null) {
      return;
    }

    final original = _logDto?.blocks ?? const <BlockDTO>[];
    final next = nextBlocks;
    final common = math.min(original.length, next.length);
    LogEditorDTO? latest = _logDto;

    for (int i = 0; i < common; i++) {
      final oldBlock = original[i];
      final updatedBlock = _copyBlockWithId(next[i], oldBlock.id);
      latest = await scope.hub.updateBlockUseCase.execute(
        UpdateBlockInput(
          logId: logId,
          blockId: oldBlock.id,
          block: updatedBlock,
        ),
      );
    }

    for (int i = common; i < next.length; i++) {
      latest = await scope.hub.appendBlockUseCase.execute(
        AppendBlockInput(logId: logId, block: next[i]),
      );
    }

    for (int i = original.length - 1; i >= next.length; i--) {
      latest = await scope.hub.removeBlockUseCase.execute(
        RemoveBlockInput(logId: logId, blockId: original[i].id),
      );
    }

    if (!mounted || latest == null) {
      return;
    }
    final safeLatest = latest;
    final title = _extractLogTitle(safeLatest.blocks);
    setState(() {
      _logDto = safeLatest;
      _draftTitle = title;
      _editorSeedBlocks = _extractLogBodyBlocks(safeLatest.blocks);
      _draftBlocks = List<BlockDTO>.from(safeLatest.blocks);
      _editorRevision += 1;
      _resetHistory(title: _draftTitle, blocks: _draftBlocks);
    });
    _setTitleControllerText(title);
  }

  BlockDTO _copyBlockWithId(BlockDTO block, String id) {
    if (block is TextBlockDTO) {
      return TextBlockDTO(id: id, text: block.text);
    }
    if (block is HeadingBlockDTO) {
      return HeadingBlockDTO(id: id, text: block.text, level: block.level);
    }
    if (block is DividerBlockDTO) {
      return DividerBlockDTO(id: id);
    }
    if (block is ExerciseBlockDTO) {
      return ExerciseBlockDTO(
        id: id,
        exerciseId: block.exerciseId,
        exerciseNameSnapshot: block.exerciseNameSnapshot,
        sets: block.sets,
        note: block.note,
        rpe: block.rpe,
      );
    }
    if (block is ImageBlockDTO) {
      return ImageBlockDTO(
        id: id,
        attachments: block.attachments,
        caption: block.caption,
      );
    }
    if (block is VideoBlockDTO) {
      return VideoBlockDTO(
        id: id,
        attachments: block.attachments,
        caption: block.caption,
      );
    }
    if (block is ChecklistBlockDTO) {
      return ChecklistBlockDTO(id: id, items: block.items);
    }
    if (block is TimerMarkerBlockDTO) {
      return TimerMarkerBlockDTO(
        id: id,
        kind: block.kind,
        atUtc: block.atUtc,
        label: block.label,
      );
    }
    if (block is ReferenceBlockDTO) {
      return ReferenceBlockDTO(
        id: id,
        refType: block.refType,
        refId: block.refId,
        previewText: block.previewText,
      );
    }
    if (block is LinkBlockDTO) {
      return LinkBlockDTO(
        id: id,
        url: block.url,
        title: block.title,
        note: block.note,
      );
    }
    if (block is TableBlockDTO) {
      return TableBlockDTO(
        id: id,
        columnCount: block.columnCount,
        rows: block.rows,
      );
    }
    return block;
  }

  void _resetHistory({
    required String title,
    required List<BlockDTO> blocks,
  }) {
    _currentSnapshot = _LogEditorSnapshot(
      title: title,
      blocks: List<BlockDTO>.from(blocks),
    );
    _undoStack.clear();
  }

  void _captureDraft(InlineLogDraft draft) {
    final previousActionIds =
        extractExerciseLibraryActionIds(_draftBlocks).toSet();
    final nextActionIds = extractExerciseLibraryActionIds(draft.blocks).toSet();
    final removedActionIds = previousActionIds.difference(nextActionIds);
    final nextSnapshot = _LogEditorSnapshot(
      title: draft.title,
      blocks: List<BlockDTO>.from(draft.blocks),
    );
    if (nextSnapshot.signature == _currentSnapshot.signature) {
      return;
    }
    setState(() {
      _undoStack.add(_currentSnapshot);
      _currentSnapshot = nextSnapshot;
      _draftTitle = draft.title;
      _draftBlocks = List<BlockDTO>.from(nextSnapshot.blocks);
      for (final actionId in removedActionIds) {
        _actionProgressionConfigs.remove(actionId);
      }
    });
    if (removedActionIds.isNotEmpty && mounted) {
      final count = removedActionIds.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 1 ? '已移除 1 个已删除动作链接关联的递增设置' : '已移除 $count 个已删除动作链接关联的递增设置',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _undoLastChange() {
    if (_undoStack.isEmpty || _busy) {
      return;
    }
    final previous = _undoStack.removeLast();
    _setTitleControllerText(previous.title);
    setState(() {
      _currentSnapshot = previous;
      _draftTitle = previous.title;
      _editorSeedBlocks = _extractLogBodyBlocks(previous.blocks);
      _draftBlocks = List<BlockDTO>.from(previous.blocks);
      _editorRevision += 1;
    });
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          IconButton(
            tooltip: '撤销',
            onPressed: _undoStack.isEmpty || _busy ? null : _undoLastChange,
            icon: const Icon(Icons.undo_rounded),
          ),
          _busy
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  tooltip: '保存',
                  onPressed: _save,
                  icon: const Icon(Icons.check),
                ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _logOptionsSummary() {
    final mode = _taskOccurrenceId == null ? '独立日志' : '任务日志';
    final linkedActionCount =
        extractExerciseLibraryActionIds(_draftBlocks).length;
    final linkedActions =
        linkedActionCount == 0 ? '无关联动作' : '$linkedActionCount 个关联动作';
    return '$_date · $mode · $linkedActions';
  }

  // ignore: unused_element
  Future<void> _openBasicOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.56,
          minChildSize: 0.32,
          maxChildSize: 0.86,
          builder: (context, scrollController) {
            return Material(
              color: Theme.of(sheetContext).colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '基础选项',
                            style: AppTypography.bodyBold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today_outlined),
                          title: const Text('日期'),
                          subtitle:
                              Text(_date.isEmpty ? _todayDateString() : _date),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.assignment_outlined),
                          title: Text(
                            _taskOccurrenceId == null ? '独立训练日志' : '已关联训练任务',
                          ),
                          subtitle: Text(
                            _taskOccurrenceId == null
                                ? '这条日志没有关联计划任务。'
                                : '这条日志已关联计划任务。',
                          ),
                        ),
                        if (extractExerciseLibraryActionIds(_draftBlocks)
                            .isNotEmpty)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.link_rounded),
                            title: Text(
                              '${extractExerciseLibraryActionIds(_draftBlocks).length} 个关联动作',
                            ),
                            subtitle: const Text(
                              '动作递增会自动识别当前日志里的动作库链接。',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  String _compactLogSummary() {
    final mode = _taskOccurrenceId == null ? '独立' : '任务';
    final linkedActionCount =
        extractExerciseLibraryActionIds(_draftBlocks).length;
    if (linkedActionCount == 0) {
      return '$_date · $mode';
    }
    return '$_date · $mode · ${_templateActionIds.length} 个动作';
  }

  // ignore: unused_element
  String _progressionSummary(List<ActionProgressionResolvedItem> items) {
    final configured = items.where((item) => item.config.isConfigured).length;
    if (items.isEmpty) {
      return '无关联动作';
    }
    return '${items.length} 个动作 · 已配置 $configured 个';
  }

  // ignore: unused_element
  String _launcherLogSummary() {
    final mode = _taskOccurrenceId == null ? '独立' : '任务';
    if (_templateActionIds.isEmpty) {
      return '$_date / $mode';
    }
    return '$_date / $mode / ${_templateActionIds.length} 个动作';
  }

  String _launcherProgressionSummary(
    List<ActionProgressionResolvedItem> items,
  ) {
    final configured = items.where((item) => item.config.isConfigured).length;
    if (items.isEmpty) {
      return '会自动识别日志中的动作库动作';
    }
    if (configured == 0) {
      return '${items.length} 个动作 / 可选配置';
    }
    return '${items.length} 个动作 / 已配置 $configured 个';
  }

  Widget _buildTitleStrip({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        compact ? 4 : AppSpacing.xs,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? 6 : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary.withValues(
            alpha: compact ? 0.08 : 0.1,
          ),
          borderRadius:
              BorderRadius.circular(compact ? AppRadius.md : AppRadius.lg),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
          ),
        ),
        child: TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: '训练日志标题',
            border: InputBorder.none,
            isDense: true,
          ),
          style: AppTypography.bodyBold.copyWith(
            color: AppColors.textPrimary,
            fontSize: compact ? 16 : 18,
          ),
        ),
      ),
    );
  }

  Future<void> _openActionProgressionPanel(
    List<ActionProgressionResolvedItem> actionItems,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.42,
          maxChildSize: 0.96,
          builder: (context, scrollController) {
            return Material(
              color: Theme.of(sheetContext).colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '动作递增设置',
                            style: AppTypography.bodyBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        ActionProgressionPanel(
                          items: actionItems,
                          embedded: true,
                          editable: true,
                          subtitle: '从当前日志自动识别，只配置你要用的动作。',
                          emptyHint: '这里只会自动显示当前日志里关联到动作库的动作。',
                          onConfigure: _editActionProgression,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLauncherRow(
    List<ActionProgressionResolvedItem> actionItems, {
    bool compact = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      child: EditorPanelLauncher(
        icon: Icons.stacked_line_chart_rounded,
        title: '动作递增',
        summary: _launcherProgressionSummary(actionItems),
        compact: compact,
        onTap: () => _openActionProgressionPanel(actionItems),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.removeListener(_handleTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<ExerciseLibraryService>();
    final actionItems = _resolveTemplateActionItems(library);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            _buildTitleStrip(compact: keyboardVisible),
            _buildLauncherRow(
              actionItems,
              compact: keyboardVisible,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  keyboardVisible ? 4 : AppSpacing.xs,
                  0,
                  keyboardVisible ? 4 : AppSpacing.xs,
                  keyboardVisible ? AppSpacing.xs : AppSpacing.sm,
                ),
                child: InlineLogAppflowyEditor(
                  key: ValueKey<String>('editor_$_editorRevision'),
                  initialBlocks: _editorSeedBlocks,
                  showTitleField: false,
                  externalTitle: _draftTitle,
                  onChanged: _captureDraft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEditorSnapshot {
  const _LogEditorSnapshot({
    required this.title,
    required this.blocks,
  });

  final String title;
  final List<BlockDTO> blocks;

  String get signature => jsonEncode(
        <String, dynamic>{
          'title': title,
          'blocks':
              blocks.map((block) => block.toJson()).toList(growable: false),
        },
      );
}
