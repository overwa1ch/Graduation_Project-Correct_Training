import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

import 'package:aiwa_app/ui/widgets/aiwa_attachment_block_component.dart';
import 'package:aiwa_app/ui/widgets/aiwa_divider_block_component.dart';
import 'package:aiwa_app/ui/widgets/aiwa_image_block_component.dart';
import 'package:aiwa_app/ui/widgets/aiwa_table_block_component.dart';

Map<String, BlockComponentBuilder> buildAiwaBlockComponentBuilders() {
  final compactTextConfig = BlockComponentConfiguration(
    padding: _zeroPadding,
    blockSelectionAreaMargin: _zeroPadding,
  );

  return <String, BlockComponentBuilder>{
    ...standardBlockComponentBuilderMap,
    ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
      configuration: compactTextConfig,
    ),
    TodoListBlockKeys.type: TodoListBlockComponentBuilder(
      configuration: compactTextConfig.copyWith(
        placeholderText: (_) => AppFlowyEditorL10n.current.toDoPlaceholder,
      ),
    ),
    BulletedListBlockKeys.type: BulletedListBlockComponentBuilder(
      configuration: compactTextConfig.copyWith(
        placeholderText: (_) => AppFlowyEditorL10n.current.listItemPlaceholder,
      ),
    ),
    NumberedListBlockKeys.type: NumberedListBlockComponentBuilder(
      configuration: compactTextConfig.copyWith(
        placeholderText: (_) => AppFlowyEditorL10n.current.listItemPlaceholder,
      ),
    ),
    QuoteBlockKeys.type: QuoteBlockComponentBuilder(
      configuration: compactTextConfig.copyWith(
        placeholderText: (_) => AppFlowyEditorL10n.current.quote,
      ),
    ),
    HeadingBlockKeys.type: HeadingBlockComponentBuilder(
      configuration: compactTextConfig.copyWith(
        placeholderText: (node) =>
            'Heading ${node.attributes[HeadingBlockKeys.level]}',
      ),
    ),
    ImageBlockKeys.type: AiwaImageBlockComponentBuilder(),
    AiwaAttachmentBlockKeys.type: AiwaAttachmentBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: _zeroPadding,
        blockSelectionAreaMargin: _zeroPadding,
      ),
    ),
    DividerBlockKeys.type: DividerBlockComponentBuilder(
      configuration: BlockComponentConfiguration(
        padding: _zeroPadding,
        blockSelectionAreaMargin: _zeroPadding,
      ),
      wrapper: wrapAiwaDividerBlock,
    ),
    TableBlockKeys.type: AiwaTableBlockComponentBuilder(),
  };
}

EdgeInsets _zeroPadding(Node _) => EdgeInsets.zero;
