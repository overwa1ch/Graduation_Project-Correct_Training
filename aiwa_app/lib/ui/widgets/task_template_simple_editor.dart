import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:aiwa_app/theme/colors.dart';
import 'package:aiwa_app/theme/typography.dart';
import 'package:aiwa_app/theme/spacing.dart';

class TaskTemplateDraft {
  const TaskTemplateDraft({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class TaskTemplateSimpleEditor extends StatefulWidget {
  const TaskTemplateSimpleEditor({
    super.key,
    required this.initialTitle,
    required this.initialBody,
    this.onChanged,
  });

  final String initialTitle;
  final String initialBody;
  final ValueChanged<TaskTemplateDraft>? onChanged;

  @override
  State<TaskTemplateSimpleEditor> createState() => _TaskTemplateSimpleEditorState();
}

class _TaskTemplateSimpleEditorState extends State<TaskTemplateSimpleEditor> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    
    String parsedBody = widget.initialBody;
    if (parsedBody.trim().startsWith('[{"insert"')) {
      try {
        final List<dynamic> delta = jsonDecode(parsedBody.trim()) as List<dynamic>;
        parsedBody = delta.map((op) => op['insert'] as String? ?? '').join();
      } catch (_) {}
    }
    _bodyController = TextEditingController(text: parsedBody);

    _titleController.addListener(_emitDraft);
    _bodyController.addListener(_emitDraft);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _emitDraft();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _emitDraft() {
    widget.onChanged?.call(
      TaskTemplateDraft(
        title: _titleController.text.trim(),
        body: _bodyController.text,
      ),
    );
  }

  void _insertText(String text) {
    final textSelection = _bodyController.selection;
    final currentText = _bodyController.text;
    
    if (textSelection.isValid) {
      final newText = currentText.replaceRange(
        textSelection.start,
        textSelection.end,
        text,
      );
      _bodyController.value = _bodyController.value.copyWith(
        text: newText,
        selection: TextSelection.collapsed(
          offset: textSelection.start + text.length,
        ),
      );
    } else {
      _bodyController.text = currentText + text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 标题输入区
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              hintText: '任务名称',
              border: InputBorder.none,
            ),
            style: AppTypography.h2,
          ),
        ),
        const Divider(height: 1),
        
        // 正文编辑区
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TextField(
              controller: _bodyController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: '任务详情...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: AppTypography.bodyBase,
            ),
          ),
        ),
        
        // 工具栏
        Material(
          color: AppColors.surfaceSecondary.withOpacity(0.5),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_box_outline_blank, size: 20),
                    tooltip: '插入待办',
                    onPressed: () => _insertText('- [ ] '),
                  ),
                  IconButton(
                    icon: const Icon(Icons.format_size, size: 20),
                    tooltip: '插入标题',
                    onPressed: () => _insertText('## '),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.keyboard_hide),
                    tooltip: '收起键盘',
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
