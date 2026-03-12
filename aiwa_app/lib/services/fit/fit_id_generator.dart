import 'dart:math';

import 'package:aiwa_core/fit_application/fit_application.dart';

/// Simple ID generator (no new deps): timestamp + random suffix.
class FitIdGenerator implements IdGenerator {
  static final Random _random = Random();

  const FitIdGenerator();

  @override
  String newId() {
    final t = DateTime.now().toUtc().microsecondsSinceEpoch;
    final r = _random.nextInt(0x7FFFFFFF);
    return '${t}_$r';
  }
}
