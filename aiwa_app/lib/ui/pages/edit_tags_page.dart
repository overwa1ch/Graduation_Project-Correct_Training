import 'package:flutter/material.dart';

import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';

// ---------------------------------------------------------------------------
//  EditTagsPage
// ---------------------------------------------------------------------------
/// Route args (Map<String, dynamic>):
///   • 'allTags'     List<String>  – the full My Tags pool
///   • 'activeTags'  List<String>  – tags currently assigned to this entry
///
/// Pops with Map<String, dynamic>?:
///   • 'allTags'    List<String>  – (possibly updated) pool
///   • 'activeTags' List<String>  – updated assignment
class EditTagsPage extends StatefulWidget {
  const EditTagsPage({super.key});

  @override
  State<EditTagsPage> createState() => _EditTagsPageState();
}

class _EditTagsPageState extends State<EditTagsPage> {
  final TextEditingController _inputCtrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  List<String> _allTags = [];
  List<String> _activeTags = [];
  List<String> _filtered = [];

  bool _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsLoaded) return;
    _argsLoaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final all = args['allTags'];
      final active = args['activeTags'];
      if (all is List) _allTags = List<String>.from(all);
      if (active is List) _activeTags = List<String>.from(active);
    }
    _filtered = List<String>.from(_allTags);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ── logic ─────────────────────────────────────────────────────────────────
  void _onInputChanged(String text) {
    final q = text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List<String>.from(_allTags)
          : _allTags.where((t) => t.toLowerCase().contains(q)).toList();
    });
  }

  void _confirmInput() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final exactMatch = _allTags.firstWhere(
      (t) => t.toLowerCase() == text.toLowerCase(),
      orElse: () => '',
    );

    if (exactMatch.isNotEmpty) {
      _toggleTag(exactMatch);
    } else {
      setState(() {
        _allTags.add(text);
        _activeTags.add(text);
        _filtered = List<String>.from(_allTags);
      });
    }
    _inputCtrl.clear();
    _onInputChanged('');
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_activeTags.contains(tag)) {
        _activeTags.remove(tag);
      } else {
        _activeTags.add(tag);
      }
    });
  }

  void _removeActiveTag(String tag) {
    setState(() => _activeTags.remove(tag));
  }

  void _done() {
    Navigator.of(context).pop(<String, dynamic>{
      'allTags': _allTags,
      'activeTags': _activeTags,
    });
  }

  // ── rename / delete pool tag ──────────────────────────────────────────────
  Future<void> _showTagOptions(String tag) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withOpacity(.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
              title: Text('重命名 "$tag"',
                  style: AppTypography.bodyBase
                      .copyWith(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.of(ctx).pop();
                _renameTag(tag);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('删除 "$tag"',
                  style:
                      AppTypography.bodyBase.copyWith(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteTag(tag);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _renameTag(String oldName) async {
    final ctrl = TextEditingController(text: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceSecondary,
        title: Text('重命名标签',
            style:
                AppTypography.bodyBold.copyWith(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTypography.bodyBase.copyWith(color: AppColors.textPrimary),
          cursorColor: AppColors.brandPrimaryVariant,
          decoration: InputDecoration(
            hintText: '新名称',
            hintStyle: AppTypography.bodyBase
                .copyWith(color: AppColors.textPrimary.withOpacity(.4)),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('取消')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('确认')),
        ],
      ),
    );
    ctrl.dispose();
    if (newName == null || newName.isEmpty || newName == oldName) return;
    if (_allTags.contains(newName)) return; // duplicate
    setState(() {
      final idx = _allTags.indexOf(oldName);
      if (idx != -1) _allTags[idx] = newName;
      final activeIdx = _activeTags.indexOf(oldName);
      if (activeIdx != -1) _activeTags[activeIdx] = newName;
      _filtered = List<String>.from(_allTags);
    });
  }

  void _deleteTag(String tag) {
    setState(() {
      _allTags.remove(tag);
      _activeTags.remove(tag);
      _filtered = List<String>.from(_allTags);
    });
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNavBar(),
            const Divider(height: 1, color: Color(0xFF333333)),
            _buildInputArea(),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                '标签',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary.withOpacity(.45),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildTagsPool(),
            ),
          ],
        ),
      ),
    );
  }

  // ── nav bar ───────────────────────────────────────────────────────────────
  Widget _buildNavBar() {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary.withOpacity(.75),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: const Text('取消'),
            ),
            const Spacer(),
            Text(
              '标签',
              style:
                  AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
            ),
            const Spacer(),
            TextButton(
              onPressed: _done,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandPrimaryVariant,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }

  // ── input area ────────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      color: AppColors.surfaceSecondary,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // active tag chips row
          if (_activeTags.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tag in _activeTags)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: _ActiveTagChip(
                        tag: tag,
                        onRemove: () => _removeActiveTag(tag),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          // text input
          Row(
            children: [
              const Icon(Icons.search, size: 18, color: Color(0xFF888888)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  focusNode: _inputFocus,
                  autofocus: true,
                  style: AppTypography.bodyBase
                      .copyWith(color: AppColors.textPrimary),
                  cursorColor: AppColors.brandPrimaryVariant,
                  decoration: InputDecoration(
                    hintText: '搜索或添加标签',
                    hintStyle: AppTypography.bodyBase.copyWith(
                        color: AppColors.textPrimary.withOpacity(.35)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                  onChanged: _onInputChanged,
                  onSubmitted: (_) => _confirmInput(),
                  textInputAction: TextInputAction.done,
                ),
              ),
              // confirm button — shows only when text is non-empty
              if (_inputCtrl.text.trim().isNotEmpty)
                GestureDetector(
                  onTap: _confirmInput,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimaryVariant.withOpacity(.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _allTags.any((t) =>
                              t.toLowerCase() ==
                              _inputCtrl.text.trim().toLowerCase())
                          ? '选中'
                          : '+ 添加',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.brandPrimaryVariant,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── tags pool ─────────────────────────────────────────────────────────────
  Widget _buildTagsPool() {
    final displayList = _inputCtrl.text.trim().isEmpty ? _allTags : _filtered;

    if (displayList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Center(
          child: Text(
            _inputCtrl.text.trim().isEmpty ? '还没有标签，输入后添加' : '没有匹配标签，按回车新建',
            style: AppTypography.caption
                .copyWith(color: AppColors.textPrimary.withOpacity(.4)),
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final tag in displayList)
          _PoolTagChip(
            tag: tag,
            active: _activeTags.contains(tag),
            onTap: () => _toggleTag(tag),
            onLongPress: () => _showTagOptions(tag),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  Sub-widgets
// ---------------------------------------------------------------------------

/// Green chip inside the input area – represents an active tag.
class _ActiveTagChip extends StatelessWidget {
  const _ActiveTagChip({required this.tag, required this.onRemove});

  final String tag;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.brandPrimaryVariant.withOpacity(.18),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
              color: AppColors.brandPrimaryVariant.withOpacity(.6), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: AppTypography.caption.copyWith(
                  color: AppColors.brandPrimaryVariant,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            Icon(Icons.close_rounded,
                size: 13, color: AppColors.brandPrimaryVariant.withOpacity(.8)),
          ],
        ),
      ),
    );
  }
}

/// Chip in the My Tags pool that toggles active state.
class _PoolTagChip extends StatelessWidget {
  const _PoolTagChip({
    required this.tag,
    required this.active,
    required this.onTap,
    this.onLongPress,
  });

  final String tag;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.brandPrimaryVariant.withOpacity(.18)
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: active
                ? AppColors.brandPrimaryVariant.withOpacity(.7)
                : AppColors.surfaceSecondary,
            width: 1.2,
          ),
        ),
        child: Text(
          tag,
          style: AppTypography.bodyBase.copyWith(
            color: active
                ? AppColors.brandPrimaryVariant
                : AppColors.textPrimary.withOpacity(.8),
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
