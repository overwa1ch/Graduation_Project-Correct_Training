import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as fq;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';

import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/spacing.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/ui/widgets/aiwa_image_preview.dart';
import 'package:aiwa_app/ui/widgets/aiwa_inline_rich_text_codec.dart';

class AiwaBlockEditorDraft {
  const AiwaBlockEditorDraft({
    required this.title,
    required this.blocks,
  });

  final String title;
  final List<BlockDTO> blocks;
}

class AiwaBlockEditor extends StatefulWidget {
  const AiwaBlockEditor({
    super.key,
    required this.initialTitle,
    required this.initialBlocks,
    this.onChanged,
    this.onOpenHeader,
    this.showTitleField = true,
    this.externalTitle,
    this.titleHint = 'Title',
    this.headerTitle = 'Basic options',
    this.headerSubtitle,
  });

  final String initialTitle;
  final List<BlockDTO> initialBlocks;
  final ValueChanged<AiwaBlockEditorDraft>? onChanged;
  final VoidCallback? onOpenHeader;
  final bool showTitleField;
  final String? externalTitle;
  final String titleHint;
  final String headerTitle;
  final String? headerSubtitle;

  @override
  State<AiwaBlockEditor> createState() => _AiwaBlockEditorState();
}

class _AiwaBlockEditorState extends State<AiwaBlockEditor>
    with WidgetsBindingObserver {
  late final TextEditingController _titleController;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _rootFocusNode = FocusNode(debugLabel: 'AiwaBlockEditorRoot');
  final Map<String, GlobalKey> _blockAnchorKeys = <String, GlobalKey>{};

  late List<BlockDTO> _blocks;
  String? _selectedBlockId;
  String? _highlightedBlockId;
  int _highlightPulseToken = 0;
  fq.QuillController? _activeRichTextController;
  FocusNode? _activeRichTextFocusNode;
  String? _activeRichTextBlockId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _titleController = TextEditingController(text: widget.initialTitle);
    _blocks = _normalizeBlocks(widget.initialBlocks);
    _syncBlockAnchorKeys();
    _titleController.addListener(_emitDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emitDraft());
  }

  @override
  void didUpdateWidget(covariant AiwaBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTitle != widget.initialTitle &&
        _titleController.text != widget.initialTitle) {
      _titleController.text = widget.initialTitle;
    }
    if (!_sameBlockList(oldWidget.initialBlocks, widget.initialBlocks)) {
      _blocks = _normalizeBlocks(widget.initialBlocks);
      _syncBlockAnchorKeys();
      _selectedBlockId = null;
      _highlightedBlockId = null;
      _activeRichTextController = null;
      _activeRichTextFocusNode = null;
      _activeRichTextBlockId = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _titleController.dispose();
    _scrollController.dispose();
    _rootFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) {
      return;
    }
    // Keyboard visibility changes do not reliably rebuild this body because
    // Scaffold strips bottom viewInsets from the nested MediaQuery.
    setState(() {});
  }

  List<BlockDTO> _normalizeBlocks(List<BlockDTO> input) {
    return input.map(_normalizeBlock).toList(growable: true);
  }

  BlockDTO _normalizeBlock(BlockDTO block) {
    if (block is TextBlockDTO) {
      return TextBlockDTO(
        id: block.id,
        text: normalizeAiwaRichTextStorage(block.text),
      );
    }
    if (block is HeadingBlockDTO) {
      return HeadingBlockDTO(
        id: block.id,
        text: normalizeAiwaRichTextStorage(block.text),
        level: block.level.clamp(1, 3),
      );
    }
    if (block is ChecklistBlockDTO) {
      return ChecklistBlockDTO(
        id: block.id,
        items: block.items.isEmpty
            ? const <ChecklistItemDTO>[
                ChecklistItemDTO(text: '', checked: false),
              ]
            : block.items,
      );
    }
    if (block is ImageBlockDTO) {
      return ImageBlockDTO(
        id: block.id,
        attachments: block.attachments.isEmpty
            ? <AttachmentDTO>[_newImageAttachment('')]
            : block.attachments,
        caption: block.caption,
      );
    }
    if (block is TableBlockDTO) {
      return _normalizeTableBlock(block);
    }
    return block;
  }

  GlobalKey _blockAnchorKey(String blockId) {
    return _blockAnchorKeys.putIfAbsent(
      blockId,
      () => GlobalKey(debugLabel: 'AiwaBlockAnchor_$blockId'),
    );
  }

  void _syncBlockAnchorKeys() {
    final activeIds = _blocks.map((block) => block.id).toSet();
    _blockAnchorKeys.removeWhere((blockId, _) => !activeIds.contains(blockId));
    for (final block in _blocks) {
      _blockAnchorKey(block.id);
    }
  }

  TableBlockDTO _normalizeTableBlock(TableBlockDTO block) {
    final columnCount = math.max(1, block.columnCount);
    final rows = block.rows.isEmpty
        ? <List<String>>[
            List<String>.filled(columnCount, '', growable: false),
          ]
        : block.rows
            .map(
              (row) => List<String>.generate(
                columnCount,
                (index) => index < row.length ? row[index] : '',
                growable: false,
              ),
            )
            .toList(growable: false);
    return TableBlockDTO(id: block.id, columnCount: columnCount, rows: rows);
  }

  void _emitDraft() {
    widget.onChanged?.call(
      AiwaBlockEditorDraft(
        title: widget.showTitleField
            ? _titleController.text.trim()
            : (widget.externalTitle ?? '').trim(),
        blocks: List<BlockDTO>.unmodifiable(_blocks),
      ),
    );
  }

  void _clearActiveRichText() {
    if (!mounted) {
      return;
    }
    if (_activeRichTextController == null &&
        _activeRichTextFocusNode == null &&
        _activeRichTextBlockId == null) {
      return;
    }
    setState(() {
      _activeRichTextController = null;
      _activeRichTextFocusNode = null;
      _activeRichTextBlockId = null;
    });
  }

  bool _sameBlockList(List<BlockDTO> a, List<BlockDTO> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].toJson().toString() != b[i].toJson().toString()) {
        return false;
      }
    }
    return true;
  }

  int _indexOfBlock(String blockId) {
    return _blocks.indexWhere((block) => block.id == blockId);
  }

  BlockDTO? get _selectedBlock {
    final id = _selectedBlockId;
    if (id == null) {
      return null;
    }
    final index = _indexOfBlock(id);
    if (index == -1) {
      return null;
    }
    return _blocks[index];
  }

  void _selectBlock(String blockId, {bool requestKeyboardFocus = false}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedBlockId = blockId;
      if (_activeRichTextBlockId != blockId) {
        _activeRichTextController = null;
        _activeRichTextFocusNode = null;
        _activeRichTextBlockId = null;
      }
    });
    if (requestKeyboardFocus) {
      _rootFocusNode.requestFocus();
    }
  }

  void _activateRichTextBlock(
    String blockId,
    fq.QuillController controller,
    FocusNode focusNode,
  ) {
    if (!mounted) {
      return;
    }
    if (_selectedBlockId == blockId &&
        identical(_activeRichTextController, controller) &&
        identical(_activeRichTextFocusNode, focusNode) &&
        _activeRichTextBlockId == blockId) {
      return;
    }
    setState(() {
      _selectedBlockId = blockId;
      _activeRichTextController = controller;
      _activeRichTextFocusNode = focusNode;
      _activeRichTextBlockId = blockId;
    });
  }

  void _replaceBlock(BlockDTO block) {
    final index = _indexOfBlock(block.id);
    if (index == -1) {
      return;
    }
    setState(() {
      _blocks[index] = _normalizeBlock(block);
      _selectedBlockId = block.id;
    });
    _emitDraft();
  }

  void _deleteBlock(String blockId) {
    final index = _indexOfBlock(blockId);
    if (index == -1) {
      return;
    }
    setState(() {
      _blocks.removeAt(index);
      if (_blocks.isEmpty) {
        _selectedBlockId = null;
        _activeRichTextController = null;
        _activeRichTextFocusNode = null;
        _activeRichTextBlockId = null;
      } else {
        final nextIndex = index.clamp(0, _blocks.length - 1);
        _selectedBlockId = _blocks[nextIndex].id;
        _activeRichTextController = null;
        _activeRichTextFocusNode = null;
        _activeRichTextBlockId = null;
      }
    });
    _syncBlockAnchorKeys();
    FocusManager.instance.primaryFocus?.unfocus();
    _rootFocusNode.requestFocus();
    _emitDraft();
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _blocks.length) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final targetIndex = newIndex.clamp(0, _blocks.length - 1);
    if (oldIndex == targetIndex) {
      return;
    }
    setState(() {
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(targetIndex, block);
      _selectedBlockId = block.id;
    });
    _emitDraft();
  }

  void _insertBlock(BlockDTO block, {bool selectBlock = true}) {
    final selectedId = _selectedBlockId;
    final insertIndex =
        selectedId == null ? _blocks.length : _indexOfBlock(selectedId) + 1;
    setState(() {
      _blocks.insert(
          insertIndex.clamp(0, _blocks.length), _normalizeBlock(block));
      _selectedBlockId = selectBlock ? block.id : _selectedBlockId;
    });
    _syncBlockAnchorKeys();
    _flashBlockHighlight(block.id);
    _emitDraft();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _flashBlockHighlight(String blockId) {
    final token = ++_highlightPulseToken;
    setState(() => _highlightedBlockId = blockId);
    _scrollBlockIntoView(blockId);
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted || token != _highlightPulseToken) {
        return;
      }
      if (_highlightedBlockId != blockId) {
        return;
      }
      setState(() => _highlightedBlockId = null);
    });
  }

  void _scrollBlockIntoView(
    String blockId, {
    Duration duration = const Duration(milliseconds: 260),
    Curve curve = Curves.easeOutCubic,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final targetContext = _blockAnchorKeys[blockId]?.currentContext;
      if (targetContext == null) {
        return;
      }
      await Scrollable.ensureVisible(
        targetContext,
        duration: duration,
        curve: curve,
        alignment: 0.18,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  Future<void> _insertLinkBlock() async {
    final result = await showDialog<_LinkEditorValue>(
      context: context,
      builder: (context) => const _LinkEditorDialog(
        title: '插入链接',
        confirmLabel: '插入',
      ),
    );
    if (result == null) {
      return;
    }
    _insertBlock(
      LinkBlockDTO(
        id: _nextId('link'),
        url: result.url.trim(),
        title: result.title.trim().isEmpty ? null : result.title.trim(),
        note: result.note.trim().isEmpty ? null : result.note.trim(),
      ),
    );
  }

  Future<void> _insertExerciseLibraryLinkBlock() async {
    final library = context.read<ExerciseLibraryService>();
    final entries = library.entries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在动作库添加动作')),
      );
      return;
    }

    final result = await _pickExerciseLibraryEntry(entries);
    if (result == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    _insertBlock(
      LinkBlockDTO(
        id: _nextId('exercise_link'),
        url: buildExerciseLibraryLinkUri(result.id).toString(),
        title: result.name.trim().isEmpty ? '动作链接' : result.name.trim(),
        note: '动作库链接',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已插入 ${result.name} 链接')),
    );
  }

  Future<ExerciseEntry?> _pickExerciseLibraryEntry(
    List<ExerciseEntry> entries, {
    String initialQuery = '',
  }) {
    return showModalBottomSheet<ExerciseEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ExerciseLibraryLinkPickerSheet(
        entries: entries,
        initialQuery: initialQuery,
      ),
    );
  }

  Future<void> _insertExerciseLibraryLinkAfterBlock(
    String blockId, {
    String initialQuery = '',
  }) async {
    final library = context.read<ExerciseLibraryService>();
    final entries = library.entries;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在动作库添加动作')),
      );
      return;
    }

    final result = await _pickExerciseLibraryEntry(
      entries,
      initialQuery: initialQuery,
    );
    if (result == null || !mounted) {
      return;
    }

    final nextBlock = LinkBlockDTO(
      id: _nextId('exercise_link'),
      url: buildExerciseLibraryLinkUri(result.id).toString(),
      title: result.name.trim().isEmpty ? '动作链接' : result.name.trim(),
      note: '动作库链接',
    );
    final blockIndex = _indexOfBlock(blockId);
    if (blockIndex == -1) {
      _insertBlock(nextBlock);
    } else {
      setState(() {
        _blocks.insert(blockIndex + 1, _normalizeBlock(nextBlock));
        _selectedBlockId = nextBlock.id;
      });
      _flashBlockHighlight(nextBlock.id);
      _emitDraft();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已插入 ${result.name} 链接')),
    );
  }

  Future<void> _insertAttachmentBlock() async {
    final pick = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (pick == null || pick.files.isEmpty) {
      return;
    }
    final file = pick.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      return;
    }
    _insertBlock(
      LinkBlockDTO(
        id: _nextId('attachment'),
        url: Uri.file(path).toString(),
        title: '附件',
        note: null,
      ),
    );
  }

  Future<void> _insertImageBlock() async {
    final pick = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );
    if (pick == null || pick.files.isEmpty) {
      return;
    }
    final file = pick.files.single;
    final path = file.path;
    if (path == null || path.trim().isEmpty) {
      return;
    }
    _insertBlock(
      ImageBlockDTO(
        id: _nextId('image'),
        attachments: <AttachmentDTO>[_newImageAttachment(path)],
        caption: null,
      ),
    );
  }

  Future<void> _insertTableBlock() async {
    final result = await showDialog<_TableShapeValue>(
      context: context,
      builder: (context) => const _TableShapeDialog(),
    );
    if (result == null) {
      return;
    }
    _insertBlock(
      TableBlockDTO(
        id: _nextId('table'),
        columnCount: result.columns,
        rows: List<List<String>>.generate(
          result.rows,
          (_) => List<String>.filled(result.columns, '', growable: false),
          growable: false,
        ),
      ),
    );
  }

  void _deleteSelectedFromKeyboard() {
    final block = _selectedBlock;
    if (block == null) {
      return;
    }
    if (block is TextBlockDTO ||
        block is HeadingBlockDTO ||
        block is ChecklistBlockDTO) {
      return;
    }
    _deleteBlock(block.id);
  }

  BlockDTO _newTextBlock() {
    return TextBlockDTO(id: _nextId('text'), text: '');
  }

  AttachmentDTO _newImageAttachment(String source) {
    return AttachmentDTO(
      id: source,
      mediaType: 'image',
      meta: <String, dynamic>{'source': source},
      createdAtUtc: DateTime.now().toUtc().toIso8601String(),
    );
  }

  String _nextId(String prefix) {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '${prefix}_$stamp';
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: We intentionally do NOT gate showTextToolbar on keyboardVisible.
    // When a PopupMenuButton in the toolbar opens, the system keyboard can
    // briefly hide on Android, which would unmount the PopupMenu while it
    // is still open 閳?causing a "deactivated widget ancestor" crash when
    // onSelected fires. Keeping the toolbar mounted whenever a text block
    // is active avoids this entirely.
    final showTextToolbar = _activeRichTextController != null &&
        (_selectedBlock is TextBlockDTO || _selectedBlock is HeadingBlockDTO);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    final content = Focus(
      focusNode: _rootFocusNode,
      child: Column(
        children: [
          if (widget.showTitleField)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _titleController,
                onTap: _clearActiveRichText,
                decoration: InputDecoration(
                  hintText: widget.titleHint,
                  border: InputBorder.none,
                ),
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          if (widget.showTitleField) const Divider(height: 1),
          if (widget.onOpenHeader != null)
            ListTile(
              title: Text(
                widget.headerTitle,
                style: AppTypography.bodyBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                widget.headerSubtitle ??
                    'Open ${widget.headerTitle.toLowerCase()}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.72),
                ),
              ),
              trailing: const Icon(Icons.tune),
              onTap: () {
                _clearActiveRichText();
                FocusManager.instance.primaryFocus?.unfocus();
                widget.onOpenHeader?.call();
              },
            ),
          if (widget.onOpenHeader != null) const Divider(height: 1),
          Expanded(
            child: _blocks.isEmpty ? _buildEmptyCanvas() : _buildBlockCanvas(),
          ),
          if (showTextToolbar)
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: _buildTextToolbar(compact: keyboardVisible),
            ),
          const Divider(height: 1),
          _buildInsertToolbar(compact: keyboardVisible),
        ],
      ),
    );

    final selected = _selectedBlock;
    final supportsBlockDeleteShortcut = selected != null &&
        selected is! TextBlockDTO &&
        selected is! HeadingBlockDTO &&
        selected is! ChecklistBlockDTO;
    if (!supportsBlockDeleteShortcut) {
      return content;
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.delete):
            DeleteCharacterIntent(forward: true),
        SingleActivator(LogicalKeyboardKey.backspace):
            DeleteCharacterIntent(forward: false),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DeleteCharacterIntent: CallbackAction<DeleteCharacterIntent>(
            onInvoke: (_) {
              if (_rootFocusNode.hasFocus) {
                _deleteSelectedFromKeyboard();
              }
              return null;
            },
          ),
        },
        child: content,
      ),
    );
  }

  Widget _buildBlockCanvas() {
    return ReorderableListView(
      scrollController: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      buildDefaultDragHandles: false,
      onReorder: _reorderBlocks,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
      children: [
        for (int index = 0; index < _blocks.length; index++)
          Padding(
            key: ValueKey<String>(_blocks[index].id),
            padding: EdgeInsets.only(
              bottom: index == _blocks.length - 1 ? 0 : 8,
            ),
            child: Container(
              key: _blockAnchorKey(_blocks[index].id),
              child: _buildBlockCard(
                _blocks[index],
                index,
                _blocks[index].id == _selectedBlockId,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyCanvas() {
    return ListView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.edit_note_outlined,
                size: 28,
                color: AppColors.textPrimary.withValues(alpha: 0.78),
              ),
              const SizedBox(height: 10),
              Text(
                '内容为空',
                style: AppTypography.bodyBold.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '使用下方插入栏添加正文、标题、图片、表格等内容。',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockCard(BlockDTO block, int index, bool selected) {
    final highlighted = _highlightedBlockId == block.id;
    final actionColor = selected
        ? AppColors.brandPrimaryVariant
        : AppColors.textPrimary.withValues(alpha: 0.76);
    final baseBorderColor = highlighted
        ? AppColors.brandPrimaryVariant.withValues(alpha: 0.9)
        : selected
            ? AppColors.brandPrimaryVariant.withValues(alpha: 0.34)
            : AppColors.textPrimary.withValues(alpha: 0.08);
    final baseFillColor = highlighted
        ? AppColors.brandPrimaryVariant.withValues(alpha: 0.12)
        : selected
            ? AppColors.surfaceSecondary.withValues(alpha: 0.08)
            : AppColors.surfaceSecondary.withValues(alpha: 0.03);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: baseFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: baseBorderColor,
          width: highlighted ? 1.2 : 1,
        ),
        boxShadow: highlighted
            ? [
                BoxShadow(
                  color: AppColors.brandPrimaryVariant.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ]
            : selected
                ? [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => _selectBlock(block.id, requestKeyboardFocus: true),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 4, 2),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.drag_indicator,
                        color: actionColor,
                        size: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _blockLabel(block),
                      style: AppTypography.caption.copyWith(
                        color: actionColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: selected || highlighted ? 1 : 0.44,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      splashRadius: 18,
                      icon: Icon(
                        Icons.delete_outline,
                        color: actionColor,
                        size: 17,
                      ),
                      onPressed: () => _deleteBlock(block.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildBlockEditor(block, selected),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockEditor(BlockDTO block, bool selected) {
    if (block is TextBlockDTO) {
      return _PlainTextBlockEditor(
        key: ValueKey<String>('text_${block.id}'),
        block: block,
        onSelected: () => _selectBlock(block.id),
        onActivated: (controller, focusNode) =>
            _activateRichTextBlock(block.id, controller, focusNode),
        onChanged: _replaceBlock,
      );
    }
    if (block is HeadingBlockDTO) {
      return _HeadingBlockEditor(
        key: ValueKey<String>('heading_${block.id}'),
        block: block,
        onSelected: () => _selectBlock(block.id),
        onActivated: (controller, focusNode) =>
            _activateRichTextBlock(block.id, controller, focusNode),
        onChanged: _replaceBlock,
      );
    }
    if (block is ChecklistBlockDTO) {
      return _ChecklistBlockEditor(
        key: ValueKey<String>('check_${block.id}'),
        block: block,
        onSelected: () => _selectBlock(block.id),
        onChanged: _replaceBlock,
        onInsertAction: (seedText) {
          return _insertExerciseLibraryLinkAfterBlock(
            block.id,
            initialQuery: seedText,
          );
        },
      );
    }
    if (block is DividerBlockDTO) {
      return _DividerBlockEditor(
        selected: selected,
        onTap: () => _selectBlock(block.id, requestKeyboardFocus: true),
      );
    }
    if (block is LinkBlockDTO) {
      return _LinkBlockEditor(
        key: ValueKey<String>('link_${block.id}'),
        block: block,
        onSelected: () => _selectBlock(block.id, requestKeyboardFocus: true),
        onChanged: _replaceBlock,
        onOpenExerciseLink: () async {
          final entryId = parseExerciseLibraryLinkId(block.url);
          if (entryId == null) {
            return;
          }
          final entry =
              context.read<ExerciseLibraryService>().findById(entryId);
          if (entry == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('未找到动作')),
            );
            return;
          }
          await Navigator.of(context).pushNamed(
            '/exercise_library_entry',
            arguments: {'entryId': entryId},
          );
          if (!mounted) {
            return;
          }
          _selectBlock(block.id, requestKeyboardFocus: true);
          _flashBlockHighlight(block.id);
        },
        onReplaceExerciseLink: () async {
          final entry = await _pickExerciseLibraryEntry(
            context.read<ExerciseLibraryService>().entries,
          );
          if (entry == null) {
            return;
          }
          _replaceBlock(
            LinkBlockDTO(
              id: block.id,
              url: buildExerciseLibraryLinkUri(entry.id).toString(),
              title: entry.name.trim().isEmpty ? '动作链接' : entry.name,
              note: '动作库链接',
            ),
          );
        },
        onPickFile: () async {
          final pick =
              await FilePicker.platform.pickFiles(allowMultiple: false);
          if (pick == null || pick.files.isEmpty) {
            return;
          }
          final file = pick.files.single;
          final path = file.path;
          if (path == null || path.trim().isEmpty) {
            return;
          }
          _replaceBlock(
            LinkBlockDTO(
              id: block.id,
              url: Uri.file(path).toString(),
              title: (block.title?.trim().isEmpty ?? true) ? '附件' : block.title,
              note: block.note,
            ),
          );
        },
      );
    }
    if (block is ImageBlockDTO) {
      return _ImageBlockEditor(
        key: ValueKey<String>('image_${block.id}'),
        block: block,
        onSelected: () => _selectBlock(block.id, requestKeyboardFocus: true),
        onChanged: _replaceBlock,
        onPickImage: () async {
          final pick = await FilePicker.platform.pickFiles(
            allowMultiple: false,
            type: FileType.image,
          );
          if (pick == null || pick.files.isEmpty) {
            return;
          }
          final file = pick.files.single;
          final path = file.path;
          if (path == null || path.trim().isEmpty) {
            return;
          }
          _replaceBlock(
            ImageBlockDTO(
              id: block.id,
              attachments: <AttachmentDTO>[_newImageAttachment(path)],
              caption: (block.caption?.trim().isEmpty ?? true)
                  ? null
                  : block.caption,
            ),
          );
        },
      );
    }
    if (block is TableBlockDTO) {
      return _TableBlockEditor(
        key: ValueKey<String>('table_${block.id}'),
        block: block,
        onSelected: () => _selectBlock(block.id, requestKeyboardFocus: true),
        onChanged: (next) => _replaceBlock(_normalizeTableBlock(next)),
      );
    }

    return Text(
      'Unsupported block: ${block.runtimeType}',
      style: AppTypography.caption.copyWith(color: Colors.redAccent),
    );
  }

  Widget _buildTextToolbar({bool compact = false}) {
    final controller = _activeRichTextController;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: AppColors.surfaceSecondary,
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final selectionStyle = controller.getSelectionStyle().attributes;
            final rawSize =
                selectionStyle[fq.Attribute.size.key]?.value as String?;
            final textColor = _selectionTextColor(selectionStyle);
            final canClearText = _hasVisibleTextContent(controller);

            // 閳光偓閳光偓 size options (null = default)
            const sizes = <String?>[null, '12', '14', '16', '18', '20', '24'];
            // 閳光偓閳光偓 color palette (null = default)
            const colors = <Color?>[
              null,
              Color(0xFFEFEFEF), // White-ish
              Color(0xFF111827), // Black
              Color(0xFF0F766E), // Teal
              Color(0xFF2563EB), // Blue
              Color(0xFFDC2626), // Red
              Color(0xFF7C3AED), // Violet
              Color(0xFFF59E0B), // Amber
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.fromLTRB(
                      8, compact ? 5 : 8, 8, compact ? 2 : 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 閳光偓閳光偓 inline formatting 閳光偓閳光偓
                      _InlineToolbarIconButton(
                        icon: Icons.format_bold,
                        selected:
                            selectionStyle.containsKey(fq.Attribute.bold.key),
                        onPressed: () => _toggleInlineAttribute(
                            controller, fq.Attribute.bold),
                      ),
                      _InlineToolbarIconButton(
                        icon: Icons.format_italic,
                        selected:
                            selectionStyle.containsKey(fq.Attribute.italic.key),
                        onPressed: () => _toggleInlineAttribute(
                            controller, fq.Attribute.italic),
                      ),
                      _InlineToolbarIconButton(
                        icon: Icons.format_underlined,
                        selected: selectionStyle
                            .containsKey(fq.Attribute.underline.key),
                        onPressed: () => _toggleInlineAttribute(
                            controller, fq.Attribute.underline),
                      ),
                      _InlineToolbarIconButton(
                        icon: Icons.format_strikethrough,
                        selected: selectionStyle
                            .containsKey(fq.Attribute.strikeThrough.key),
                        onPressed: () => _toggleInlineAttribute(
                            controller, fq.Attribute.strikeThrough),
                      ),
                      const _ToolbarDivider(),
                      // 閳光偓閳光偓 size pills 閳光偓閳光偓
                      for (final size in sizes)
                        _SizePill(
                          size: size,
                          selected: rawSize == size,
                          onTap: () => _applyFontSize(controller, size),
                        ),
                      const _ToolbarDivider(),
                      // 閳光偓閳光偓 color dots 閳光偓閳光偓
                      for (final color in colors)
                        _ColorDot(
                          color: color,
                          selected: textColor == color,
                          onTap: () => _applyTextColor(controller, color),
                        ),
                      const _ToolbarDivider(),
                      _ToolbarButton(
                        icon: Icons.backspace_outlined,
                        label: '清除',
                        onPressed:
                            canClearText ? _clearActiveTextContent : null,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggleInlineAttribute(
    fq.QuillController controller,
    fq.Attribute<dynamic> attribute,
  ) {
    final hasAttribute =
        controller.getSelectionStyle().attributes.containsKey(attribute.key);
    controller.formatSelection(
      hasAttribute ? fq.Attribute.clone(attribute, null) : attribute,
    );
    _activeRichTextFocusNode?.requestFocus();
  }

  void _applyFontSize(fq.QuillController controller, String? size) {
    if (size == null) {
      // Clear: must use Attribute.clone with null value
      controller.formatSelection(fq.Attribute.clone(fq.Attribute.size, null));
    } else {
      controller.formatSelection(fq.SizeAttribute(size));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activeRichTextFocusNode?.requestFocus();
    });
  }

  void _applyTextColor(fq.QuillController controller, Color? color) {
    if (color == null) {
      // Clear: must use Attribute.clone with null value
      controller.formatSelection(fq.Attribute.clone(fq.Attribute.color, null));
    } else {
      controller.formatSelection(fq.ColorAttribute(_colorToHex(color)));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activeRichTextFocusNode?.requestFocus();
    });
  }

  Color? _selectionTextColor(Map<String, fq.Attribute<dynamic>> attributes) {
    final value = attributes[fq.Attribute.color.key]?.value as String?;
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final hex = value.trim().replaceFirst('#', '');
    final normalized = hex.length == 6 ? 'ff$hex' : hex;
    final intValue = int.tryParse(normalized, radix: 16);
    if (intValue == null) {
      return null;
    }
    return Color(intValue);
  }

  String _colorToHex(Color color) {
    // Use color.value (ARGB 32-bit int) 閳?mask off alpha to get 6-char hex
    // ignore: deprecated_member_use
    final rgb = color.value & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0')}';
  }

  bool _hasVisibleTextContent(fq.QuillController controller) {
    final plainText = controller.plainTextEditingValue.text;
    return plainText.replaceAll('\n', '').trim().isNotEmpty;
  }

  fq.Attribute<int?> _headingAttributeForLevel(int level) {
    return switch (level) {
      1 => fq.Attribute.h1,
      2 => fq.Attribute.h2,
      _ => fq.Attribute.h3,
    };
  }

  void _clearActiveTextContent() {
    final controller = _activeRichTextController;
    final block = _selectedBlock;
    if (controller == null || block == null) {
      return;
    }
    controller.clear();
    if (block is HeadingBlockDTO) {
      controller.formatText(
        0,
        controller.document.length,
        _headingAttributeForLevel(block.level),
      );
    }
    _activeRichTextFocusNode?.requestFocus();
  }

  Widget _buildInsertToolbar({bool compact = false}) {
    return Material(
      color: AppColors.surfaceSecondary,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.fromLTRB(8, compact ? 4 : 6, 8, compact ? 6 : 10),
          child: Row(
            children: [
              if (!compact)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '插入',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              _ToolbarButton(
                icon: Icons.fitness_center_outlined,
                label: '动作',
                onPressed: _insertExerciseLibraryLinkBlock,
              ),
              _ToolbarButton(
                icon: Icons.notes_outlined,
                label: '文本',
                onPressed: () => _insertBlock(_newTextBlock()),
              ),
              _ToolbarButton(
                icon: Icons.title_outlined,
                label: 'H1',
                onPressed: () => _insertBlock(
                  HeadingBlockDTO(id: _nextId('heading'), text: '', level: 1),
                ),
              ),
              _ToolbarButton(
                icon: Icons.looks_two_outlined,
                label: 'H2',
                onPressed: () => _insertBlock(
                  HeadingBlockDTO(id: _nextId('heading'), text: '', level: 2),
                ),
              ),
              _ToolbarButton(
                icon: Icons.checklist_rtl,
                label: '清单',
                onPressed: () => _insertBlock(
                  ChecklistBlockDTO(
                    id: _nextId('check'),
                    items: const <ChecklistItemDTO>[
                      ChecklistItemDTO(text: '', checked: false),
                    ],
                  ),
                ),
              ),
              _ToolbarButton(
                icon: Icons.link_outlined,
                label: '链接',
                onPressed: _insertLinkBlock,
              ),
              _ToolbarButton(
                icon: Icons.attach_file_outlined,
                label: '文件',
                onPressed: _insertAttachmentBlock,
              ),
              _ToolbarButton(
                icon: Icons.image_outlined,
                label: '图片',
                onPressed: _insertImageBlock,
              ),
              _ToolbarButton(
                icon: Icons.table_chart_outlined,
                label: '表格',
                onPressed: _insertTableBlock,
              ),
              _ToolbarButton(
                icon: Icons.horizontal_rule,
                label: '分隔线',
                onPressed: () =>
                    _insertBlock(DividerBlockDTO(id: _nextId('divider'))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _blockLabel(BlockDTO block) {
    if (block is TextBlockDTO) {
      return '正文';
    }
    if (block is HeadingBlockDTO) {
      return '标题 ${block.level}';
    }
    if (block is ChecklistBlockDTO) {
      return '清单';
    }
    if (block is DividerBlockDTO) {
      return '分隔线';
    }
    if (block is LinkBlockDTO) {
      if (parseExerciseLibraryLinkId(block.url) != null) {
        return '动作库动作';
      }
      return _isFileReference(block.url) ? '附件' : '链接';
    }
    if (block is ImageBlockDTO) {
      return '图片';
    }
    if (block is TableBlockDTO) {
      return '表格';
    }
    return block.type;
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          backgroundColor: enabled
              ? AppColors.surfacePrimary.withValues(alpha: 0.74)
              : AppColors.surfacePrimary.withValues(alpha: 0.32),
          foregroundColor: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _InlineToolbarIconButton extends StatelessWidget {
  const _InlineToolbarIconButton({
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton.filledTonal(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        selectedIcon: Icon(icon, size: 18),
        isSelected: selected,
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
          backgroundColor: selected
              ? AppColors.brandPrimaryVariant.withValues(alpha: 0.18)
              : AppColors.surfacePrimary.withValues(alpha: 0.74),
          foregroundColor:
              selected ? AppColors.brandPrimaryVariant : AppColors.textPrimary,
        ),
      ),
    );
  }
}

// Small vertical separator between toolbar sections
class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: Colors.white24,
        ),
      );
}

/// Font-size pill. [size] == null means "clear / default".
class _SizePill extends StatelessWidget {
  const _SizePill({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final String? size;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = size ?? 'A';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandPrimaryVariant.withValues(alpha: 0.20)
                : AppColors.surfacePrimary.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimaryVariant.withValues(alpha: 0.80)
                  : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: size == null ? 12 : 11,
              color: selected
                  ? AppColors.brandPrimaryVariant
                  : AppColors.textPrimary.withValues(alpha: 0.85),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Color swatch dot. [color] == null means "clear / default" (shown as 鑴?.
class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const dotSize = 24.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color ?? AppColors.surfacePrimary.withValues(alpha: 0.70),
            border: Border.all(
              color: selected ? AppColors.brandPrimaryVariant : Colors.white30,
              width: selected ? 2.5 : 1.2,
            ),
          ),
          child: color == null
              ? Icon(
                  Icons.close,
                  size: 13,
                  color: AppColors.textPrimary.withValues(alpha: 0.70),
                )
              : null,
        ),
      ),
    );
  }
}

typedef _RichTextBlockActivation = void Function(
  fq.QuillController controller,
  FocusNode focusNode,
);

class _PlainTextBlockEditor extends StatefulWidget {
  const _PlainTextBlockEditor({
    super.key,
    required this.block,
    required this.onSelected,
    required this.onActivated,
    required this.onChanged,
  });

  final TextBlockDTO block;
  final VoidCallback onSelected;
  final _RichTextBlockActivation onActivated;
  final ValueChanged<TextBlockDTO> onChanged;

  @override
  State<_PlainTextBlockEditor> createState() => _PlainTextBlockEditorState();
}

class _PlainTextBlockEditorState extends State<_PlainTextBlockEditor> {
  late final fq.QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  String _lastSerializedValue = '';

  @override
  void initState() {
    super.initState();
    _controller = fq.QuillController(
      document: parseAiwaInlineDocument(widget.block.text),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _focusNode = FocusNode(debugLabel: 'Paragraph_${widget.block.id}');
    _scrollController = ScrollController();
    _lastSerializedValue = encodeAiwaInlineDocument(_controller.document);
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _PlainTextBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final normalized = normalizeAiwaRichTextStorage(widget.block.text);
    if (oldWidget.block.text != widget.block.text &&
        normalized != _lastSerializedValue) {
      _controller.document = parseAiwaInlineDocument(widget.block.text);
      _controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        fq.ChangeSource.local,
      );
      _lastSerializedValue = encodeAiwaInlineDocument(_controller.document);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      widget.onSelected();
      widget.onActivated(_controller, _focusNode);
    }
  }

  void _handleControllerChanged() {
    if (_focusNode.hasFocus) {
      widget.onSelected();
      widget.onActivated(_controller, _focusNode);
    }
    final serialized = encodeAiwaInlineDocument(_controller.document);
    if (serialized == _lastSerializedValue) {
      return;
    }
    _lastSerializedValue = serialized;
    widget.onChanged(TextBlockDTO(id: widget.block.id, text: serialized));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        widget.onSelected();
        widget.onActivated(_controller, _focusNode);
      },
      child: fq.QuillEditor.basic(
        controller: _controller,
        focusNode: _focusNode,
        scrollController: _scrollController,
        config: const fq.QuillEditorConfig(
          scrollable: false,
          padding: EdgeInsets.zero,
          placeholder: '正文内容',
        ),
      ),
    );
  }
}

class _HeadingBlockEditor extends StatefulWidget {
  const _HeadingBlockEditor({
    super.key,
    required this.block,
    required this.onSelected,
    required this.onActivated,
    required this.onChanged,
  });

  final HeadingBlockDTO block;
  final VoidCallback onSelected;
  final _RichTextBlockActivation onActivated;
  final ValueChanged<HeadingBlockDTO> onChanged;

  @override
  State<_HeadingBlockEditor> createState() => _HeadingBlockEditorState();
}

class _HeadingBlockEditorState extends State<_HeadingBlockEditor> {
  late final fq.QuillController _controller;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  String _lastSerializedValue = '';

  @override
  void initState() {
    super.initState();
    _controller = fq.QuillController(
      document: parseAiwaInlineDocument(widget.block.text),
      selection: const TextSelection.collapsed(offset: 0),
    );
    _focusNode = FocusNode(debugLabel: 'Heading_${widget.block.id}');
    _scrollController = ScrollController();
    _applyHeadingLevel(widget.block.level);
    _lastSerializedValue = encodeAiwaInlineDocument(_controller.document);
    _controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _HeadingBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final normalized = normalizeAiwaRichTextStorage(widget.block.text);
    if (oldWidget.block.text != widget.block.text &&
        normalized != _lastSerializedValue) {
      _controller.document = parseAiwaInlineDocument(widget.block.text);
      _controller.updateSelection(
        const TextSelection.collapsed(offset: 0),
        fq.ChangeSource.local,
      );
      _applyHeadingLevel(widget.block.level);
      _lastSerializedValue = encodeAiwaInlineDocument(_controller.document);
      return;
    }
    if (oldWidget.block.level != widget.block.level) {
      _applyHeadingLevel(widget.block.level);
      _lastSerializedValue = encodeAiwaInlineDocument(_controller.document);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_handleFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  fq.Attribute<int?> _headingAttribute(int level) {
    return switch (level) {
      1 => fq.Attribute.h1,
      2 => fq.Attribute.h2,
      _ => fq.Attribute.h3,
    };
  }

  void _applyHeadingLevel(int level) {
    _controller.formatText(
      0,
      _controller.document.length,
      _headingAttribute(level),
      shouldNotifyListeners: false,
    );
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      widget.onSelected();
      widget.onActivated(_controller, _focusNode);
    }
  }

  void _handleControllerChanged() {
    if (_focusNode.hasFocus) {
      widget.onSelected();
      widget.onActivated(_controller, _focusNode);
    }
    final serialized = encodeAiwaInlineDocument(_controller.document);
    if (serialized == _lastSerializedValue) {
      return;
    }
    _lastSerializedValue = serialized;
    widget.onChanged(
      HeadingBlockDTO(
        id: widget.block.id,
        text: serialized,
        level: widget.block.level,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = switch (widget.block.level) {
      1 => AppColors.brandPrimaryVariant,
      2 => AppColors.brandPrimaryVariant.withValues(alpha: 0.84),
      _ => AppColors.brandPrimaryVariant.withValues(alpha: 0.68),
    };

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        widget.onSelected();
        widget.onActivated(_controller, _focusNode);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<int>(
                segments: const <ButtonSegment<int>>[
                  ButtonSegment<int>(value: 1, label: Text('H1')),
                  ButtonSegment<int>(value: 2, label: Text('H2')),
                  ButtonSegment<int>(value: 3, label: Text('H3')),
                ],
                selected: <int>{widget.block.level},
                onSelectionChanged: (selection) {
                  final level = selection.first;
                  _applyHeadingLevel(level);
                  final serialized =
                      encodeAiwaInlineDocument(_controller.document);
                  _lastSerializedValue = serialized;
                  widget.onChanged(
                    HeadingBlockDTO(
                      id: widget.block.id,
                      text: serialized,
                      level: level,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            fq.QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              scrollController: _scrollController,
              config: const fq.QuillEditorConfig(
                scrollable: false,
                padding: EdgeInsets.zero,
                placeholder: '标题内容',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistBlockEditor extends StatefulWidget {
  const _ChecklistBlockEditor({
    super.key,
    required this.block,
    required this.onSelected,
    required this.onChanged,
    required this.onInsertAction,
  });

  final ChecklistBlockDTO block;
  final VoidCallback onSelected;
  final ValueChanged<ChecklistBlockDTO> onChanged;
  final Future<void> Function(String seedText) onInsertAction;

  @override
  State<_ChecklistBlockEditor> createState() => _ChecklistBlockEditorState();
}

class _ChecklistBlockEditorState extends State<_ChecklistBlockEditor> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _buildControllers(widget.block.items);
  }

  @override
  void didUpdateWidget(covariant _ChecklistBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controllers.length != widget.block.items.length) {
      for (final controller in _controllers) {
        controller.dispose();
      }
      _controllers = _buildControllers(widget.block.items);
      return;
    }
    for (int i = 0; i < widget.block.items.length; i++) {
      final nextText = widget.block.items[i].text;
      if (_controllers[i].text != nextText) {
        _controllers[i].text = nextText;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> _buildControllers(List<ChecklistItemDTO> items) {
    final source = items.isEmpty
        ? const <ChecklistItemDTO>[ChecklistItemDTO(text: '', checked: false)]
        : items;
    return source
        .map((item) => TextEditingController(text: item.text))
        .toList(growable: false);
  }

  void _updateItem(int index, {String? text, bool? checked}) {
    final items = List<ChecklistItemDTO>.from(widget.block.items);
    while (items.length <= index) {
      items.add(const ChecklistItemDTO(text: '', checked: false));
    }
    final current = items[index];
    items[index] = ChecklistItemDTO(
      text: text ?? current.text,
      checked: checked ?? current.checked,
    );
    widget.onChanged(ChecklistBlockDTO(id: widget.block.id, items: items));
  }

  void _removeItem(int index) {
    final items = List<ChecklistItemDTO>.from(widget.block.items);
    if (items.length == 1) {
      items[0] = const ChecklistItemDTO(text: '', checked: false);
    } else {
      items.removeAt(index);
    }
    widget.onChanged(ChecklistBlockDTO(id: widget.block.id, items: items));
  }

  void _addItem() {
    final items = List<ChecklistItemDTO>.from(widget.block.items)
      ..add(const ChecklistItemDTO(text: '', checked: false));
    widget.onChanged(ChecklistBlockDTO(id: widget.block.id, items: items));
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.block.items.isEmpty
        ? const <ChecklistItemDTO>[ChecklistItemDTO(text: '', checked: false)]
        : widget.block.items;

    return Column(
      children: [
        for (int index = 0; index < items.length; index++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Checkbox(
                value: items[index].checked,
                onChanged: (value) {
                  widget.onSelected();
                  _updateItem(index, checked: value ?? false);
                },
              ),
              Expanded(
                child: TextField(
                  controller: _controllers[index],
                  minLines: 1,
                  maxLines: null,
                  onTap: widget.onSelected,
                  onChanged: (value) => _updateItem(index, text: value),
                  decoration: const InputDecoration(
                    hintText: '清单项',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: AppTypography.bodyBase.copyWith(
                    color: AppColors.textPrimary,
                    decoration: items[index].checked
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _removeItem(index),
              ),
              IconButton(
                tooltip: '下方插入动作',
                icon: const Icon(Icons.fitness_center_outlined, size: 18),
                onPressed: () async {
                  widget.onSelected();
                  await widget.onInsertAction(_controllers[index].text.trim());
                },
              ),
            ],
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加项目'),
            ),
            TextButton.icon(
              onPressed: () async {
                widget.onSelected();
                await widget.onInsertAction('');
              },
              icon: const Icon(Icons.fitness_center_outlined, size: 18),
              label: const Text('下方添加动作'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DividerBlockEditor extends StatelessWidget {
  const _DividerBlockEditor({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Divider(
            thickness: 1.3,
            color: selected
                ? AppColors.brandPrimaryVariant
                : AppColors.textPrimary.withValues(alpha: 0.26),
          ),
          const SizedBox(height: 2),
          Text(
            '点标题栏或删除按钮移除此分隔线',
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkBlockEditor extends StatefulWidget {
  const _LinkBlockEditor({
    super.key,
    required this.block,
    required this.onSelected,
    required this.onChanged,
    required this.onOpenExerciseLink,
    required this.onReplaceExerciseLink,
    required this.onPickFile,
  });

  final LinkBlockDTO block;
  final VoidCallback onSelected;
  final ValueChanged<LinkBlockDTO> onChanged;
  final VoidCallback onOpenExerciseLink;
  final Future<void> Function() onReplaceExerciseLink;
  final Future<void> Function() onPickFile;

  @override
  State<_LinkBlockEditor> createState() => _LinkBlockEditorState();
}

enum _ExerciseLinkMenuAction { open, replace, copyLabel }

class _LinkBlockEditorState extends State<_LinkBlockEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _urlController;
  late final TextEditingController _noteController;
  bool _actionHovered = false;
  bool _actionPressed = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.block.title ?? '');
    _urlController = TextEditingController(text: widget.block.url);
    _noteController = TextEditingController(text: widget.block.note ?? '');
  }

  @override
  void didUpdateWidget(covariant _LinkBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.title != widget.block.title &&
        _titleController.text != (widget.block.title ?? '')) {
      _titleController.text = widget.block.title ?? '';
    }
    if (oldWidget.block.url != widget.block.url &&
        _urlController.text != widget.block.url) {
      _urlController.text = widget.block.url;
    }
    if (oldWidget.block.note != widget.block.note &&
        _noteController.text != (widget.block.note ?? '')) {
      _noteController.text = widget.block.note ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      LinkBlockDTO(
        id: widget.block.id,
        url: _urlController.text.trim(),
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  String _fileDisplayName() {
    final explicitTitle = _titleController.text.trim();
    if (explicitTitle.isNotEmpty) {
      return explicitTitle;
    }
    final url = _urlController.text.trim();
    final uri = Uri.tryParse(url);
    if (uri != null && uri.scheme == 'file') {
      final path = uri.toFilePath(windows: true);
      final name = p.basename(path);
      if (name.trim().isNotEmpty) {
        return name.trim();
      }
    }
    return '已附加文件';
  }

  Future<void> _showExerciseLinkMenu(
    LongPressStartDetails details,
    String label,
  ) async {
    widget.onSelected();
    HapticFeedback.mediumImpact();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (overlay is! RenderBox) {
      return;
    }

    final action = await showMenu<_ExerciseLinkMenuAction>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          details.globalPosition.dx,
          details.globalPosition.dy,
          0,
          0,
        ),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem<_ExerciseLinkMenuAction>(
          value: _ExerciseLinkMenuAction.open,
          child: Text('打开动作'),
        ),
        PopupMenuItem<_ExerciseLinkMenuAction>(
          value: _ExerciseLinkMenuAction.replace,
          child: Text('替换动作'),
        ),
        PopupMenuItem<_ExerciseLinkMenuAction>(
          value: _ExerciseLinkMenuAction.copyLabel,
          child: Text('复制文本'),
        ),
      ],
    );
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _ExerciseLinkMenuAction.open:
        widget.onOpenExerciseLink();
        return;
      case _ExerciseLinkMenuAction.replace:
        await widget.onReplaceExerciseLink();
        return;
      case _ExerciseLinkMenuAction.copyLabel:
        final text = label.trim().isEmpty ? '动作链接' : label.trim();
        HapticFeedback.selectionClick();
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已复制“$text”')),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFile = _isFileReference(widget.block.url);
    final isExerciseLink = parseExerciseLibraryLinkId(widget.block.url) != null;

    if (isExerciseLink) {
      final label = (widget.block.title ?? '动作链接').trim();
      final linkActive = _actionHovered || _actionPressed;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.link_rounded,
              size: 16,
              color: AppColors.brandPrimaryVariant.withValues(alpha: 0.9),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MouseRegion(
                onEnter: (_) => setState(() => _actionHovered = true),
                onExit: (_) => setState(() => _actionHovered = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPressStart: (LongPressStartDetails details) =>
                      _showExerciseLinkMenu(details, label),
                  child: InkWell(
                    onTap: () {
                      widget.onSelected();
                      widget.onOpenExerciseLink();
                    },
                    onHighlightChanged: (pressed) {
                      if (_actionPressed == pressed) {
                        return;
                      }
                      setState(() => _actionPressed = pressed);
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimaryVariant.withValues(
                          alpha: linkActive ? 0.18 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        label.isEmpty ? '动作链接' : label,
                        style: AppTypography.bodyBase.copyWith(
                          color: AppColors.brandPrimaryVariant.withValues(
                            alpha: linkActive ? 1 : 0.96,
                          ),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.brandPrimaryVariant,
                          decorationThickness: linkActive ? 2.2 : 1.6,
                          backgroundColor: AppColors.brandPrimaryVariant
                              .withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: '替换动作',
              onPressed: () async {
                widget.onSelected();
                await widget.onReplaceExerciseLink();
              },
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.swap_horiz_rounded,
                size: 18,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
            IconButton(
              tooltip: '打开动作',
              onPressed: widget.onOpenExerciseLink,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppColors.brandPrimaryVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFile)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfacePrimary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _fileDisplayName(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    widget.onSelected();
                    await widget.onPickFile();
                  },
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('替换'),
                ),
              ],
            ),
          ),
        TextField(
          controller: _titleController,
          onTap: widget.onSelected,
          onChanged: (_) => _emit(),
          decoration: InputDecoration(
            labelText: isFile ? '文件名' : '标题',
            border: InputBorder.none,
            isDense: true,
          ),
          style: AppTypography.bodyBase.copyWith(color: AppColors.textPrimary),
        ),
        if (!isFile)
          TextField(
            controller: _urlController,
            onTap: widget.onSelected,
            onChanged: (_) => _emit(),
            decoration: const InputDecoration(
              labelText: '链接',
              hintText: 'https://',
              border: InputBorder.none,
              isDense: true,
            ),
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
          ),
        TextField(
          controller: _noteController,
          onTap: widget.onSelected,
          onChanged: (_) => _emit(),
          decoration: const InputDecoration(
            labelText: '备注',
            border: InputBorder.none,
            isDense: true,
          ),
          style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _ImageBlockEditor extends StatefulWidget {
  const _ImageBlockEditor({
    super.key,
    required this.block,
    required this.onSelected,
    required this.onChanged,
    required this.onPickImage,
  });

  final ImageBlockDTO block;
  final VoidCallback onSelected;
  final ValueChanged<ImageBlockDTO> onChanged;
  final Future<void> Function() onPickImage;

  @override
  State<_ImageBlockEditor> createState() => _ImageBlockEditorState();
}

class _ImageBlockEditorState extends State<_ImageBlockEditor> {
  late final TextEditingController _captionController;
  late String _source;

  @override
  void initState() {
    super.initState();
    _captionController =
        TextEditingController(text: widget.block.caption ?? '');
    _source = _imageSource(widget.block);
  }

  @override
  void didUpdateWidget(covariant _ImageBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.caption != widget.block.caption &&
        _captionController.text != (widget.block.caption ?? '')) {
      _captionController.text = widget.block.caption ?? '';
    }
    final nextSource = _imageSource(widget.block);
    if (_source != nextSource) {
      _source = nextSource;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  String _imageSource(ImageBlockDTO block) {
    if (block.attachments.isEmpty) {
      return '';
    }
    final attachment = block.attachments.first;
    return attachment.meta?['source'] as String? ?? attachment.id;
  }

  void _emit() {
    final attachment = widget.block.attachments.isNotEmpty
        ? widget.block.attachments.first
        : AttachmentDTO(
            id: '',
            mediaType: 'image',
            meta: const <String, dynamic>{},
            createdAtUtc: DateTime.now().toUtc().toIso8601String(),
          );
    final source = _source.trim();
    widget.onChanged(
      ImageBlockDTO(
        id: widget.block.id,
        attachments: <AttachmentDTO>[
          AttachmentDTO(
            id: source,
            mediaType: 'image',
            meta: <String, dynamic>{...?attachment.meta, 'source': source},
            createdAtUtc: attachment.createdAtUtc,
          ),
        ],
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = _source.trim();
    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');
    final preview = isNetwork
        ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              source,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          )
        : buildAiwaLocalImagePreview(source);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfacePrimary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (preview != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: preview,
                  ),
                ),
              if (preview != null) const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isNetwork ? Icons.public : Icons.image_outlined,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      source.isEmpty
                          ? '未选择图片'
                          : (widget.block.caption?.trim().isNotEmpty ?? false)
                              ? widget.block.caption!.trim()
                              : '图片预览',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () async {
                  widget.onSelected();
                  await widget.onPickImage();
                },
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('选择图片'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          onTap: widget.onSelected,
          onChanged: (_) => _emit(),
          decoration: const InputDecoration(
            labelText: '说明',
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _TableBlockEditor extends StatefulWidget {
  const _TableBlockEditor({
    super.key,
    required this.block,
    required this.onSelected,
    required this.onChanged,
  });

  final TableBlockDTO block;
  final VoidCallback onSelected;
  final ValueChanged<TableBlockDTO> onChanged;

  @override
  State<_TableBlockEditor> createState() => _TableBlockEditorState();
}

class _TableBlockEditorState extends State<_TableBlockEditor> {
  late List<List<TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _buildControllers(widget.block);
  }

  @override
  void didUpdateWidget(covariant _TableBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final structureChanged = _controllers.length != widget.block.rows.length ||
        _controllers.any((row) => row.length != widget.block.columnCount);
    if (structureChanged) {
      for (final row in _controllers) {
        for (final controller in row) {
          controller.dispose();
        }
      }
      _controllers = _buildControllers(widget.block);
      return;
    }
    for (int row = 0; row < widget.block.rows.length; row++) {
      for (int col = 0; col < widget.block.columnCount; col++) {
        final nextText = widget.block.rows[row][col];
        if (_controllers[row][col].text != nextText) {
          _controllers[row][col].text = nextText;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final row in _controllers) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  List<List<TextEditingController>> _buildControllers(TableBlockDTO block) {
    return block.rows
        .map(
          (row) => row
              .map((cell) => TextEditingController(text: cell))
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  void _updateCell(int rowIndex, int columnIndex, String value) {
    final rows = widget.block.rows
        .map((row) => List<String>.from(row, growable: true))
        .toList(growable: true);
    rows[rowIndex][columnIndex] = value;
    widget.onChanged(
      TableBlockDTO(
        id: widget.block.id,
        columnCount: widget.block.columnCount,
        rows: rows,
      ),
    );
  }

  Future<void> _editShape() async {
    widget.onSelected();
    final result = await showDialog<_TableShapeValue>(
      context: context,
      builder: (context) => _TableShapeDialog(
        initialRows: widget.block.rows.length,
        initialColumns: widget.block.columnCount,
      ),
    );
    if (result == null) {
      return;
    }

    final nextRows = List<List<String>>.generate(
      result.rows,
      (rowIndex) => List<String>.generate(
        result.columns,
        (columnIndex) {
          if (rowIndex >= widget.block.rows.length) {
            return '';
          }
          final row = widget.block.rows[rowIndex];
          if (columnIndex >= row.length) {
            return '';
          }
          return row[columnIndex];
        },
        growable: false,
      ),
      growable: false,
    );

    widget.onChanged(
      TableBlockDTO(
        id: widget.block.id,
        columnCount: result.columns,
        rows: nextRows,
      ),
    );
  }

  void _appendRow() {
    final rows = widget.block.rows
        .map((row) => List<String>.from(row, growable: true))
        .toList(growable: true)
      ..add(List<String>.filled(widget.block.columnCount, '', growable: false));
    widget.onChanged(
      TableBlockDTO(
        id: widget.block.id,
        columnCount: widget.block.columnCount,
        rows: rows,
      ),
    );
  }

  void _appendColumn() {
    final nextColumnCount = widget.block.columnCount + 1;
    final rows = widget.block.rows
        .map(
          (row) => List<String>.generate(
            nextColumnCount,
            (index) => index < row.length ? row[index] : '',
            growable: false,
          ),
        )
        .toList(growable: false);
    widget.onChanged(
      TableBlockDTO(
        id: widget.block.id,
        columnCount: nextColumnCount,
        rows: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${widget.block.rows.length} rows x ${widget.block.columnCount} cols',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
            FilledButton.tonal(
              onPressed: _editShape,
              child: const Text('行 / 列'),
            ),
            FilledButton.tonal(
              onPressed: _appendRow,
              child: const Text('加行'),
            ),
            FilledButton.tonal(
              onPressed: _appendColumn,
              child: const Text('加列'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            children: [
              for (int row = 0; row < widget.block.rows.length; row++)
                Row(
                  children: [
                    for (int col = 0; col < widget.block.columnCount; col++)
                      Container(
                        width: 160,
                        constraints: const BoxConstraints(minHeight: 56),
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                              AppColors.surfacePrimary.withValues(alpha: 0.3),
                          border: Border.all(
                            color:
                                AppColors.surfacePrimary.withValues(alpha: 0.9),
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[row][col],
                          minLines: 1,
                          maxLines: null,
                          onTap: widget.onSelected,
                          onChanged: (value) => _updateCell(row, col, value),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '单元格',
                            isDense: true,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseLibraryLinkPickerSheet extends StatefulWidget {
  const _ExerciseLibraryLinkPickerSheet({
    required this.entries,
    this.initialQuery = '',
  });

  final List<ExerciseEntry> entries;
  final String initialQuery;

  @override
  State<_ExerciseLibraryLinkPickerSheet> createState() =>
      _ExerciseLibraryLinkPickerSheetState();
}

class _ExerciseLibraryLinkPickerSheetState
    extends State<_ExerciseLibraryLinkPickerSheet> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery.trim());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExerciseEntry> get _visibleEntries {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.entries;
    }
    return widget.entries
        .where((entry) => entry.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  String _bestRecordLabel(ExerciseEntry entry) {
    if (entry.records.isEmpty) {
      return '暂无纪录';
    }
    final best = entry.records.map((record) => record.value).reduce(math.max);
    final formatted = best == best.roundToDouble()
        ? best.toStringAsFixed(0)
        : best.toStringAsFixed(1);
    return '最佳 $formatted kg';
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
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
              color: AppColors.brandPrimaryVariant.withValues(alpha: 0.2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '从动作库插入动作',
                    style: AppTypography.bodyBold.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '选择一个已关联动作，会以高亮文本插入，并可跳转到动作库详情页。',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: AppTypography.bodyBase.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '搜索动作',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor:
                          AppColors.surfacePrimary.withValues(alpha: 0.34),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${entries.length} 个结果',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: entries.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Text(
                                '没有匹配的动作。',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.64),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: entries.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.xs),
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return Material(
                                color: AppColors.surfacePrimary
                                    .withValues(alpha: 0.32),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.lg),
                                child: InkWell(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                  onTap: () => Navigator.of(context).pop(entry),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AppColors.brandPrimaryVariant
                                                .withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(
                                                AppRadius.md),
                                          ),
                                          child: const Icon(
                                            Icons.fitness_center_outlined,
                                            size: 18,
                                            color:
                                                AppColors.brandPrimaryVariant,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.md),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                entry.name,
                                                style: AppTypography.bodyBold
                                                    .copyWith(
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                spacing: AppSpacing.xs,
                                                runSpacing: AppSpacing.xs,
                                                children: [
                                                  _DialogInfoChip(
                                                    icon: Icons
                                                        .emoji_events_outlined,
                                                    label:
                                                        _bestRecordLabel(entry),
                                                  ),
                                                  if (entry.tagIds.isNotEmpty)
                                                    _DialogInfoChip(
                                                      icon: Icons.sell_outlined,
                                                      label: entry.tagIds
                                                          .join(' · '),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Icon(
                                          Icons.north_west_rounded,
                                          color: AppColors.textPrimary
                                              .withValues(alpha: 0.35),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
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
}

class _DialogInfoChip extends StatelessWidget {
  const _DialogInfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textPrimary.withValues(alpha: 0.68),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.78),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkEditorDialog extends StatefulWidget {
  const _LinkEditorDialog({
    required this.title,
    required this.confirmLabel,
  });

  final String title;
  final String confirmLabel;

  @override
  State<_LinkEditorDialog> createState() => _LinkEditorDialogState();
}

class _LinkEditorDialogState extends State<_LinkEditorDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '标题'),
            ),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: '链接',
                hintText: 'https://example.com',
              ),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: '备注'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            if (_urlController.text.trim().isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _LinkEditorValue(
                title: _titleController.text,
                url: _urlController.text,
                note: _noteController.text,
              ),
            );
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class _TableShapeDialog extends StatefulWidget {
  const _TableShapeDialog({
    this.initialRows = 3,
    this.initialColumns = 3,
  });

  final int initialRows;
  final int initialColumns;

  @override
  State<_TableShapeDialog> createState() => _TableShapeDialogState();
}

class _TableShapeDialogState extends State<_TableShapeDialog> {
  late int _rows;
  late int _columns;

  @override
  void initState() {
    super.initState();
    _rows = math.max(1, widget.initialRows);
    _columns = math.max(1, widget.initialColumns);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('表格大小'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CounterRow(
            label: '行',
            value: _rows,
            onChanged: (value) => setState(() => _rows = math.max(1, value)),
          ),
          const SizedBox(height: 12),
          _CounterRow(
            label: '列',
            value: _columns,
            onChanged: (value) => setState(() => _columns = math.max(1, value)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _TableShapeValue(rows: _rows, columns: _columns),
            );
          },
          child: const Text('应用'),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value <= 1 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style:
                AppTypography.bodyBold.copyWith(color: AppColors.textPrimary),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _LinkEditorValue {
  const _LinkEditorValue({
    required this.title,
    required this.url,
    required this.note,
  });

  final String title;
  final String url;
  final String note;
}

class _TableShapeValue {
  const _TableShapeValue({
    required this.rows,
    required this.columns,
  });

  final int rows;
  final int columns;
}

bool _isFileReference(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) {
    return uri.scheme == 'file';
  }
  return trimmed.contains('\\') || trimmed.startsWith('/');
}
