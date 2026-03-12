import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aiwa_app/ui/widgets/aiwa_editor_block_operations.dart';
import 'package:aiwa_app/ui/widgets/aiwa_editor_table_actions.dart';

class AiwaTableBlockComponentBuilder extends BlockComponentBuilder {
  AiwaTableBlockComponentBuilder({
    super.configuration,
    this.tableStyle = const TableStyle(),
  });

  final TableStyle tableStyle;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return AiwaTableBlockComponentWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      tableStyle: tableStyle,
    );
  }

  @override
  BlockComponentValidate get validate => TableBlockComponentBuilder(
        configuration: configuration,
      ).validate;
}

class AiwaTableBlockComponentWidget extends BlockComponentStatefulWidget {
  const AiwaTableBlockComponentWidget({
    super.key,
    required super.node,
    required this.tableStyle,
    super.configuration = const BlockComponentConfiguration(),
  });

  final TableStyle tableStyle;

  @override
  State<AiwaTableBlockComponentWidget> createState() =>
      _AiwaTableBlockComponentWidgetState();
}

class _AiwaTableBlockComponentWidgetState
    extends State<AiwaTableBlockComponentWidget> {
  late final EditorState _editorState = context.read<EditorState>();

  int get _rows => widget.node.attributes[TableBlockKeys.rowsLen] as int? ?? 1;

  int get _cols => widget.node.attributes[TableBlockKeys.colsLen] as int? ?? 1;

  Future<void> _showTableSettings() async {
    var rows = _rows;
    var cols = _cols;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    '编辑表格',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _StepperRow(
                    label: '行数',
                    value: rows,
                    onChanged: (value) => setModalState(() => rows = value),
                  ),
                  const SizedBox(height: 12),
                  _StepperRow(
                    label: '列数',
                    value: cols,
                    onChanged: (value) => setModalState(() => cols = value),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            resizeAiwaTable(
                              _editorState,
                              widget.node,
                              rows: rows,
                              cols: cols,
                            );
                            Navigator.of(context).pop();
                          },
                          child: const Text('应用'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => selectAiwaBlockNode(_editorState, widget.node),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '表格 $_rows x $_cols',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _showTableSettings,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('编辑'),
              ),
              IconButton(
                tooltip: '删除表格',
                onPressed: () => deleteAiwaTable(_editorState, widget.node),
                icon: const Icon(Icons.delete_outline, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          TableBlockComponentWidget(
            node: widget.node,
            configuration: widget.configuration,
            tableNode: TableNode(node: widget.node),
            tableStyle: widget.tableStyle,
          ),
        ],
      ),
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
