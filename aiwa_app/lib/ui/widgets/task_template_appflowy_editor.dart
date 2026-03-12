import 'package:flutter/material.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';

import 'package:aiwa_app/ui/widgets/aiwa_block_editor.dart';

class TaskTemplateDraft {
  const TaskTemplateDraft({
    required this.title,
    required this.blocks,
  });

  final String title;
  final List<BlockDTO> blocks;
}

class TaskTemplateAppflowyEditor extends StatelessWidget {
  const TaskTemplateAppflowyEditor({
    super.key,
    required this.initialTitle,
    required this.initialBlocks,
    this.onChanged,
    this.onOpenHeader,
  });

  final String initialTitle;
  final List<BlockDTO> initialBlocks;
  final ValueChanged<TaskTemplateDraft>? onChanged;
  final VoidCallback? onOpenHeader;

  @override
  Widget build(BuildContext context) {
    return AiwaBlockEditor(
      initialTitle: initialTitle,
      initialBlocks: initialBlocks,
      onOpenHeader: onOpenHeader,
      showTitleField: false,
      externalTitle: initialTitle,
      headerTitle: '基础选项',
      headerSubtitle: '标题和重复规则',
      onChanged: (draft) {
        onChanged?.call(
          TaskTemplateDraft(
            title: initialTitle,
            blocks: draft.blocks,
          ),
        );
      },
    );
  }
}
