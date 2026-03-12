import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/services/fit/fit_scope.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/models/repeat_config.dart';
import 'package:aiwa_app/ui/widgets/task_template_payload_codec.dart';

class TemplateManagerBottomSheet extends StatefulWidget {
  const TemplateManagerBottomSheet({
    super.key,
    required this.onActivateTask,
  });

  final Future<void> Function(TaskTemplate template) onActivateTask;

  @override
  State<TemplateManagerBottomSheet> createState() =>
      _TemplateManagerBottomSheetState();
}

class _TemplateManagerBottomSheetState
    extends State<TemplateManagerBottomSheet> {
  List<TaskTemplate> _templates = <TaskTemplate>[];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    try {
      final list = await scope.hub.getTaskTemplatesUseCase.execute(
        const NoInput(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _templates = list.toList(growable: false);
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  double _getSortOrder(TaskTemplate template) {
    if (template.description == null) {
      return 0;
    }
    try {
      final map = jsonDecode(template.description!) as Map<String, dynamic>;
      return (map['sortOrder'] as num?)?.toDouble() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _setSortOrder(TaskTemplate template, double order) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    try {
      final raw = template.description;
      final map = raw != null && raw.startsWith('{')
          ? jsonDecode(raw) as Map<String, dynamic>
          : <String, dynamic>{};
      map['sortOrder'] = order;
      template.updateDescription(jsonEncode(map));
      await scope.hub.saveTaskTemplateUseCase.execute(template);
    } catch (_) {}
  }

  RepeatConfig _getRepeatConfig(TaskTemplate template) {
    try {
      if (template.description != null &&
          template.description!.startsWith('{')) {
        final map = jsonDecode(template.description!) as Map<String, dynamic>;
        final repeatJson = map['repeatConfig'];
        if (repeatJson is Map<String, dynamic>) {
          return RepeatConfig.fromJson(repeatJson);
        }
        if (repeatJson is Map) {
          return RepeatConfig.fromJson(Map<String, dynamic>.from(repeatJson));
        }
      }
    } catch (_) {}
    return RepeatConfig();
  }

  Future<void> _setRepeatConfig(TaskTemplate template, RepeatConfig cfg) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    try {
      final raw = template.description;
      final map = raw != null && raw.startsWith('{')
          ? jsonDecode(raw) as Map<String, dynamic>
          : <String, dynamic>{};
      map['repeatConfig'] = cfg.toJson();
      template.updateDescription(jsonEncode(map));
      await scope.hub.saveTaskTemplateUseCase.execute(template);
    } catch (_) {}
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

  Future<void> _showRepeatSettings(TaskTemplate template) async {
    final cfg = _getRepeatConfig(template);
    final intervalCtrl = TextEditingController(text: cfg.interval.toString());
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocalState) => AlertDialog(
          title: const Text('重复设置'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('每'),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 56,
                      child: TextField(
                        controller: intervalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(isDense: true),
                        onChanged: (value) =>
                            cfg.interval = int.tryParse(value) ?? 1,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DropdownButton<String>(
                      value: cfg.unit,
                      items: const ['Days', 'Weeks', 'Months', 'Years']
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(_repeatUnitLabel(value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setLocalState(() => cfg.unit = value);
                      },
                    ),
                  ],
                ),
                if (cfg.unit == 'Weeks')
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                      const labels = ['一', '二', '三', '四', '五', '六', '日'];
                      final isSelected = cfg.daysOfWeek.contains(day);
                      return FilterChip(
                        label: Text(labels[day - 1]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setLocalState(() {
                            if (selected) {
                              cfg.daysOfWeek.add(day);
                            } else {
                              cfg.daysOfWeek.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(growable: false),
                  ),
                if (cfg.unit == 'Months' || cfg.unit == 'Years')
                  Row(
                    children: [
                      const Text('在每月的'),
                      const SizedBox(width: AppSpacing.sm),
                      DropdownButton<String>(
                        value: cfg.ordinal,
                        items: const ['1st', '2nd', '3rd', '4th', 'Last']
                            .map(
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(_ordinalLabel(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setLocalState(() => cfg.ordinal = value);
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      DropdownButton<String>(
                        value: cfg.dayType,
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
                              (value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(_dayTypeLabel(value)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setLocalState(() => cfg.dayType = value);
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
    if (confirm == true) {
      await _setRepeatConfig(template, cfg);
    }
  }

  Future<void> _duplicateTemplate(TaskTemplate template) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    final duplicated = TaskTemplate(
      id: 'tpl_${DateTime.now().microsecondsSinceEpoch}',
      title: '${template.title}（副本）',
      description: template.description,
    );
    await scope.hub.saveTaskTemplateUseCase.execute(duplicated);
    await _loadTemplates();
  }

  Future<void> _deleteTemplate(TaskTemplate template) async {
    final deleteTaskTemplateUseCase =
        FitScope.maybeOf(context)?.hub.deleteTaskTemplateUseCase;
    if (deleteTaskTemplateUseCase == null) {
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除模板'),
        content: const Text('确定删除这个模板吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await deleteTaskTemplateUseCase.execute(template.id);
      await _loadTemplates();
    }
  }

  Future<void> _createAndEditNewTemplate(NavigatorState navigator) async {
    final scope = FitScope.maybeOf(context);
    if (scope == null) {
      return;
    }
    final defaultDescription = jsonEncode(
      buildTaskTemplatePayload(
        title: '新任务',
        body: '',
        basePayload: const <String, dynamic>{
          'version': 2,
          'taskTitle': '新任务',
        },
      ),
    );
    final template = TaskTemplate(
      id: 'tpl_${DateTime.now().microsecondsSinceEpoch}',
      title: '新任务模板',
      description: defaultDescription,
    );
    await scope.hub.saveTaskTemplateUseCase.execute(template);
    final result = await navigator.pushNamed(
      '/task_template_editor',
      arguments: <String, dynamic>{'templateId': template.id},
    );
    if (result != true) {
      await scope.hub.deleteTaskTemplateUseCase.execute(template.id);
    }
    await _loadTemplates();
  }

  void _onReorder(int oldIndex, int newIndex, List<TaskTemplate> items) async {
    if (newIndex > oldIndex) {
      newIndex--;
    }
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    setState(() => _templates = List<TaskTemplate>.from(items));
    for (var i = 0; i < items.length; i++) {
      await _setSortOrder(items[i], i.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final templates = _templates.toList()
      ..sort(
          (left, right) => _getSortOrder(left).compareTo(_getSortOrder(right)));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      minChildSize: 0.45,
      maxChildSize: 0.98,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Text(
                    '任务模板',
                    style: AppTypography.subheading
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ReorderableListView(
                scrollController: scrollController,
                onReorder: (oldIndex, newIndex) =>
                    _onReorder(oldIndex, newIndex, templates),
                children: [
                  for (var i = 0; i < templates.length; i++)
                    Card(
                      key: ValueKey<String>(templates[i].id),
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      child: ListTile(
                        leading: ReorderableDragStartListener(
                          index: i,
                          child: Icon(
                            Icons.fitness_center,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(
                          templates[i].title,
                          style: AppTypography.bodyBase
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.repeat, size: 20),
                              onPressed: () =>
                                  _showRepeatSettings(templates[i]),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                switch (value) {
                                  case 'edit':
                                    final result = await Navigator.pushNamed(
                                      context,
                                      '/task_template_editor',
                                      arguments: <String, dynamic>{
                                        'templateId': templates[i].id,
                                      },
                                    );
                                    if (result == true && context.mounted) {
                                      await _loadTemplates();
                                    }
                                    break;
                                  case 'dup':
                                    await _duplicateTemplate(templates[i]);
                                    break;
                                  case 'del':
                                    await _deleteTemplate(templates[i]);
                                    break;
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('编辑'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'dup',
                                  child: Text('复制'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'del',
                                  child: Text(
                                    '删除',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await widget.onActivateTask(templates[i]);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: FilledButton.icon(
                onPressed: () async {
                  await _createAndEditNewTemplate(Navigator.of(context));
                },
                icon: const Icon(Icons.add),
                label: const Text('新建任务模板'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
