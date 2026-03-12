import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart' as af;
import 'package:dart_quill_delta/dart_quill_delta.dart' as qd;
import 'package:flutter_quill/flutter_quill.dart' as fq;

import 'package:aiwa_app/ui/widgets/rich_text_document_codec.dart';

fq.Document parseAiwaInlineDocument(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return fq.Document();
  }

  if (trimmed.startsWith('[')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List<dynamic>) {
        return fq.Document.fromJson(decoded);
      }
    } catch (_) {
      // Fall through to the AppFlowy decoder path.
    }
  }

  final appFlowyDocument = parseRichTextDocument(raw);
  return fq.Document.fromDelta(
    _quillDeltaFromAppFlowyDocument(appFlowyDocument),
  );
}

String encodeAiwaInlineDocument(fq.Document document) {
  final plainText = plainTextFromAiwaInlineDocument(document).trim();
  if (plainText.isEmpty) {
    return '';
  }
  return jsonEncode(document.toDelta().toJson());
}

String normalizeAiwaRichTextStorage(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  return encodeAiwaInlineDocument(parseAiwaInlineDocument(raw));
}

String plainTextFromAiwaRichText(String raw) {
  if (raw.trim().isEmpty) {
    return '';
  }
  return plainTextFromAiwaInlineDocument(parseAiwaInlineDocument(raw));
}

String plainTextFromAiwaInlineDocument(fq.Document document) {
  return document.toPlainText().replaceFirst(RegExp(r'\n+$'), '');
}

qd.Delta _quillDeltaFromAppFlowyDocument(af.Document document) {
  final delta = qd.Delta();
  final nodes = document.root.children;
  if (nodes.isEmpty) {
    delta.insert('\n');
    return delta;
  }

  for (final node in nodes) {
    final nodeDelta = node.delta;
    var wroteText = false;
    if (nodeDelta != null) {
      for (final operation in nodeDelta) {
        if (operation is af.TextInsert) {
          delta.insert(
            operation.text,
            _quillAttributesFromAppFlowy(operation.attributes),
          );
          wroteText = true;
        }
      }
    }
    if (!wroteText) {
      delta.insert('');
    }
    final lineAttributes = _lineAttributesFromNode(node);
    delta.insert('\n', lineAttributes.isEmpty ? null : lineAttributes);
  }

  return delta;
}

Map<String, dynamic>? _quillAttributesFromAppFlowy(af.Attributes? attributes) {
  if (attributes == null || attributes.isEmpty) {
    return null;
  }

  final mapped = <String, dynamic>{};
  if (attributes[af.AppFlowyRichTextKeys.bold] == true) {
    mapped[fq.Attribute.bold.key] = true;
  }
  if (attributes[af.AppFlowyRichTextKeys.italic] == true) {
    mapped[fq.Attribute.italic.key] = true;
  }
  if (attributes[af.AppFlowyRichTextKeys.underline] == true) {
    mapped[fq.Attribute.underline.key] = true;
  }
  if (attributes[af.AppFlowyRichTextKeys.strikethrough] == true) {
    mapped[fq.Attribute.strikeThrough.key] = true;
  }
  if (attributes[af.AppFlowyRichTextKeys.code] == true) {
    mapped[fq.Attribute.inlineCode.key] = true;
  }

  final href = attributes[af.AppFlowyRichTextKeys.href];
  if (href is String && href.trim().isNotEmpty) {
    mapped[fq.Attribute.link.key] = href;
  }

  final textColor = _quillColorValue(
    attributes[af.AppFlowyRichTextKeys.textColor] as String?,
  );
  if (textColor != null) {
    mapped[fq.Attribute.color.key] = textColor;
  }

  final backgroundColor = _quillColorValue(
    attributes[af.AppFlowyRichTextKeys.backgroundColor] as String?,
  );
  if (backgroundColor != null) {
    mapped[fq.Attribute.background.key] = backgroundColor;
  }

  final fontSize = attributes[af.AppFlowyRichTextKeys.fontSize];
  if (fontSize is num) {
    mapped[fq.Attribute.size.key] = fontSize.toString();
  }

  return mapped.isEmpty ? null : mapped;
}

Map<String, dynamic> _lineAttributesFromNode(af.Node node) {
  if (node.type == af.HeadingBlockKeys.type) {
    return <String, dynamic>{
      fq.Attribute.header.key:
          (node.attributes[af.HeadingBlockKeys.level] as int? ?? 1).clamp(1, 6),
    };
  }
  if (node.type == af.TodoListBlockKeys.type) {
    return <String, dynamic>{
      fq.Attribute.list.key:
          node.attributes[af.TodoListBlockKeys.checked] == true
              ? fq.Attribute.checked.value
              : fq.Attribute.unchecked.value,
    };
  }
  if (node.type == af.BulletedListBlockKeys.type) {
    return <String, dynamic>{fq.Attribute.list.key: fq.Attribute.ul.value};
  }
  if (node.type == af.NumberedListBlockKeys.type) {
    return <String, dynamic>{fq.Attribute.list.key: fq.Attribute.ol.value};
  }
  if (node.type == af.QuoteBlockKeys.type) {
    return <String, dynamic>{fq.Attribute.blockQuote.key: true};
  }
  return const <String, dynamic>{};
}

String? _quillColorValue(String? rawColor) {
  if (rawColor == null || rawColor.trim().isEmpty) {
    return null;
  }

  final value = rawColor.trim();
  if (value.startsWith('#')) {
    return value;
  }
  if (value.startsWith('0x') && value.length >= 10) {
    return '#${value.substring(value.length - 6)}';
  }
  return null;
}
