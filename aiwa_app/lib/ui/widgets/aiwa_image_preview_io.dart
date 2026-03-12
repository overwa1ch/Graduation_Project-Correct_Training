import 'dart:io';

import 'package:flutter/widgets.dart';

Widget? buildAiwaLocalImagePreview(String source) {
  final path = _resolveImagePath(source);
  if (path == null || path.isEmpty) {
    return null;
  }

  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }

  return Image.file(
    file,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}

String? _resolveImagePath(String source) {
  final trimmed = source.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme && uri.scheme == 'file') {
    return uri.toFilePath();
  }

  return trimmed;
}
