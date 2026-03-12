import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiwa_app/ui/widgets/aiwa_editor_block_operations.dart';

Widget wrapAiwaDividerBlock(
  BuildContext context,
  Node node,
  Widget child,
) {
  final editorState = context.read<EditorState>();

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => selectAiwaBlockNode(editorState, node),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: '删除分割线',
              onPressed: () => deleteAiwaBlockNode(editorState, node),
              icon: const Icon(Icons.delete_outline, size: 18),
              visualDensity: VisualDensity.compact,
            ),
          ),
          child,
        ],
      ),
    ),
  );
}
