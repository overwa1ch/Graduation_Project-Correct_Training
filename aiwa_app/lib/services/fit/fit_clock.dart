import 'package:aiwa_core/fit_application/fit_application.dart';

/// System UTC clock for fit use cases.
class FitClock implements Clock {
  const FitClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
