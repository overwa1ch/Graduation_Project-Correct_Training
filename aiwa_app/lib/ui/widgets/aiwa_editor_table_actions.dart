import 'package:appflowy_editor/appflowy_editor.dart';

class AiwaTableSelectionContext {
  const AiwaTableSelectionContext({
    required this.tableNode,
    required this.cellNode,
    required this.row,
    required this.col,
  });

  final Node tableNode;
  final Node cellNode;
  final int row;
  final int col;
}

Node? findTableCellNode(Node tableNode, int col, int row) {
  for (final child in tableNode.children) {
    if (child.attributes[TableCellBlockKeys.colPosition] == col &&
        child.attributes[TableCellBlockKeys.rowPosition] == row) {
      return child;
    }
  }
  return null;
}

AiwaTableSelectionContext? resolveAiwaTableSelectionContext(
  EditorState editorState,
  Selection? selection,
) {
  final normalized = selection?.normalized;
  if (normalized == null) {
    return null;
  }

  Node? tableNode;
  Node? cellNode;
  Path currentPath = normalized.start.path;

  while (currentPath.isNotEmpty) {
    final node = editorState.getNodeAtPath(currentPath);
    if (node == null) {
      break;
    }
    if (cellNode == null && node.type == TableCellBlockKeys.type) {
      cellNode = node;
    }
    if (node.type == TableBlockKeys.type) {
      tableNode = node;
      break;
    }
    currentPath = currentPath.parent;
  }

  if (tableNode == null || cellNode == null) {
    return null;
  }

  return AiwaTableSelectionContext(
    tableNode: tableNode,
    cellNode: cellNode,
    row: cellNode.attributes[TableCellBlockKeys.rowPosition] as int? ?? 0,
    col: cellNode.attributes[TableCellBlockKeys.colPosition] as int? ?? 0,
  );
}

void insertAiwaTableAtPath(
  EditorState editorState,
  Path path, {
  required int rows,
  required int cols,
}) {
  final safeRows = rows < 1 ? 1 : rows;
  final safeCols = cols < 1 ? 1 : cols;
  final table = TableNode.fromList<String>(
    List.generate(
      safeCols,
      (_) => List<String>.filled(safeRows, ''),
    ),
  );

  final transaction = editorState.transaction
    ..insertNode(path, table.node)
    ..insertNode(path.next, paragraphNode());

  transaction.afterSelection = Selection.collapsed(
    Position(
      path: path.child(0).child(0),
      offset: 0,
    ),
  );

  editorState.apply(transaction);
}

void deleteAiwaTable(EditorState editorState, Node tableNode) {
  final transaction = editorState.transaction;
  final previous = tableNode.previous;
  final next = tableNode.next;
  if (editorState.document.root.children.length == 1) {
    transaction.insertNode(tableNode.path, paragraphNode());
  }
  transaction.deleteNode(tableNode);
  final selectionNode =
      next ?? previous ?? editorState.document.root.children.first;
  transaction.afterSelection = Selection.collapsed(
    Position(path: selectionNode.path, offset: 0),
  );
  tableNode.dispose();
  editorState.apply(transaction);
}

void addAiwaTableRow(
  EditorState editorState,
  Node tableNode,
  int row,
) {
  final rowsLen = tableNode.attributes[TableBlockKeys.rowsLen] as int? ?? 0;
  final colsLen = tableNode.attributes[TableBlockKeys.colsLen] as int? ?? 0;
  final insertAt = row.clamp(0, rowsLen);

  for (var col = 0; col < colsLen; col++) {
    final firstCellInCol = findTableCellNode(tableNode, col, 0);
    final colBgColor =
        firstCellInCol?.attributes[TableCellBlockKeys.colBackgroundColor];
    final node = Node(
      type: TableCellBlockKeys.type,
      attributes: {
        TableCellBlockKeys.colPosition: col,
        TableCellBlockKeys.rowPosition: insertAt,
        if (colBgColor != null)
          TableCellBlockKeys.colBackgroundColor: colBgColor,
      },
      children: [paragraphNode()],
    );

    final transaction = editorState.transaction;
    if (insertAt != rowsLen) {
      for (var currentRow = insertAt; currentRow < rowsLen; currentRow++) {
        final cellNode = findTableCellNode(tableNode, col, currentRow);
        if (cellNode != null) {
          transaction.updateNode(
            cellNode,
            {
              TableCellBlockKeys.rowPosition: currentRow + 1,
            },
          );
        }
      }
    }

    final insertPath = insertAt == 0
        ? findTableCellNode(tableNode, col, 0)!.path
        : findTableCellNode(tableNode, col, insertAt - 1)!.path.next;
    transaction.insertNode(insertPath, node);
    editorState.apply(transaction, withUpdateSelection: false);
  }

  final transaction = editorState.transaction
    ..updateNode(tableNode, {TableBlockKeys.rowsLen: rowsLen + 1});
  editorState.apply(transaction, withUpdateSelection: false);
}

void removeAiwaTableRow(
  EditorState editorState,
  Node tableNode,
  int row,
) {
  final rowsLen = tableNode.attributes[TableBlockKeys.rowsLen] as int? ?? 0;
  final colsLen = tableNode.attributes[TableBlockKeys.colsLen] as int? ?? 0;
  if (rowsLen <= 1) {
    deleteAiwaTable(editorState, tableNode);
    return;
  }

  final transaction = editorState.transaction;
  final nodes = <Node>[];
  for (var col = 0; col < colsLen; col++) {
    final cell = findTableCellNode(tableNode, col, row);
    if (cell != null) {
      nodes.add(cell);
    }
  }
  transaction.deleteNodes(nodes);
  for (var col = 0; col < colsLen; col++) {
    for (var currentRow = row + 1; currentRow < rowsLen; currentRow++) {
      final cell = findTableCellNode(tableNode, col, currentRow);
      if (cell != null) {
        transaction.updateNode(
          cell,
          {TableCellBlockKeys.rowPosition: currentRow - 1},
        );
      }
    }
  }
  transaction.updateNode(tableNode, {TableBlockKeys.rowsLen: rowsLen - 1});
  editorState.apply(transaction, withUpdateSelection: false);
}

void addAiwaTableColumn(
  EditorState editorState,
  Node tableNode,
  int col,
) {
  final rowsLen = tableNode.attributes[TableBlockKeys.rowsLen] as int? ?? 0;
  final colsLen = tableNode.attributes[TableBlockKeys.colsLen] as int? ?? 0;
  final insertAt = col.clamp(0, colsLen);

  final transaction = editorState.transaction;
  if (insertAt != colsLen) {
    for (var currentCol = insertAt; currentCol < colsLen; currentCol++) {
      for (var row = 0; row < rowsLen; row++) {
        final node = findTableCellNode(tableNode, currentCol, row);
        if (node != null) {
          transaction.updateNode(
            node,
            {TableCellBlockKeys.colPosition: currentCol + 1},
          );
        }
      }
    }
  }

  final cellNodes = <Node>[];
  for (var row = 0; row < rowsLen; row++) {
    final node = Node(
      type: TableCellBlockKeys.type,
      attributes: {
        TableCellBlockKeys.colPosition: insertAt,
        TableCellBlockKeys.rowPosition: row,
      },
      children: [paragraphNode()],
    );
    final firstCellInRow = findTableCellNode(tableNode, 0, row);
    final rowBgColor =
        firstCellInRow?.attributes[TableCellBlockKeys.rowBackgroundColor];
    if (rowBgColor != null) {
      node.updateAttributes({
        TableCellBlockKeys.rowBackgroundColor: rowBgColor,
      });
    }
    cellNodes.add(node);
  }

  final insertPath = insertAt == 0
      ? findTableCellNode(tableNode, 0, 0)!.path
      : findTableCellNode(tableNode, insertAt - 1, rowsLen - 1)!.path.next;
  transaction.insertNodes(insertPath, cellNodes);
  transaction.updateNode(tableNode, {TableBlockKeys.colsLen: colsLen + 1});
  editorState.apply(transaction, withUpdateSelection: false);
}

void removeAiwaTableColumn(
  EditorState editorState,
  Node tableNode,
  int col,
) {
  final rowsLen = tableNode.attributes[TableBlockKeys.rowsLen] as int? ?? 0;
  final colsLen = tableNode.attributes[TableBlockKeys.colsLen] as int? ?? 0;
  if (colsLen <= 1) {
    deleteAiwaTable(editorState, tableNode);
    return;
  }

  final transaction = editorState.transaction;
  final nodes = <Node>[];
  for (var row = 0; row < rowsLen; row++) {
    final cell = findTableCellNode(tableNode, col, row);
    if (cell != null) {
      nodes.add(cell);
    }
  }
  transaction.deleteNodes(nodes);
  for (var currentCol = col + 1; currentCol < colsLen; currentCol++) {
    for (var row = 0; row < rowsLen; row++) {
      final cell = findTableCellNode(tableNode, currentCol, row);
      if (cell != null) {
        transaction.updateNode(
          cell,
          {TableCellBlockKeys.colPosition: currentCol - 1},
        );
      }
    }
  }
  transaction.updateNode(tableNode, {TableBlockKeys.colsLen: colsLen - 1});
  editorState.apply(transaction, withUpdateSelection: false);
}

void resizeAiwaTable(
  EditorState editorState,
  Node tableNode, {
  required int rows,
  required int cols,
}) {
  final safeRows = rows < 1 ? 1 : rows;
  final safeCols = cols < 1 ? 1 : cols;

  var currentRows = tableNode.attributes[TableBlockKeys.rowsLen] as int? ?? 0;
  while (currentRows < safeRows) {
    addAiwaTableRow(editorState, tableNode, currentRows);
    currentRows += 1;
  }
  while (currentRows > safeRows) {
    removeAiwaTableRow(editorState, tableNode, currentRows - 1);
    currentRows -= 1;
  }

  var currentCols = tableNode.attributes[TableBlockKeys.colsLen] as int? ?? 0;
  while (currentCols < safeCols) {
    addAiwaTableColumn(editorState, tableNode, currentCols);
    currentCols += 1;
  }
  while (currentCols > safeCols) {
    removeAiwaTableColumn(editorState, tableNode, currentCols - 1);
    currentCols -= 1;
  }
}
