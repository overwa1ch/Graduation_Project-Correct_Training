import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/app_shell.dart';
import 'package:aiwa_app/ui/pages/edit_tags_page.dart';
import 'package:aiwa_app/ui/pages/exercise_template_editor_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _filterTag;

  ExerciseLibraryService get _libraryService =>
      context.read<ExerciseLibraryService>();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ExerciseEntry> _visible(List<ExerciseEntry> entries) {
    final query = _searchCtrl.text.trim().toLowerCase();
    return entries.where((entry) {
      final matchName =
          query.isEmpty || entry.name.toLowerCase().contains(query);
      final matchTag = _filterTag == null || entry.tagIds.contains(_filterTag);
      return matchName && matchTag;
    }).toList(growable: false);
  }

  List<String> _usedTags(
    List<ExerciseEntry> entries,
    List<String> allTags,
  ) {
    final used = <String>{};
    for (final entry in entries) {
      used.addAll(entry.tagIds);
    }
    return allTags.where(used.contains).toList(growable: false);
  }

  Future<void> _openCreate() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseTemplateEditorPage()),
    );
  }

  Future<void> _openEdit(ExerciseEntry entry) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseTemplateEditorPage(),
        settings: RouteSettings(arguments: {'entryId': entry.id}),
      ),
    );
  }

  Future<void> _openEditTags(ExerciseEntry entry) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const EditTagsPage(),
        settings: RouteSettings(arguments: {
          'allTags': List<String>.from(_libraryService.allTags),
          'activeTags': List<String>.from(entry.tagIds),
        }),
      ),
    );
    if (result == null) {
      return;
    }

    await _libraryService.updateEntryTags(
      entryId: entry.id,
      activeTags: (result['activeTags'] as List<dynamic>? ?? entry.tagIds)
          .whereType<String>()
          .toList(growable: false),
      allTags: (result['allTags'] as List<dynamic>? ?? _libraryService.allTags)
          .whereType<String>()
          .toList(growable: false),
    );
  }

  Future<void> _delete(ExerciseEntry entry) async {
    await _libraryService.delete(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<ExerciseLibraryService>();
    final entries = library.entries;
    final usedTags = _usedTags(entries, library.allTags);
    final items = _visible(entries);

    return AppShell(
      title: '动作库',
      currentNavIndex: 2,
      showAppBar: true,
      showBottomNav: false,
      automaticallyImplyLeading: false,
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.brandPrimaryVariant,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      child: ColoredBox(
        color: AppColors.surfacePrimary,
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              _buildSearchBar(),
              const SizedBox(height: AppSpacing.sm),
              _buildTagFilter(usedTags),
              const SizedBox(height: AppSpacing.sm),
              _buildResultsHeader(
                visibleCount: items.length,
                totalCount: entries.length,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: _buildList(
                  items: items,
                  hasAnyEntries: entries.isNotEmpty,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (_) => setState(() {}),
      style: AppTypography.bodyBase.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: '搜索动作',
        hintStyle: AppTypography.bodyBase.copyWith(
          color: AppColors.textPrimary.withValues(alpha: .45),
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.textPrimary.withValues(alpha: .55),
        ),
        filled: true,
        fillColor: AppColors.surfaceSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    );
  }

  Widget _buildTagFilter(List<String> usedTags) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _tagChip('全部', null),
          for (final tag in usedTags) _tagChip(tag, tag),
        ],
      ),
    );
  }

  Widget _tagChip(String label, String? tagValue) {
    final selected = _filterTag == tagValue;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filterTag = tagValue),
        selectedColor: AppColors.brandPrimaryVariant.withValues(alpha: .2),
        labelStyle: AppTypography.caption.copyWith(
          color: selected
              ? AppColors.brandPrimaryVariant
              : AppColors.textPrimary.withValues(alpha: .75),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        backgroundColor: AppColors.surfaceSecondary,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
    );
  }

  Widget _buildResultsHeader({
    required int visibleCount,
    required int totalCount,
  }) {
    final hasFilter = _filterTag != null || _searchCtrl.text.trim().isNotEmpty;
    return Row(
      children: [
        Text(
          hasFilter ? '$visibleCount / $totalCount 个动作' : '$totalCount 个动作',
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary.withValues(alpha: .6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (hasFilter)
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() => _filterTag = null);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandPrimaryVariant,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('清空筛选'),
          ),
      ],
    );
  }

  Widget _buildList({
    required List<ExerciseEntry> items,
    required bool hasAnyEntries,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 44,
              color: AppColors.textPrimary.withValues(alpha: .2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasAnyEntries ? '没有符合条件的动作。' : '点右下角新增第一个动作。',
              style: AppTypography.bodyBase.copyWith(
                color: AppColors.textPrimary.withValues(alpha: .45),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => _ExerciseListTile(
        entry: items[index],
        onTap: () => _openEdit(items[index]),
        onEditTags: () => _openEditTags(items[index]),
        onDelete: () => _delete(items[index]),
      ),
    );
  }
}

class _ExerciseListTile extends StatefulWidget {
  const _ExerciseListTile({
    required this.entry,
    required this.onTap,
    required this.onEditTags,
    required this.onDelete,
  });

  final ExerciseEntry entry;
  final VoidCallback onTap;
  final VoidCallback onEditTags;
  final VoidCallback onDelete;

  @override
  State<_ExerciseListTile> createState() => _ExerciseListTileState();
}

class _ExerciseListTileState extends State<_ExerciseListTile>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 140;
  static const double _buttonWidth = 70;

  late final AnimationController _animCtrl;
  late final Animation<double> _slideAnim;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<double>(begin: 0, end: -_actionWidth).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _open() {
    if (_revealed) {
      return;
    }
    _animCtrl.forward();
    setState(() => _revealed = true);
  }

  void _close() {
    if (!_revealed) {
      return;
    }
    _animCtrl.reverse();
    setState(() => _revealed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.delta.dx < -4) {
          _open();
        }
        if (details.delta.dx > 4) {
          _close();
        }
      },
      onTap: _revealed ? _close : null,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: _buttonWidth,
                  child: Material(
                    color: AppColors.brandPrimaryVariant,
                    child: InkWell(
                      onTap: () {
                        _close();
                        Future.delayed(
                          const Duration(milliseconds: 160),
                          widget.onEditTags,
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.label_outline,
                              color: Colors.white, size: 20),
                          SizedBox(height: 4),
                          Text(
                            '标签',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: _buttonWidth,
                  child: Material(
                    color: const Color(0xFFE53935),
                    child: InkWell(
                      onTap: () {
                        _close();
                        Future.delayed(
                          const Duration(milliseconds: 160),
                          widget.onDelete,
                        );
                      },
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.white, size: 20),
                          SizedBox(height: 4),
                          Text(
                            '删除',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(_slideAnim.value, 0),
              child: child,
            ),
            child: Material(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: _revealed ? _close : widget.onTap,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        color: AppColors.brandPrimaryVariant,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.entry.name,
                                      style: AppTypography.bodyBold.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (widget.entry.tagIds.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 5,
                                        runSpacing: 4,
                                        children: widget.entry.tagIds
                                            .map((tag) =>
                                                _MiniTagChip(label: tag))
                                            .toList(growable: false),
                                      ),
                                    ],
                                    if (widget.entry.records.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _PrBadge(
                                        value: widget.entry.records
                                            .map((record) => record.value)
                                            .reduce((a, b) => a > b ? a : b),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              if (widget.entry.records.length >= 2)
                                SizedBox(
                                  width: 56,
                                  height: 36,
                                  child: CustomPaint(
                                    painter: _SparklinePainter(
                                      records: widget.entry.records,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.fitness_center,
                                  size: 22,
                                  color: AppColors.textPrimary
                                      .withValues(alpha: .2),
                                ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color:
                                    AppColors.textPrimary.withValues(alpha: .3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTagChip extends StatelessWidget {
  const _MiniTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandPrimaryVariant.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.brandPrimaryVariant.withValues(alpha: .35),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontSize: 11,
          color: AppColors.brandPrimaryVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PrBadge extends StatelessWidget {
  const _PrBadge({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.emoji_events_rounded,
          size: 13,
          color: AppColors.brandPrimaryVariant.withValues(alpha: .8),
        ),
        const SizedBox(width: 3),
        Text(
          'PR ${value.toStringAsFixed(1)}',
          style: AppTypography.caption.copyWith(
            fontSize: 12,
            color: AppColors.brandPrimaryVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.records});

  final List<PrRecord> records;

  @override
  void paint(Canvas canvas, Size size) {
    if (records.length < 2) {
      return;
    }

    final values =
        records.map((record) => record.value).toList(growable: false);
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range =
        (maxValue - minValue).abs() < 1e-9 ? 1.0 : maxValue - minValue;

    Offset pointAt(int index) {
      final x = index / (records.length - 1) * size.width;
      final y = size.height - (values[index] - minValue) / range * size.height;
      return Offset(x, y);
    }

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i < records.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.brandPrimaryVariant
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) => false;
}
