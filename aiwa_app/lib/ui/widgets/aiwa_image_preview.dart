import 'package:flutter/widgets.dart';

import 'aiwa_image_preview_stub.dart'
    if (dart.library.io) 'aiwa_image_preview_io.dart' as impl;

Widget? buildAiwaLocalImagePreview(String source) {
  return impl.buildAiwaLocalImagePreview(source);
}
