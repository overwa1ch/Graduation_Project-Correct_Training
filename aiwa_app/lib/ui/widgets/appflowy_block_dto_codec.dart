import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:aiwa_core/fit_application/fit_application.dart';

import 'package:aiwa_app/ui/widgets/aiwa_attachment_block_component.dart';
import 'package:aiwa_app/ui/widgets/aiwa_inline_rich_text_codec.dart';
import 'package:aiwa_app/ui/widgets/rich_text_document_codec.dart';

Document buildDocumentFromBlockDtos(Iterable<BlockDTO> blocks) {
  final nodes = <Node>[];

  for (final block in blocks) {
    nodes.addAll(_decodeBlock(block));
  }

  if (nodes.isEmpty) {
    return Document.blank(withInitialText: true);
  }

  return Document(
    root: Node(
      type: PageBlockKeys.type,
      children: nodes,
    ),
  );
}

List<BlockDTO> buildBlockDtosFromDocument(
  Document document, {
  String idSeed = 'b',
}) {
  final blocks = <BlockDTO>[];
  final nextId = _IdFactory(idSeed);
  final pendingChecklist = <ChecklistItemDTO>[];

  void flushChecklist() {
    if (pendingChecklist.isEmpty) {
      return;
    }
    blocks.add(
      ChecklistBlockDTO(
        id: nextId('check'),
        items: List<ChecklistItemDTO>.from(pendingChecklist),
      ),
    );
    pendingChecklist.clear();
  }

  for (final node in document.root.children) {
    if (_isIgnorableBlankParagraph(node)) {
      continue;
    }

    if (node.type == TodoListBlockKeys.type) {
      pendingChecklist.add(
        ChecklistItemDTO(
          text: _plainText(node),
          checked: node.attributes[TodoListBlockKeys.checked] == true,
        ),
      );
      continue;
    }

    flushChecklist();

    final payloadBlock = _decodeEmbeddedPayload(node);
    if (payloadBlock != null) {
      blocks.add(payloadBlock);
      continue;
    }

    switch (node.type) {
      case HeadingBlockKeys.type:
        blocks.add(
          HeadingBlockDTO(
            id: nextId('heading'),
            text: _encodeSingleNodeDocument(node),
            level: (node.attributes[HeadingBlockKeys.level] as int? ?? 1)
                .clamp(1, 3),
          ),
        );
        break;
      case DividerBlockKeys.type:
        blocks.add(
          DividerBlockDTO(
            id: nextId('divider'),
          ),
        );
        break;
      case AiwaAttachmentBlockKeys.type:
        blocks.add(
          LinkBlockDTO(
            id: nextId('link'),
            url: node.attributes[AiwaAttachmentBlockKeys.href] as String? ?? '',
            title: node.attributes[AiwaAttachmentBlockKeys.label] as String?,
            note: node.attributes[AiwaAttachmentBlockKeys.note] as String?,
          ),
        );
        break;
      default:
        blocks.add(
          TextBlockDTO(
            id: nextId('text'),
            text: _encodeSingleNodeDocument(node),
          ),
        );
        break;
    }
  }

  flushChecklist();
  return blocks;
}

List<BlockDTO> buildTaskTemplateBlocks({
  required String title,
  required String body,
}) {
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

  blocks.addAll(
    buildBlockDtosFromDocument(
      parseRichTextDocument(body),
      idSeed: 'task',
    ),
  );

  return blocks;
}

String buildTaskTemplateBodyFromBlocks(Iterable<BlockDTO> blocks) {
  final bodyBlocks = <BlockDTO>[];
  var skippedTitle = false;

  for (final block in blocks) {
    if (!skippedTitle && block is HeadingBlockDTO) {
      skippedTitle = true;
      continue;
    }
    bodyBlocks.add(block);
  }

  return encodeRichTextDocument(buildDocumentFromBlockDtos(bodyBlocks));
}

String describeBlockDto(BlockDTO block) {
  if (block is HeadingBlockDTO) {
    return plainTextFromAiwaRichText(block.text).trim();
  }
  if (block is TextBlockDTO) {
    final doc = parseRichTextDocument(block.text);
    return describeRichTextDocument(doc);
  }
  if (block is DividerBlockDTO) {
    return 'Divider';
  }
  if (block is ChecklistBlockDTO) {
    return block.items.map((item) => item.text.trim()).firstWhere(
          (text) => text.isNotEmpty,
          orElse: () => 'Checklist',
        );
  }
  if (block is LinkBlockDTO) {
    return (block.title ?? block.url).trim();
  }
  if (block is TableBlockDTO) {
    return 'Table ${block.rows.length} x ${block.columnCount}';
  }
  if (block is ExerciseBlockDTO) {
    return block.exerciseNameSnapshot.trim();
  }
  if (block is ImageBlockDTO) {
    return (block.caption ?? 'Image attachment').trim();
  }
  if (block is VideoBlockDTO) {
    return (block.caption ?? 'Video attachment').trim();
  }
  if (block is ReferenceBlockDTO) {
    return (block.previewText ?? block.refType).trim();
  }
  if (block is TimerMarkerBlockDTO) {
    return (block.label ?? block.kind).trim();
  }
  return block.type;
}

List<Node> _decodeBlock(BlockDTO block) {
  if (block is TextBlockDTO) {
    final document = parseRichTextDocument(block.text);
    final children = document.root.children
        .map((node) => Node.fromJson(node.toJson()))
        .toList(growable: false);
    if (children.isNotEmpty) {
      return children;
    }
    final trimmed = block.text.trim();
    return trimmed.isEmpty
        ? const <Node>[]
        : <Node>[paragraphNode(text: trimmed)];
  }

  if (block is HeadingBlockDTO) {
    final document = parseRichTextDocument(block.text);
    final headingNodes = document.root.children
        .map(
          (node) => headingNode(
            level: block.level,
            delta: node.delta,
          ),
        )
        .toList(growable: false);
    if (headingNodes.isNotEmpty) {
      return headingNodes;
    }
    return <Node>[
      headingNode(
        text: plainTextFromAiwaRichText(block.text),
        level: block.level,
      ),
    ];
  }

  if (block is DividerBlockDTO) {
    return <Node>[dividerNode()];
  }

  if (block is ChecklistBlockDTO) {
    return block.items
        .map(
          (item) => todoListNode(
            text: item.text,
            checked: item.checked,
          ),
        )
        .toList(growable: false);
  }

  if (block is LinkBlockDTO) {
    return <Node>[
      aiwaAttachmentNode(
        label: (block.title ?? block.url).trim().isEmpty
            ? 'Attachment'
            : (block.title ?? block.url).trim(),
        href: block.url,
        note: block.note,
        blockType: block.type,
        payloadJson: jsonEncode(block.toJson()),
      ),
    ];
  }

  if (block is TableBlockDTO) {
    final markdown = _tableToMarkdown(block);
    return markdown.trim().isEmpty
        ? const <Node>[]
        : <Node>[paragraphNode(text: markdown)];
  }

  if (block is ImageBlockDTO) {
    return <Node>[
      aiwaAttachmentNode(
        label: (block.caption ?? 'Image attachment').trim(),
        href: block.attachments.firstOrNull?.id ?? '',
        note: 'Image attachment',
        blockType: block.type,
        payloadJson: jsonEncode(block.toJson()),
      ),
    ];
  }

  if (block is VideoBlockDTO) {
    return <Node>[
      aiwaAttachmentNode(
        label: (block.caption ?? 'Video attachment').trim(),
        href: block.attachments.firstOrNull?.id ?? '',
        note: 'Video attachment',
        blockType: block.type,
        payloadJson: jsonEncode(block.toJson()),
      ),
    ];
  }

  if (block is ExerciseBlockDTO) {
    return <Node>[
      aiwaAttachmentNode(
        label: block.exerciseNameSnapshot,
        href: '',
        note: 'Exercise block',
        blockType: block.type,
        payloadJson: jsonEncode(block.toJson()),
      ),
    ];
  }

  if (block is ReferenceBlockDTO) {
    return <Node>[
      aiwaAttachmentNode(
        label: block.previewText?.trim().isNotEmpty == true
            ? block.previewText!.trim()
            : block.refType,
        href: block.refId,
        note: block.refType,
        blockType: block.type,
        payloadJson: jsonEncode(block.toJson()),
      ),
    ];
  }

  if (block is TimerMarkerBlockDTO) {
    return <Node>[
      aiwaAttachmentNode(
        label: block.label?.trim().isNotEmpty == true
            ? block.label!.trim()
            : block.kind,
        href: block.atUtc,
        note: 'Timer marker',
        blockType: block.type,
        payloadJson: jsonEncode(block.toJson()),
      ),
    ];
  }

  return <Node>[
    aiwaAttachmentNode(
      label: describeBlockDto(block),
      href: '',
      note: block.type,
      blockType: block.type,
      payloadJson: jsonEncode(block.toJson()),
    ),
  ];
}

BlockDTO? _decodeEmbeddedPayload(Node node) {
  if (node.type != AiwaAttachmentBlockKeys.type) {
    return null;
  }

  final payloadJson =
      node.attributes[AiwaAttachmentBlockKeys.payloadJson] as String?;
  if (payloadJson == null || payloadJson.trim().isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(payloadJson);
    if (decoded is Map<String, dynamic>) {
      return BlockDTO.fromJson(decoded);
    }
    if (decoded is Map) {
      return BlockDTO.fromJson(Map<String, dynamic>.from(decoded));
    }
  } catch (_) {}

  return null;
}

bool _isIgnorableBlankParagraph(Node node) {
  if (node.type != ParagraphBlockKeys.type) {
    return false;
  }

  final delta = node.delta;
  if (delta == null) {
    return false;
  }

  return delta.toPlainText().trim().isEmpty &&
      node.attributes.keys.every((key) => key == ParagraphBlockKeys.delta);
}

String _plainText(Node node) {
  return node.delta?.toPlainText().trim() ?? '';
}

String _encodeSingleNodeDocument(Node node) {
  final document = Document(
    root: Node(
      type: PageBlockKeys.type,
      children: <Node>[Node.fromJson(node.toJson())],
    ),
  );
  return jsonEncode(document.toJson());
}

String _tableToMarkdown(TableBlockDTO block) {
  if (block.columnCount <= 0) {
    return '';
  }

  List<String> normalizeRow(List<String> row) {
    final cells = List<String>.from(row.take(block.columnCount));
    while (cells.length < block.columnCount) {
      cells.add('');
    }
    return cells;
  }

  String formatRow(List<String> row) {
    final cells = normalizeRow(row).map(_escapeMarkdownCell).join(' | ');
    return '| $cells |';
  }

  final rows = block.rows.map(normalizeRow).toList(growable: false);
  final header =
      rows.isEmpty ? List<String>.filled(block.columnCount, '') : rows.first;
  final bodyRows = rows.isEmpty
      ? const <List<String>>[]
      : rows.skip(1).toList(growable: false);
  final separator =
      '| ${List<String>.filled(block.columnCount, '---').join(' | ')} |';

  return <String>[
    formatRow(header),
    separator,
    ...bodyRows.map(formatRow),
  ].join('\n');
}

String _escapeMarkdownCell(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', ' ');
}

final class _IdFactory {
  _IdFactory(this.seed);

  final String seed;
  int _counter = 0;

  String call(String prefix) {
    _counter += 1;
    return '${prefix}_${seed}_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }
}
