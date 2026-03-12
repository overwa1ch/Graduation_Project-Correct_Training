import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiwa_app/ui/widgets/aiwa_editor_block_operations.dart';

class AiwaAttachmentBlockKeys {
  AiwaAttachmentBlockKeys._();

  static const String type = 'aiwa_attachment';
  static const String label = 'label';
  static const String href = 'href';
  static const String note = 'note';
  static const String blockType = 'block_type';
  static const String payloadJson = 'payload_json';
}

Node aiwaAttachmentNode({
  required String label,
  required String href,
  String? note,
  String? blockType,
  String? payloadJson,
}) {
  return Node(
    type: AiwaAttachmentBlockKeys.type,
    attributes: <String, Object?>{
      AiwaAttachmentBlockKeys.label: label,
      AiwaAttachmentBlockKeys.href: href,
      if (note != null && note.trim().isNotEmpty)
        AiwaAttachmentBlockKeys.note: note.trim(),
      if (blockType != null && blockType.trim().isNotEmpty)
        AiwaAttachmentBlockKeys.blockType: blockType.trim(),
      if (payloadJson != null && payloadJson.trim().isNotEmpty)
        AiwaAttachmentBlockKeys.payloadJson: payloadJson.trim(),
    },
  );
}

class AiwaAttachmentBlockComponentBuilder extends BlockComponentBuilder {
  AiwaAttachmentBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AiwaAttachmentBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class AiwaAttachmentBlockComponentWidget extends BlockComponentStatefulWidget {
  const AiwaAttachmentBlockComponentWidget({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<AiwaAttachmentBlockComponentWidget> createState() =>
      _AiwaAttachmentBlockComponentWidgetState();
}

class _AiwaAttachmentBlockComponentWidgetState
    extends State<AiwaAttachmentBlockComponentWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final GlobalKey _contentKey = GlobalKey(debugLabel: 'aiwa_attachment');
  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  late final EditorState editorState = Provider.of<EditorState>(
    context,
    listen: false,
  );

  @override
  Widget build(BuildContext context) {
    final label =
        node.attributes[AiwaAttachmentBlockKeys.label] as String? ?? '附件';
    final href = node.attributes[AiwaAttachmentBlockKeys.href] as String? ?? '';
    final note = node.attributes[AiwaAttachmentBlockKeys.note] as String?;
    final blockType =
        node.attributes[AiwaAttachmentBlockKeys.blockType] as String?;
    final color = editorState.editorStyle.cursorColor;

    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => selectAiwaBlockNode(editorState, node),
      child: Padding(
        key: _contentKey,
        padding: padding,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.24),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _resolveIcon(label, href, blockType),
                          color: color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _displayLabel(label, href, blockType),
                            style: textStyleWithTextSpan().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '编辑附件',
                          onPressed: _showEditSheet,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          tooltip: '删除附件',
                          onPressed: _deleteBlock,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        style: textStyleWithTextSpan().copyWith(
                          fontSize: 13,
                          color: textStyleWithTextSpan()
                              .color
                              ?.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    child = BlockSelectionContainer(
      node: node,
      delegate: this,
      listenable: editorState.selectionNotifier,
      remoteSelection: editorState.remoteSelections,
      blockColor: editorState.editorStyle.selectionColor,
      supportTypes: const [
        BlockSelectionType.block,
      ],
      child: child,
    );

    return child;
  }

  IconData _resolveIcon(String label, String href, String? blockType) {
    switch (blockType) {
      case 'exercise_block':
        return Icons.fitness_center_outlined;
      case 'reference_block':
        return Icons.bookmark_outline;
      case 'timer_marker_block':
        return Icons.timer_outlined;
    }

    final value = '$label $href'.toLowerCase();
    if (value.endsWith('.pdf') || value.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.contains('video')) {
      return Icons.movie_outlined;
    }
    if (value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    return Icons.attach_file_outlined;
  }

  String _displayLabel(String label, String href, String? blockType) {
    final trimmed = label.trim();
    final generic = _genericLabel(href, blockType);
    if (trimmed.isEmpty) {
      return generic;
    }

    final lower = trimmed.toLowerCase();
    final looksLikePath = lower.contains(r'\') ||
        lower.contains('/') ||
        lower.startsWith('file:');
    final looksLikeFileName = RegExp(
      r'\.(pdf|png|jpe?g|webp|gif|mp4|mov|avi|zip|rar|7z|docx?|xlsx?|pptx?|txt)$',
      caseSensitive: false,
    ).hasMatch(trimmed);

    if (looksLikePath || looksLikeFileName) {
      return generic;
    }
    return trimmed;
  }

  String _genericLabel(String href, String? blockType) {
    switch (blockType) {
      case 'exercise_block':
        return 'Exercise';
      case 'reference_block':
        return 'Reference';
      case 'timer_marker_block':
        return 'Timer';
    }

    final value = href.toLowerCase();
    if (value.endsWith('.pdf') || value.contains('pdf')) {
      return 'PDF';
    }
    if (value.endsWith('.mp4') ||
        value.endsWith('.mov') ||
        value.endsWith('.avi') ||
        value.contains('video')) {
      return 'Video';
    }
    if (value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.webp') ||
        value.endsWith('.gif')) {
      return 'Image';
    }
    return 'Attachment';
  }

  void _deleteBlock() {
    deleteAiwaBlockNode(editorState, node);
  }

  Future<void> _showEditSheet() async {
    final label = node.attributes[AiwaAttachmentBlockKeys.label] as String? ??
        'Attachment';
    final href = node.attributes[AiwaAttachmentBlockKeys.href] as String? ?? '';
    final note = node.attributes[AiwaAttachmentBlockKeys.note] as String?;
    final blockType =
        node.attributes[AiwaAttachmentBlockKeys.blockType] as String?;
    final payloadJson =
        node.attributes[AiwaAttachmentBlockKeys.payloadJson] as String?;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _AttachmentEditorSheet(
          initialLabel: label,
          initialHref: href,
          initialNote: note,
          onSave: (nextLabel, nextHref, nextNote) {
            final transaction = editorState.transaction
              ..updateNode(node, <String, Object?>{
                AiwaAttachmentBlockKeys.label: nextLabel,
                AiwaAttachmentBlockKeys.href: nextHref,
                if (nextNote != null && nextNote.isNotEmpty)
                  AiwaAttachmentBlockKeys.note: nextNote,
                if (blockType != null)
                  AiwaAttachmentBlockKeys.blockType: blockType,
                if (payloadJson != null)
                  AiwaAttachmentBlockKeys.payloadJson: payloadJson,
              });
            editorState.apply(transaction);
            restoreAiwaEditorKeyboard(editorState);
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    final contentBox = _contentKey.currentContext?.findRenderObject();
    if (contentBox is RenderBox) {
      return Offset.zero & contentBox.size;
    }
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return null;
    }
    final size = _renderBox!.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final parentBox = context.findRenderObject();
    final contentBox = _contentKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && contentBox is RenderBox) {
      return [
        contentBox.localToGlobal(Offset.zero, ancestor: parentBox) &
            contentBox.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) =>
      _renderBox!.localToGlobal(offset);
}

class _AttachmentEditorSheet extends StatefulWidget {
  const _AttachmentEditorSheet({
    required this.initialLabel,
    required this.initialHref,
    required this.initialNote,
    required this.onSave,
  });

  final String initialLabel;
  final String initialHref;
  final String? initialNote;
  final void Function(String label, String href, String? note) onSave;

  @override
  State<_AttachmentEditorSheet> createState() => _AttachmentEditorSheetState();
}

class _AttachmentEditorSheetState extends State<_AttachmentEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _hrefController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _hrefController = TextEditingController(text: widget.initialHref);
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _labelController.dispose();
    _hrefController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '编辑附件',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: '标题'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hrefController,
            decoration: const InputDecoration(labelText: '路径或链接'),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: '备注'),
            minLines: 1,
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final href = _hrefController.text.trim();
              final label = _labelController.text.trim();
              if (href.isEmpty || label.isEmpty) {
                return;
              }
              final note = _noteController.text.trim();
              widget.onSave(label, href, note.isEmpty ? null : note);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
