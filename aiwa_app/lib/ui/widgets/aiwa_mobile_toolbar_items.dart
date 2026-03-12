import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:aiwa_app/ui/widgets/aiwa_attachment_block_component.dart';
import 'package:aiwa_app/ui/widgets/aiwa_editor_block_operations.dart';
import 'package:aiwa_app/ui/widgets/aiwa_editor_table_actions.dart';

List<MobileToolbarItem> buildAiwaMobileToolbarItems() {
  return <MobileToolbarItem>[
    textDecorationMobileToolbarItemV2,
    buildTextAndBackgroundColorMobileToolbarItem(),
    _fontSizeToolbarItem(),
    _blockToolbarItem(),
    _insertToolbarItem(),
  ];
}

MobileToolbarItem _fontSizeToolbarItem() {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, __, ___) => Icon(
      Icons.format_size,
      color: MobileToolbarTheme.of(context).iconColor,
    ),
    itemMenuBuilder: (_, editorState, itemMenuService) {
      final selection = editorState.selection;
      if (selection == null) {
        return const SizedBox.shrink();
      }

      return _FontSizeMenu(
        editorState: editorState,
        selection: selection,
        onDone: itemMenuService.closeItemMenu,
      );
    },
  );
}

MobileToolbarItem _blockToolbarItem() {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, __, ___) => Icon(
      Icons.segment_outlined,
      color: MobileToolbarTheme.of(context).iconColor,
    ),
    itemMenuBuilder: (_, editorState, itemMenuService) {
      final selection = editorState.selection;
      if (selection == null) {
        return const SizedBox.shrink();
      }

      return _BlockMenu(
        editorState: editorState,
        selection: selection,
        onDone: itemMenuService.closeItemMenu,
      );
    },
  );
}

MobileToolbarItem _insertToolbarItem() {
  return MobileToolbarItem.withMenu(
    itemIconBuilder: (context, __, ___) => Icon(
      Icons.add_box_outlined,
      color: MobileToolbarTheme.of(context).iconColor,
    ),
    itemMenuBuilder: (context, editorState, itemMenuService) {
      final selection = editorState.selection;
      if (selection == null) {
        return const SizedBox.shrink();
      }

      return _InsertMenu(
        editorState: editorState,
        selection: selection,
        onDone: itemMenuService.closeItemMenu,
      );
    },
  );
}

class _ToolbarInsertionTarget {
  const _ToolbarInsertionTarget(this.selection);

  final Selection selection;
}

_ToolbarInsertionTarget? _captureInsertionTarget(Selection selection) {
  final normalized = selection.normalized;
  if (!normalized.isCollapsed) {
    return null;
  }
  return _ToolbarInsertionTarget(normalized);
}

void _insertBlockAtTarget(
  EditorState editorState,
  _ToolbarInsertionTarget target,
  Node insertedNode, {
  bool ensureTrailingParagraph = true,
}) {
  final anchor = resolveAiwaTopLevelBlockNode(
    editorState,
    target.selection.end.path,
  );
  if (anchor == null) {
    return;
  }

  final replaceEmptyParagraph = isAiwaEmptyParagraphNode(anchor);
  final originalNext = anchor.next;
  final insertedPath = replaceEmptyParagraph ? anchor.path : anchor.path.next;

  final transaction = editorState.transaction;
  if (replaceEmptyParagraph) {
    transaction
      ..insertNode(insertedPath, insertedNode)
      ..deleteNode(anchor);
  } else {
    transaction.insertNode(insertedPath, insertedNode);
  }

  final needsTrailingParagraph = ensureTrailingParagraph &&
      insertedNode.type != ParagraphBlockKeys.type &&
      (originalNext == null ||
          originalNext.type != ParagraphBlockKeys.type ||
          originalNext.delta?.isNotEmpty == true);

  if (needsTrailingParagraph) {
    transaction.insertNode(insertedPath.next, paragraphNode());
  }

  final selectionPath = insertedNode.type == ParagraphBlockKeys.type
      ? insertedPath
      : insertedPath.next;
  transaction.afterSelection = Selection.collapsed(
    Position(path: selectionPath, offset: 0),
  );

  editorState.apply(transaction);
  restoreAiwaEditorKeyboard(editorState);
}

void _insertLink(
  EditorState editorState,
  Selection selection,
  _LinkSubmission link,
) {
  final normalized = selection.normalized;
  if (!normalized.isCollapsed) {
    editorState.formatDelta(
      normalized,
      {AppFlowyRichTextKeys.href: link.href},
    );
    restoreAiwaEditorKeyboard(editorState);
    return;
  }

  final target = _captureInsertionTarget(normalized);
  if (target == null) {
    return;
  }

  final label = link.label.trim().isEmpty ? link.href : link.label.trim();
  _insertBlockAtTarget(
    editorState,
    target,
    paragraphNode(
      delta: Delta()
        ..insert(
          label,
          attributes: <String, Object?>{
            AppFlowyRichTextKeys.href: link.href,
          },
        ),
    ),
    ensureTrailingParagraph: false,
  );
}

void _formatNode(
  EditorState editorState,
  Selection selection, {
  required String type,
  Map<String, Object?> attributes = const <String, Object?>{},
}) {
  editorState.formatNode(
    selection.normalized,
    (node) => node.copyWith(
      type: type,
      attributes: <String, Object?>{
        ParagraphBlockKeys.delta: (node.delta ?? Delta()).toJson(),
        blockComponentBackgroundColor:
            node.attributes[blockComponentBackgroundColor],
        ...attributes,
      },
    ),
    selectionExtraInfo: const <String, Object?>{
      selectionExtraInfoDoNotAttachTextService: true,
    },
  );
}

class _BlockMenu extends StatelessWidget {
  const _BlockMenu({
    required this.editorState,
    required this.selection,
    required this.onDone,
  });

  final EditorState editorState;
  final Selection selection;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final node = editorState.getNodeAtPath(selection.start.path);

    return _ToolbarActionGrid(
      actions: <_ToolbarMenuAction>[
        _ToolbarMenuAction(
          icon: Icons.subject_outlined,
          label: '正文',
          isSelected: node?.type == ParagraphBlockKeys.type,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: ParagraphBlockKeys.type,
            );
            onDone();
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.looks_one_outlined,
          label: '标题 1',
          isSelected: node?.type == HeadingBlockKeys.type &&
              node?.attributes[HeadingBlockKeys.level] == 1,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: HeadingBlockKeys.type,
              attributes: <String, Object?>{HeadingBlockKeys.level: 1},
            );
            onDone();
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.looks_two_outlined,
          label: '标题 2',
          isSelected: node?.type == HeadingBlockKeys.type &&
              node?.attributes[HeadingBlockKeys.level] == 2,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: HeadingBlockKeys.type,
              attributes: <String, Object?>{HeadingBlockKeys.level: 2},
            );
            onDone();
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.looks_3_outlined,
          label: '标题 3',
          isSelected: node?.type == HeadingBlockKeys.type &&
              node?.attributes[HeadingBlockKeys.level] == 3,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: HeadingBlockKeys.type,
              attributes: <String, Object?>{HeadingBlockKeys.level: 3},
            );
            onDone();
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.format_list_bulleted,
          label: '无序列表',
          isSelected: node?.type == BulletedListBlockKeys.type,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: BulletedListBlockKeys.type,
            );
            onDone();
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.format_list_numbered,
          label: '有序列表',
          isSelected: node?.type == NumberedListBlockKeys.type,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: NumberedListBlockKeys.type,
            );
            onDone();
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.checklist_rtl,
          label: '待办',
          isSelected: node?.type == TodoListBlockKeys.type,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: TodoListBlockKeys.type,
              attributes: <String, Object?>{TodoListBlockKeys.checked: false},
            );
            onDone();
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.format_quote_outlined,
          label: '引用',
          isSelected: node?.type == QuoteBlockKeys.type,
          onPressed: () {
            _formatNode(
              editorState,
              selection,
              type: QuoteBlockKeys.type,
            );
            onDone();
          },
        ),
      ],
    );
  }
}

class _InsertMenu extends StatelessWidget {
  const _InsertMenu({
    required this.editorState,
    required this.selection,
    required this.onDone,
  });

  final EditorState editorState;
  final Selection selection;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final insertionTarget = _captureInsertionTarget(selection);

    return _ToolbarActionGrid(
      actions: <_ToolbarMenuAction>[
        _ToolbarMenuAction(
          icon: Icons.link_outlined,
          label: selection.isCollapsed ? '插入链接' : '给选中文本加链接',
          onPressed: () {
            onDone();
            _showSheet(
              context,
              child: _LinkSheet(
                onSubmitted: (link) {
                  _insertLink(editorState, selection, link);
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        ),
        _ToolbarMenuAction(
          icon: Icons.horizontal_rule,
          label: '插入分隔线',
          isEnabled: insertionTarget != null,
          onPressed: insertionTarget == null
              ? null
              : () {
                  _insertBlockAtTarget(
                      editorState, insertionTarget, dividerNode());
                  onDone();
                },
        ),
        _ToolbarMenuAction(
          icon: Icons.image_outlined,
          label: '插入图片',
          isEnabled: insertionTarget != null,
          onPressed: insertionTarget == null
              ? null
              : () {
                  onDone();
                  _showSheet(
                    context,
                    child: _ImageSheet(
                      onSubmitted: (image) {
                        _insertBlockAtTarget(
                          editorState,
                          insertionTarget,
                          imageNode(url: image.src),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
        ),
        _ToolbarMenuAction(
          icon: Icons.attach_file_outlined,
          label: '插入附件',
          isEnabled: insertionTarget != null,
          onPressed: insertionTarget == null
              ? null
              : () {
                  onDone();
                  _showSheet(
                    context,
                    child: _AttachmentSheet(
                      onSubmitted: (attachment) {
                        _insertBlockAtTarget(
                          editorState,
                          insertionTarget,
                          aiwaAttachmentNode(
                            label: attachment.label,
                            href: attachment.href,
                            note: attachment.note,
                          ),
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
        ),
        _ToolbarMenuAction(
          icon: Icons.table_chart_outlined,
          label: '插入表格',
          isEnabled: insertionTarget != null,
          onPressed: insertionTarget == null
              ? null
              : () {
                  onDone();
                  _showSheet(
                    context,
                    child: _TableSheet(
                      onSubmitted: (rows, cols) {
                        final anchor = resolveAiwaTopLevelBlockNode(
                          editorState,
                          insertionTarget.selection.end.path,
                        );
                        if (anchor == null) {
                          return;
                        }

                        final replaceEmptyParagraph =
                            isAiwaEmptyParagraphNode(anchor);
                        final insertPath = replaceEmptyParagraph
                            ? anchor.path
                            : anchor.path.next;

                        if (replaceEmptyParagraph) {
                          final cleanup = editorState.transaction
                            ..deleteNode(anchor);
                          editorState.apply(cleanup,
                              withUpdateSelection: false);
                        }

                        insertAiwaTableAtPath(
                          editorState,
                          insertPath,
                          rows: rows,
                          cols: cols,
                        );
                        restoreAiwaEditorKeyboard(editorState);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
        ),
      ],
    );
  }
}

void _showSheet(
  BuildContext context, {
  required Widget child,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 12,
        ),
        child: child,
      );
    },
  );
}

class _ToolbarActionGrid extends StatelessWidget {
  const _ToolbarActionGrid({
    required this.actions,
  });

  final List<_ToolbarMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    final style = MobileToolbarTheme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.all(style.buttonSpacing),
      itemCount: actions.length,
      gridDelegate: buildMobileToolbarMenuGridDelegate(
        mobileToolbarStyle: style,
        crossAxisCount: 2,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return MobileToolbarItemMenuBtn(
          icon: Icon(
            action.icon,
            color: action.isEnabled
                ? style.iconColor
                : style.iconColor.withValues(alpha: 0.35),
          ),
          label: Text(
            action.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          isSelected: action.isSelected,
          onPressed: action.isEnabled ? () => action.onPressed?.call() : () {},
        );
      },
    );
  }
}

class _ToolbarMenuAction {
  const _ToolbarMenuAction({
    required this.icon,
    required this.label,
    this.isSelected = false,
    this.isEnabled = true,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback? onPressed;
}

class _FontSizeMenu extends StatefulWidget {
  const _FontSizeMenu({
    required this.editorState,
    required this.selection,
    required this.onDone,
  });

  final EditorState editorState;
  final Selection selection;
  final VoidCallback onDone;

  @override
  State<_FontSizeMenu> createState() => _FontSizeMenuState();
}

class _FontSizeMenuState extends State<_FontSizeMenu> {
  static const List<double> _sizes = <double>[14, 16, 18, 20, 24];

  @override
  Widget build(BuildContext context) {
    final style = MobileToolbarTheme.of(context);
    final selection = widget.selection.normalized;
    final currentSize =
        widget.editorState.getDeltaAttributeValueInSelection<double>(
      AppFlowyRichTextKeys.fontSize,
      selection,
    );

    if (selection.isCollapsed) {
      return Padding(
        padding: EdgeInsets.all(style.buttonSpacing),
        child: Text(
          '请先选中文本再调整字号。',
          style: TextStyle(color: style.foregroundColor),
        ),
      );
    }

    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.all(style.buttonSpacing),
      gridDelegate: buildMobileToolbarMenuGridDelegate(
        mobileToolbarStyle: style,
        crossAxisCount: 3,
      ),
      children: [
        MobileToolbarItemMenuBtn(
          icon: Icon(Icons.format_size, color: style.iconColor),
          label: const Text('默认'),
          isSelected: currentSize == null,
          onPressed: () {
            widget.editorState.formatDelta(
              selection,
              <String, Object?>{AppFlowyRichTextKeys.fontSize: null},
            );
            widget.onDone();
          },
        ),
        ..._sizes.map((size) {
          return MobileToolbarItemMenuBtn(
            icon: Icon(Icons.text_fields, color: style.iconColor),
            label: Text(size.toInt().toString()),
            isSelected: currentSize == size,
            onPressed: () {
              widget.editorState.formatDelta(
                selection,
                <String, Object?>{AppFlowyRichTextKeys.fontSize: size},
              );
              widget.onDone();
            },
          );
        }),
      ],
    );
  }
}

class _AttachmentSubmission {
  const _AttachmentSubmission({
    required this.label,
    required this.href,
    this.note,
  });

  final String label;
  final String href;
  final String? note;
}

class _LinkSubmission {
  const _LinkSubmission({
    required this.label,
    required this.href,
  });

  final String label;
  final String href;
}

class _ImageSubmission {
  const _ImageSubmission({
    required this.src,
  });

  final String src;
}

class _AttachmentSheet extends StatefulWidget {
  const _AttachmentSheet({
    required this.onSubmitted,
  });

  final ValueChanged<_AttachmentSubmission> onSubmitted;

  @override
  State<_AttachmentSheet> createState() => _AttachmentSheetState();
}

class _AttachmentSheetState extends State<_AttachmentSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _hrefController;
  late final TextEditingController _noteController;
  bool _isPickingFile = false;
  String? _pickedFilePath;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _hrefController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hrefController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final href = _pickedFilePath ?? _hrefController.text.trim();
    if (href.isEmpty) {
      return;
    }

    final label = _labelController.text.trim().isEmpty
        ? '附件'
        : _labelController.text.trim();

    widget.onSubmitted(
      _AttachmentSubmission(
        label: label,
        href: href,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  Future<void> _pickFile() async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles();
      final file = result?.files.firstOrNull;
      if (!mounted || file == null || file.path == null) {
        return;
      }

      _pickedFilePath = file.path!;
      if (_labelController.text.trim().isEmpty) {
        _labelController.text = '附件';
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      title: '插入附件',
      onSubmit: _submit,
      submitText: '插入',
      children: [
        TextField(
          controller: _labelController,
          decoration: const InputDecoration(labelText: '标题'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        if (_pickedFilePath == null) ...[
          TextField(
            controller: _hrefController,
            decoration: const InputDecoration(labelText: '链接'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.attach_file_outlined, size: 18),
                SizedBox(width: 8),
                Text('已选择文件'),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isPickingFile ? null : _pickFile,
            icon: _isPickingFile
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open_outlined),
            label: const Text('选择文件'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(labelText: '备注'),
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

class _LinkSheet extends StatefulWidget {
  const _LinkSheet({
    required this.onSubmitted,
  });

  final ValueChanged<_LinkSubmission> onSubmitted;

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _hrefController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController();
    _hrefController = TextEditingController();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hrefController.dispose();
    super.dispose();
  }

  void _submit() {
    final href = _hrefController.text.trim();
    if (href.isEmpty) {
      return;
    }

    widget.onSubmitted(
      _LinkSubmission(
        label: _labelController.text.trim(),
        href: href,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      title: '插入链接',
      onSubmit: _submit,
      submitText: '插入',
      children: [
        TextField(
          controller: _labelController,
          decoration: const InputDecoration(labelText: '标题'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hrefController,
          decoration: const InputDecoration(labelText: '链接'),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}

class _ImageSheet extends StatefulWidget {
  const _ImageSheet({
    required this.onSubmitted,
  });

  final ValueChanged<_ImageSubmission> onSubmitted;

  @override
  State<_ImageSheet> createState() => _ImageSheetState();
}

class _ImageSheetState extends State<_ImageSheet> {
  late final TextEditingController _srcController;
  bool _isPickingImage = false;
  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    _srcController = TextEditingController();
  }

  @override
  void dispose() {
    _srcController.dispose();
    super.dispose();
  }

  void _submit() {
    final src = _pickedImagePath ?? _srcController.text.trim();
    if (src.isEmpty) {
      return;
    }

    widget.onSubmitted(_ImageSubmission(src: src));
  }

  Future<void> _pickImage() async {
    setState(() => _isPickingImage = true);
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      final file = result?.files.firstOrNull;
      if (!mounted || file == null || file.path == null) {
        return;
      }

      _pickedImagePath = file.path!;
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      title: '插入图片',
      onSubmit: _submit,
      submitText: '插入',
      children: [
        if (_pickedImagePath == null) ...[
          TextField(
            controller: _srcController,
            decoration: const InputDecoration(labelText: '图片链接'),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.image_outlined, size: 18),
                SizedBox(width: 8),
                Text('已选择图片'),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _isPickingImage ? null : _pickImage,
            icon: _isPickingImage
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
            label: const Text('选择图片'),
          ),
        ),
      ],
    );
  }
}

class _TableSheet extends StatefulWidget {
  const _TableSheet({
    required this.onSubmitted,
  });

  final void Function(int rows, int cols) onSubmitted;

  @override
  State<_TableSheet> createState() => _TableSheetState();
}

class _TableSheetState extends State<_TableSheet> {
  int _rows = 3;
  int _cols = 3;

  @override
  Widget build(BuildContext context) {
    return _SheetCard(
      title: '插入表格',
      onSubmit: () => widget.onSubmitted(_rows, _cols),
      submitText: '插入',
      children: [
        _StepperRow(
          label: '行',
          value: _rows,
          onChanged: (value) => setState(() => _rows = value),
        ),
        const SizedBox(height: 12),
        _StepperRow(
          label: '列',
          value: _cols,
          onChanged: (value) => setState(() => _cols = value),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
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
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(value.toString()),
        IconButton(
          onPressed: value < 12 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({
    required this.title,
    required this.children,
    this.onSubmit,
    this.submitText,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onSubmit;
  final String? submitText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ...children,
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      if (onSubmit != null && submitText != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: onSubmit,
                            child: Text(submitText!),
                          ),
                        ),
                      ],
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
