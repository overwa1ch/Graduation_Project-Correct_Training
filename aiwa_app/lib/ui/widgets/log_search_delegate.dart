import 'package:flutter/material.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';

Future<LogEditorDTO?> showLogSearch({
  required BuildContext context,
  required List<LogEditorDTO> logs,
  required String Function(LogEditorDTO) titleOf,
}) {
  return showSearch<LogEditorDTO?>(
    context: context,
    delegate: LogSearchDelegate(logs: logs, titleOf: titleOf),
  );
}

class LogSearchDelegate extends SearchDelegate<LogEditorDTO?> {
  LogSearchDelegate({required this.logs, required this.titleOf});

  final List<LogEditorDTO> logs;
  final String Function(LogEditorDTO) titleOf;

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back_ios_new),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.trim().toLowerCase();
    final items = q.isEmpty
        ? logs
        : logs.where((e) => titleOf(e).toLowerCase().contains(q)).toList();
    if (items.isEmpty) {
      return const Center(
        child: Text('未找到匹配日志'),
      );
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(
        title: Text(titleOf(items[i])),
        onTap: () => close(context, items[i]),
      ),
    );
  }
}
