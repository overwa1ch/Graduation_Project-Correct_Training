import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/services/fit/fit_scope.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/models/repeat_config.dart';
import 'package:aiwa_app/ui/widgets/action_progression_panel.dart';
import 'package:aiwa_app/ui/widgets/editor_panel_launcher.dart';
import 'package:aiwa_app/ui/widgets/task_template_appflowy_editor.dart';
import 'package:aiwa_app/ui/widgets/task_template_payload_codec.dart';

class TaskTemplateEditorPage extends StatefulWidget {
  const TaskTemplateEditorPage({super.key});

  @override
  State<TaskTemplateEditorPage> createState() => _TaskTemplateEditorPageState();
}

class _TaskTemplateEditorPageState extends State<TaskTemplateEditorPage> {
  final TextEditingController _titleController = TextEditingController();

  String? _templateId;
  TaskTemplate? _template;
  bool _loading = false;

  String _draftTitle = '';
  List<BlockDTO> _editorSeedBlocks = const <BlockDTO>[];
  List<BlockDTO> _taskBlocks = const <BlockDTO>[];
  RepeatConfig _repeatConfig = RepeatConfig();
  final Map<String, TaskTemplateActionProgressionConfig>
      _actionProgressionConfigs =
      <String, TaskTemplateActionProgressionConfig>{};
  int _editorRevision = 0;
  bool _ignoreTitleChanges = false;
  _TaskTemplateEditorSnapshot _currentSnapshot =
      const _TaskTemplateEditorSnapshot(
    title: '',
    blocks: <BlockDTO>[],
  );
  final List<_TaskTemplateEditorSnapshot> _undoStack =
      <_TaskTemplateEditorSnapshot>[];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_handleTitleChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_templateId != null) {
      return;
    }
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['templateId'] is String) {
      _templateId = args['templateId'] as String;
      _loadTemplate();
    }
  }

  Future<void> _loadTemplate() async {
    final scope = FitScope.maybeOf(context);
    if (scope == null || _templateId == null) {
      return;
    }
    setState(() => _loading = true);
    try {
      final template = await scope.hub.getTaskTemplateByIdUseCase.execute(
        _templateId!,
      );
      if (template == null || !mounted) {
        return;
      }
      final blocks = <BlockDTO>[];
      var repeatConfig = RepeatConfig();
      final actionConfigs = <String, TaskTemplateActionProgressionConfig>{};
      try {
        final payload =
            jsonDecode(template.description ?? '{}') as Map<String, dynamic>;
        final snapshot = normalizeTaskTemplatePayload(
          payload,
          title: template.title,
        );
        blocks.addAll(extractTaskTemplateEditorBlocks(snapshot.blocks));
        final repeatJson = payload['repeatConfig'];
        if (repeatJson is Map<String, dynamic>) {
          repeatConfig = RepeatConfig.fromJson(repeatJson);
        } else if (repeatJson is Map) {
          repeatConfig =
              RepeatConfig.fromJson(Map<String, dynamic>.from(repeatJson));
        }
        for (final config in parseTaskTemplateActionProgressions(payload)) {
          actionConfigs[config.exerciseId] = config;
        }
      } catch (_) {}
      setState(() {
        _template = template;
        _draftTitle = template.title;
        _editorSeedBlocks = List<BlockDTO>.from(blocks);
        _taskBlocks = blocks;
        _repeatConfig = repeatConfig;
        _actionProgressionConfigs
          ..clear()
          ..addAll(actionConfigs);
        _editorRevision += 1;
        _resetHistory(title: _draftTitle, blocks: _taskBlocks);
      });
      _setTitleControllerText(template.title);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _saveTemplate() async {
    final scope = FitScope.maybeOf(context);
    final template = _template;
    if (scope == null || template == null) {
      return false;
    }

    final title = _draftTitle.trim().isEmpty ? '未命名任务模板' : _draftTitle.trim();

    Map<String, dynamic> payload = <String, dynamic>{};
    if (template.description != null &&
        template.description!.trim().isNotEmpty) {
      try {
        payload = jsonDecode(template.description!) as Map<String, dynamic>;
      } catch (_) {}
    }

    payload.addAll(
      buildTaskTemplatePayloadFromBlocks(
        title: title,
        bodyBlocks: _taskBlocks,
        basePayload: payload,
      ),
    );
    payload['version'] = 2;
    payload['taskTitle'] = title;
    payload['repeatConfig'] = _repeatConfig.toJson();
    final linkedActionIds = extractExerciseLibraryActionIds(_taskBlocks);
    payload['actionProgressions'] = linkedActionIds
        .map((exerciseId) {
          final library = context.read<ExerciseLibraryService>();
          final entry = library.findById(exerciseId);
          final fallback = entry == null
              ? TaskTemplateActionProgressionConfig(
                  exerciseId: exerciseId,
                  targetWeightKg: 0,
                  openingPercent:
                      TaskTemplateActionProgressionConfig.defaultOpeningPercent,
                  endingPercent:
                      TaskTemplateActionProgressionConfig.defaultEndingPercent,
                  incrementWeightKg: TaskTemplateActionProgressionConfig
                      .defaultIncrementWeightKg,
                )
              : TaskTemplateActionProgressionConfig.defaultsFor(entry);
          final config = _actionProgressionConfigs[exerciseId] ?? fallback;
          return config.copyWith(exerciseId: exerciseId);
        })
        .where((config) => config.isConfigured)
        .map((config) => config.toJson())
        .toList(growable: false);

    template.updateTitle(title);
    template.updateDescription(jsonEncode(payload));

    try {
      setState(() => _loading = true);
      await scope.hub.saveTaskTemplateUseCase.execute(template);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _dateString(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _handleTitleChanged() {
    if (_ignoreTitleChanges) {
      return;
    }
    final value = _titleController.text;
    if (value == _draftTitle) {
      return;
    }
    final nextSnapshot = _TaskTemplateEditorSnapshot(
      title: value,
      blocks: List<BlockDTO>.from(_taskBlocks),
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

  void _resetHistory({
    required String title,
    required List<BlockDTO> blocks,
  }) {
    _currentSnapshot = _TaskTemplateEditorSnapshot(
      title: title,
      blocks: List<BlockDTO>.from(blocks),
    );
    _undoStack.clear();
  }

  void _captureBodyDraft(List<BlockDTO> blocks) {
    final previousActionIds =
        extractExerciseLibraryActionIds(_taskBlocks).toSet();
    final nextActionIds = extractExerciseLibraryActionIds(blocks).toSet();
    final removedActionIds = previousActionIds.difference(nextActionIds);
    final nextSnapshot = _TaskTemplateEditorSnapshot(
      title: _draftTitle,
      blocks: List<BlockDTO>.from(blocks),
    );
    if (nextSnapshot.signature == _currentSnapshot.signature) {
      return;
    }
    setState(() {
      _undoStack.add(_currentSnapshot);
      _currentSnapshot = nextSnapshot;
      _taskBlocks = List<BlockDTO>.from(blocks);
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
    if (_undoStack.isEmpty || _loading) {
      return;
    }
    final previous = _undoStack.removeLast();
    _setTitleControllerText(previous.title);
    setState(() {
      _currentSnapshot = previous;
      _draftTitle = previous.title;
      _editorSeedBlocks = List<BlockDTO>.from(previous.blocks);
      _taskBlocks = List<BlockDTO>.from(previous.blocks);
      _editorRevision += 1;
    });
  }

  Future<void> _pickRepeatStartDate(VoidCallback refreshSheet) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      initialDate: _repeatConfig.startDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _repeatConfig.startDate = DateTime(picked.year, picked.month, picked.day);
      if (!_repeatConfig.neverEnds &&
          _repeatConfig.endDate != null &&
          _repeatConfig.endDate!.isBefore(_repeatConfig.startDate)) {
        _repeatConfig.endDate = _repeatConfig.startDate;
      }
    });
    refreshSheet();
  }

  Future<void> _pickRepeatEndDate(VoidCallback refreshSheet) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: _repeatConfig.startDate,
      lastDate: DateTime(2100, 12, 31),
      initialDate: _repeatConfig.endDate ?? _repeatConfig.startDate,
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _repeatConfig.endDate = DateTime(picked.year, picked.month, picked.day);
      _repeatConfig.neverEnds = false;
    });
    refreshSheet();
  }

  Widget _buildRepeatConfigSection({
    required VoidCallback refreshSheet,
    required TextEditingController intervalController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('重复规则', style: AppTypography.subheading),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Text('每'),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 56,
              child: TextFormField(
                controller: intervalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _repeatConfig.interval = int.tryParse(value) ?? 1;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _repeatConfig.unit,
                items: const ['Days', 'Weeks', 'Months', 'Years']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_repeatUnitLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _repeatConfig.unit = value);
                  refreshSheet();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('开始：${_dateString(_repeatConfig.startDate)}'),
          trailing: const Icon(Icons.event_available),
          onTap: () => _pickRepeatStartDate(refreshSheet),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('结束：永不'),
          value: _repeatConfig.neverEnds,
          onChanged: (value) {
            setState(() {
              _repeatConfig.neverEnds = value;
              if (value) {
                _repeatConfig.endDate = null;
              } else {
                _repeatConfig.endDate ??= _repeatConfig.startDate;
              }
            });
            refreshSheet();
          },
        ),
        if (!_repeatConfig.neverEnds)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '结束：${_dateString(_repeatConfig.endDate ?? _repeatConfig.startDate)}',
            ),
            trailing: const Icon(Icons.event_busy),
            onTap: () => _pickRepeatEndDate(refreshSheet),
          ),
        if (_repeatConfig.unit == 'Weeks')
          Wrap(
            spacing: AppSpacing.xs,
            children: [1, 2, 3, 4, 5, 6, 7].map((day) {
              const labels = ['一', '二', '三', '四', '五', '六', '日'];
              final isSelected = _repeatConfig.daysOfWeek.contains(day);
              return FilterChip(
                label: Text(labels[day - 1]),
                selected: isSelected,
                onSelected: (selected) => setState(() {
                  if (selected) {
                    _repeatConfig.daysOfWeek.add(day);
                  } else {
                    _repeatConfig.daysOfWeek.remove(day);
                  }
                  refreshSheet();
                }),
              );
            }).toList(),
          ),
        if (_repeatConfig.unit == 'Months' || _repeatConfig.unit == 'Years')
          Row(
            children: [
              const Text('在每月的'),
              const SizedBox(width: AppSpacing.sm),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _repeatConfig.ordinal,
                  items: const ['1st', '2nd', '3rd', '4th', 'Last']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_ordinalLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _repeatConfig.ordinal = value);
                    refreshSheet();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _repeatConfig.dayType,
                  items: const [
                    'Day',
                    'Weekday',
                    'Weekend day',
                    'Mo',
                    'Tu',
                    'We',
                    'Th',
                    'Fr',
                    'Sa',
                    'Su',
                  ]
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(_dayTypeLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _repeatConfig.dayType = value);
                    refreshSheet();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<void> _openBasicOptions() async {
    final intervalController = TextEditingController(
      text: _repeatConfig.interval.toString(),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void refreshSheet() => setSheetState(() {});

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.84,
              minChildSize: 0.44,
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
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          children: [
                            const SizedBox(height: AppSpacing.md),
                            _buildRepeatConfigSection(
                              refreshSheet: refreshSheet,
                              intervalController: intervalController,
                            ),
                            const SizedBox(height: AppSpacing.xl),
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
      },
    );
    intervalController.dispose();
  }

  List<ActionProgressionResolvedItem> _resolveActionProgressionItems(
    ExerciseLibraryService library,
  ) {
    final labelsById = extractExerciseLibraryActionLabels(_taskBlocks);
    return resolveActionProgressionItems(
      actionIds: labelsById.keys,
      labelsById: labelsById,
      configsById: _actionProgressionConfigs,
      library: library,
    );
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

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _loading
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    Navigator.pop(context);
                  },
          ),
          const Spacer(),
          IconButton(
            tooltip: '撤销',
            onPressed: _undoStack.isEmpty || _loading ? null : _undoLastChange,
            icon: const Icon(Icons.undo_rounded),
          ),
          _loading
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
                  onPressed: () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (await _saveTemplate() && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  icon: const Icon(Icons.check),
                ),
        ],
      ),
    );
  }

  // ignore: unused_element
  String _repeatSummaryText() {
    final interval = _repeatConfig.interval <= 0 ? 1 : _repeatConfig.interval;
    final ending = _repeatConfig.neverEnds
        ? '永不结束'
        : '结束于 ${_dateString(_repeatConfig.endDate ?? _repeatConfig.startDate)}';
    return '每 $interval ${_repeatUnitLabel(_repeatConfig.unit)} · 开始于 ${_dateString(_repeatConfig.startDate)} · $ending';
  }

  String _compactRepeatSummary() {
    final interval = _repeatConfig.interval <= 0 ? 1 : _repeatConfig.interval;
    final ending = _repeatConfig.neverEnds ? '永不结束' : '有结束日期';
    return '每 $interval ${_repeatUnitLabel(_repeatConfig.unit)} / $ending';
  }

  String _repeatUnitLabel(String value) {
    switch (value) {
      case 'Days':
        return '天';
      case 'Weeks':
        return '周';
      case 'Months':
        return '月';
      case 'Years':
        return '年';
      default:
        return value;
    }
  }

  String _ordinalLabel(String value) {
    switch (value) {
      case '1st':
        return '第 1';
      case '2nd':
        return '第 2';
      case '3rd':
        return '第 3';
      case '4th':
        return '第 4';
      case 'Last':
        return '最后';
      default:
        return value;
    }
  }

  String _dayTypeLabel(String value) {
    switch (value) {
      case 'Day':
        return '天';
      case 'Weekday':
        return '工作日';
      case 'Weekend day':
        return '周末';
      case 'Mo':
        return '周一';
      case 'Tu':
        return '周二';
      case 'We':
        return '周三';
      case 'Th':
        return '周四';
      case 'Fr':
        return '周五';
      case 'Sa':
        return '周六';
      case 'Su':
        return '周日';
      default:
        return value;
    }
  }

  String _progressionSummary(List<ActionProgressionResolvedItem> items) {
    final configured = items.where((item) => item.config.isConfigured).length;
    if (items.isEmpty) {
      return '还没有关联动作';
    }
    if (configured == 0) {
      return '${items.length} 个动作 / 点按配置';
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
            hintText: '任务模板名称',
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
                            '配置动作递增',
                            style: AppTypography.bodyBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (actionItems.any(
                          (item) => item.config.buildProgression().isNotEmpty,
                        ))
                          IconButton(
                            tooltip: '复制全部递增',
                            onPressed: () {
                              copyAllActionProgressionsToClipboard(
                                context: context,
                                items: actionItems,
                              );
                            },
                            icon: const Icon(Icons.copy_all_rounded),
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
                          onConfigure: _editActionProgression,
                          onCopy: (item) {
                            copyActionProgressionToClipboard(
                              context: context,
                              item: item,
                            );
                          },
                          onCopyAll: () {
                            return copyAllActionProgressionsToClipboard(
                              context: context,
                              items: actionItems,
                            );
                          },
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
      child: Row(
        children: [
          Expanded(
            child: EditorPanelLauncher(
              icon: Icons.tune_rounded,
              title: '基础选项',
              summary: _compactRepeatSummary(),
              compact: compact,
              onTap: _openBasicOptions,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: EditorPanelLauncher(
              icon: Icons.stacked_line_chart_rounded,
              title: '配置递增',
              summary: _progressionSummary(actionItems),
              compact: compact,
              onTap: () => _openActionProgressionPanel(actionItems),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    _titleController.removeListener(_handleTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<ExerciseLibraryService>();
    final actionItems = _resolveActionProgressionItems(library);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            if (_template == null)
              Expanded(
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator(strokeWidth: 2.4)
                      : const SizedBox.shrink(),
                ),
              )
            else ...[
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
                  child: TaskTemplateAppflowyEditor(
                    key: ValueKey<String>('task_editor_$_editorRevision'),
                    initialTitle: _draftTitle,
                    initialBlocks: _editorSeedBlocks,
                    onChanged: (draft) => _captureBodyDraft(draft.blocks),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskTemplateEditorSnapshot {
  const _TaskTemplateEditorSnapshot({
    required this.title,
    required this.blocks,
  });

  final String title;
  final List<BlockDTO> blocks;

  String get signature => jsonEncode(<String, dynamic>{
        'title': title,
        'blocks': blocks.map((block) => block.toJson()).toList(growable: false),
      });
}
