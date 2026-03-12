import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiwa_app/ui/widgets/aiwa_editor_block_operations.dart';

class AiwaImageBlockComponentBuilder extends BlockComponentBuilder {
  AiwaImageBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AiwaImageBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.delta == null && node.children.isEmpty;
}

class AiwaImageBlockComponentWidget extends BlockComponentStatefulWidget {
  const AiwaImageBlockComponentWidget({
    super.key,
    required super.node,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<AiwaImageBlockComponentWidget> createState() =>
      _AiwaImageBlockComponentWidgetState();
}

class _AiwaImageBlockComponentWidgetState
    extends State<AiwaImageBlockComponentWidget> {
  late final EditorState _editorState = context.read<EditorState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => selectAiwaBlockNode(_editorState, widget.node),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Stack(
          children: [
            ImageBlockComponentWidget(
              node: widget.node,
              configuration: widget.configuration,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(999),
                child: IconButton(
                  tooltip: '删除图片',
                  onPressed: () =>
                      deleteAiwaBlockNode(_editorState, widget.node),
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
