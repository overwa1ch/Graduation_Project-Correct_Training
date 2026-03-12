import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';

Document parseRichTextDocument(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) {
    return Document.blank(withInitialText: true);
  }

  if (trimmed.startsWith('[')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List<dynamic>) {
        return quillDeltaEncoder.convert(Delta.fromJson(decoded));
      }
    } catch (_) {
      // Fall through to other decoders.
    }
  }

  if (trimmed.startsWith('{')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return Document.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // Fall through to markdown fallback.
    }
  }

  try {
    return markdownToDocument(body);
  } catch (_) {
    return Document.blank(withInitialText: true);
  }
}

String encodeRichTextDocument(Document document) {
  return jsonEncode(document.toJson());
}

String describeRichTextDocument(Document document) {
  return documentToMarkdown(document).trim();
}
