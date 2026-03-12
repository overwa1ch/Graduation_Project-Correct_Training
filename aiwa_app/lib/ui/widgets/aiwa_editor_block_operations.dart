import 'package:appflowy_editor/appflowy_editor.dart';

Node? resolveAiwaTopLevelBlockNode(EditorState editorState, Path path) {
  Node? node = editorState.getNodeAtPath(path);
  while (node != null &&
      node.parent != null &&
      node.parent!.type != PageBlockKeys.type) {
    node = node.parent;
  }
  return node;
}

bool isAiwaEmptyParagraphNode(Node node) {
  return node.type == ParagraphBlockKeys.type &&
      (node.delta?.isEmpty ?? false) &&
      node.children.isEmpty;
}

void restoreAiwaEditorKeyboard(EditorState editorState) {
  final selection = editorState.selection;
  if (selection != null) {
    editorState.service.keyboardService?.enableKeyBoard(selection);
  }
}

Future<void> selectAiwaBlockNode(EditorState editorState, Node node) {
  final topLevelNode = resolveAiwaTopLevelBlockNode(editorState, node.path);
  if (topLevelNode == null) {
    return Future<void>.value();
  }

  return editorState
      .updateSelectionWithReason(
        Selection.single(
          path: topLevelNode.path,
          startOffset: 0,
          endOffset: 1,
        ),
        reason: SelectionUpdateReason.uiEvent,
        customSelectionType: SelectionType.block,
      )
      .then((_) => editorState.service.keyboardService?.enable());
}

void deleteAiwaBlockNode(EditorState editorState, Node node) {
  final topLevelNode = resolveAiwaTopLevelBlockNode(editorState, node.path);
  if (topLevelNode == null || topLevelNode.type == PageBlockKeys.type) {
    return;
  }

  final transaction = editorState.transaction;
  final previous = topLevelNode.previous;
  final next = topLevelNode.next;

  if (editorState.document.root.children.length == 1) {
    transaction.insertNode(topLevelNode.path, paragraphNode());
  }

  transaction.deleteNode(topLevelNode);

  final selectionNode =
      next ?? previous ?? editorState.document.root.children.first;
  transaction.afterSelection = Selection.collapsed(
    Position(path: selectionNode.path, offset: 0),
  );

  editorState.apply(transaction);
  restoreAiwaEditorKeyboard(editorState);
}
