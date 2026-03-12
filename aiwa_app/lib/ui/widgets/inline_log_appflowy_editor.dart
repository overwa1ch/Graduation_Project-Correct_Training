import 'package:flutter/material.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';

import 'package:aiwa_app/ui/widgets/aiwa_block_editor.dart';
import 'package:aiwa_app/ui/widgets/aiwa_inline_rich_text_codec.dart';
import 'package:aiwa_app/ui/widgets/appflowy_block_dto_codec.dart';

class InlineLogDraft {
  const InlineLogDraft({
    required this.title,
    required this.body,
    required this.blocks,
  });

  final String title;
  final String body;
  final List<BlockDTO> blocks;
}

class InlineLogAppflowyEditor extends StatelessWidget {
  const InlineLogAppflowyEditor({
    super.key,
    required this.initialBlocks,
    this.onChanged,
    this.showTimer = false,
    this.showTitleField = true,
    this.externalTitle,
  });

  final List<BlockDTO> initialBlocks;
  final ValueChanged<InlineLogDraft>? onChanged;
  final bool showTimer;
  final bool showTitleField;
  final String? externalTitle;

  @override
  Widget build(BuildContext context) {
    final split = _splitBlocks(initialBlocks, externalTitle: externalTitle);

    return AiwaBlockEditor(
      initialTitle: showTitleField ? split.title : (externalTitle ?? ''),
      initialBlocks: split.bodyBlocks,
      showTitleField: showTitleField,
      externalTitle: externalTitle,
      titleHint: 'Title',
      onChanged: (draft) {
        final title = showTitleField ? draft.title : (externalTitle ?? '').trim();
        final blocks = _composeBlocks(title, draft.blocks);
        final body = draft.blocks
            .map((block) => describeBlockDto(block).trim())
            .where((text) => text.isNotEmpty)
            .join('\n');
        onChanged?.call(
          InlineLogDraft(
            title: title,
            body: body,
            blocks: blocks,
          ),
        );
      },
    );
  }

  _InitialLogBlocks _splitBlocks(
    List<BlockDTO> blocks, {
    String? externalTitle,
  }) {
    if (blocks.isNotEmpty && blocks.first is HeadingBlockDTO) {
      final heading = blocks.first as HeadingBlockDTO;
      return _InitialLogBlocks(
        title: plainTextFromAiwaRichText(heading.text),
        bodyBlocks: blocks.skip(1).toList(growable: false),
      );
    }
    return _InitialLogBlocks(
      title: externalTitle?.trim() ?? '',
      bodyBlocks: List<BlockDTO>.from(blocks),
    );
  }

  List<BlockDTO> _composeBlocks(String title, List<BlockDTO> bodyBlocks) {
    final blocks = <BlockDTO>[];
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) {
      blocks.add(
        HeadingBlockDTO(
          id: 'heading_${DateTime.now().microsecondsSinceEpoch}',
          text: trimmedTitle,
          level: 1,
        ),
      );
    }
    blocks.addAll(bodyBlocks);
    return blocks;
  }
}

class _InitialLogBlocks {
  const _InitialLogBlocks({
    required this.title,
    required this.bodyBlocks,
  });

  final String title;
  final List<BlockDTO> bodyBlocks;
}
