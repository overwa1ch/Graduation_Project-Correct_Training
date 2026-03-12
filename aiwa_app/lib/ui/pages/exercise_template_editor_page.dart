import 'dart:convert';
import 'dart:math' as math;

import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/widgets/task_template_appflowy_editor.dart';

class ExerciseTemplateEditorPage extends StatefulWidget {
  const ExerciseTemplateEditorPage({super.key});

  @override
  State<ExerciseTemplateEditorPage> createState() =>
      _ExerciseTemplateEditorPageState();
}

class _ExerciseTemplateEditorPageState
    extends State<ExerciseTemplateEditorPage> {
  late final TextEditingController _titleCtrl;
  late List<BlockDTO> _noteBlocks;
  late List<PrRecord> _records;

  bool _argsLoaded = false;
  String? _existingId;

  ExerciseLibraryService get _libraryService =>
      context.read<ExerciseLibraryService>();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _noteBlocks = const <BlockDTO>[];
    _records = <PrRecord>[];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) {
      return;
    }
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map) {
      return;
    }

    final directEntry = args['entry'];
    ExerciseEntry? resolvedEntry;
    if (directEntry is ExerciseEntry) {
      resolvedEntry = directEntry;
    } else if (args['entryId'] is String) {
      resolvedEntry = _libraryService.findById(args['entryId'] as String);
      if (resolvedEntry == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未找到动作')),
          );
          Navigator.of(context).maybePop();
        });
        return;
      }
    }

    if (resolvedEntry == null) {
      return;
    }

    _existingId = resolvedEntry.id;
    _titleCtrl.text = resolvedEntry.name;
    _noteBlocks = _decodeBlocks(resolvedEntry.notes);
    _records = List<PrRecord>.from(resolvedEntry.records);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  List<BlockDTO> _decodeBlocks(String rawJson) {
    if (rawJson.trim().isEmpty) {
      return const <BlockDTO>[];
    }
    try {
      final values = jsonDecode(rawJson) as List<dynamic>;
      return values
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => BlockDTO.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const <BlockDTO>[];
    }
  }

  String _encodeBlocks(List<BlockDTO> blocks) {
    return jsonEncode(blocks.map((block) => block.toJson()).toList());
  }

  String _genId() => ExerciseLibraryService.generateId();

  Future<void> _save() async {
    final name = _titleCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('名称不能为空')),
      );
      return;
    }

    final entry = ExerciseEntry(
      id: _existingId ?? _genId(),
      name: name,
      records: List<PrRecord>.from(_records),
      notes: _encodeBlocks(_noteBlocks),
      tagIds: _existingId == null
          ? const <String>[]
          : (_libraryService.findById(_existingId!)?.tagIds ??
              const <String>[]),
    );

    await _libraryService.save(entry);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(entry);
  }

  Future<void> _addRecord() async {
    final result = await showDialog<PrRecord>(
      context: context,
      builder: (_) => const _AddRecordDialog(),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _records.add(result);
      _records.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  void _deleteRecord(int index) {
    setState(() => _records.removeAt(index));
  }

  String _fmtDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatWeight(double value) {
    final normalized = normalizeExerciseWeight(value);
    if ((normalized - normalized.roundToDouble()).abs() < 0.001) {
      return normalized.toStringAsFixed(0);
    }
    return normalized.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildNameField(),
                          const SizedBox(height: AppSpacing.xl),
                          _buildPrSection(),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            '备注',
                            style: AppTypography.bodyBold.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ),
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        0,
                        AppSpacing.lg,
                        AppSpacing.md,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: ColoredBox(
                          color: AppColors.surfaceSecondary,
                          child: TaskTemplateAppflowyEditor(
                            initialTitle: '',
                            initialBlocks: _noteBlocks,
                            onChanged: (TaskTemplateDraft draft) {
                              _noteBlocks = draft.blocks;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surfacePrimary,
        border: Border(
          bottom: BorderSide(
            color: AppColors.surfaceSecondary,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '动作编辑',
            style: AppTypography.bodyBold.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('保存'),
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              backgroundColor:
                  AppColors.brandPrimaryVariant.withValues(alpha: .18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _titleCtrl,
      style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: '动作名称',
        hintStyle: AppTypography.heading.copyWith(
          color: AppColors.textPrimary.withValues(alpha: .4),
        ),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildPrSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '个人纪录',
              style: AppTypography.bodyBold.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _addRecord,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimaryVariant.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      size: 16,
                      color: AppColors.brandPrimaryVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '添加',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.brandPrimaryVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (_records.isEmpty) _buildEmptyChart() else _buildChart(),
        const SizedBox(height: AppSpacing.sm),
        if (_records.isNotEmpty) _buildRecordsList(),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 32,
              color: AppColors.textPrimary.withValues(alpha: .3),
            ),
            const SizedBox(height: 8),
            Text(
              '还没有记录。\n点“添加”保存一条纪录。',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary.withValues(alpha: .45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.hardEdge,
      child: CustomPaint(
        painter: _LineChartPainter(records: _records),
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      children: [
        for (int i = _records.length - 1; i >= 0; i--)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                Text(
                  _fmtDate(_records[i].date),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: .65),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _formatWeight(_records[i].value),
                  style: AppTypography.bodyBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _deleteRecord(i),
                  child: Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: AppColors.textPrimary.withValues(alpha: .5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddRecordDialog extends StatefulWidget {
  const _AddRecordDialog();

  @override
  State<_AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<_AddRecordDialog> {
  DateTime _date = DateTime.now();
  final TextEditingController _valCtrl = TextEditingController();

  @override
  void dispose() {
    _valCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _confirm() {
    final value = double.tryParse(_valCtrl.text.trim());
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效数字')),
      );
      return;
    }
    Navigator.of(context).pop(
      PrRecord(
        date: _date,
        value: normalizeExerciseWeight(value),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceSecondary,
      title: Text(
        '添加记录',
        style: AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _fmtDate(_date),
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            trailing: const Icon(
              Icons.calendar_today,
              color: AppColors.textPrimary,
            ),
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _valCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: AppTypography.bodyBase.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '重量，例如 100.5',
              hintStyle: AppTypography.bodyBase.copyWith(
                color: AppColors.textPrimary.withValues(alpha: .5),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _confirm,
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({required this.records});

  final List<PrRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) {
      return;
    }

    const double padH = 24;
    const double padV = 20;

    final values =
        records.map((record) => record.value).toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final valueRange =
        (maxValue - minValue).abs() < 1e-9 ? 1.0 : maxValue - minValue;

    final timestamps = records
        .map((record) => record.date.millisecondsSinceEpoch.toDouble())
        .toList(growable: false);
    final minTimestamp = timestamps.reduce(math.min);
    final maxTimestamp = timestamps.reduce(math.max);
    final timeRange = (maxTimestamp - minTimestamp).abs() < 1e-9
        ? 1.0
        : maxTimestamp - minTimestamp;

    Offset toPos(int index) {
      final x = padH +
          (timestamps[index] - minTimestamp) /
              timeRange *
              (size.width - padH * 2);
      final y = size.height -
          padV -
          (values[index] - minValue) / valueRange * (size.height - padV * 2);
      return Offset(x, y);
    }

    final gridPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: .08)
      ..strokeWidth = 1;
    for (int j = 0; j <= 4; j++) {
      final y = padV + j * (size.height - padV * 2) / 4;
      canvas.drawLine(
        Offset(padH, y),
        Offset(size.width - padH, y),
        gridPaint,
      );
    }

    final fillPath = Path()..moveTo(toPos(0).dx, size.height - padV);
    for (int i = 0; i < records.length; i++) {
      fillPath.lineTo(toPos(i).dx, toPos(i).dy);
    }
    fillPath.lineTo(toPos(records.length - 1).dx, size.height - padV);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandPrimaryVariant.withValues(alpha: .35),
            AppColors.brandPrimaryVariant.withValues(alpha: .0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePaint = Paint()
      ..color = AppColors.brandPrimaryVariant
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    for (int i = 0; i < records.length; i++) {
      final point = toPos(i);
      if (i == 0) {
        linePath.moveTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = AppColors.brandPrimaryVariant;
    final dotBg = Paint()..color = AppColors.surfaceSecondary;
    for (int i = 0; i < records.length; i++) {
      final point = toPos(i);
      canvas.drawCircle(point, 5, dotBg);
      canvas.drawCircle(point, 3.5, dotPaint);
    }

    void drawLabel(int index, Alignment align) {
      final point = toPos(index);
      final span = TextSpan(
        text: records[index].value.toStringAsFixed(1),
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textPrimary.withValues(alpha: .8),
          fontWeight: FontWeight.w600,
        ),
      );
      final painter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = align == Alignment.centerLeft
          ? point.dx + 6
          : point.dx - painter.width - 6;
      final dy = point.dy - painter.height / 2;
      painter.paint(
        canvas,
        Offset(dx.clamp(padH, size.width - padH - painter.width), dy),
      );
    }

    if (records.length == 1) {
      drawLabel(0, Alignment.centerLeft);
    } else {
      drawLabel(0, Alignment.centerLeft);
      drawLabel(records.length - 1, Alignment.centerRight);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.records != records;
  }
}
