import 'package:aiwa_core/fit_application/fit_application.dart';

class FakeClock implements Clock {
  DateTime _nowUtc;

  FakeClock(DateTime nowUtc) : _nowUtc = nowUtc.toUtc();

  @override
  DateTime nowUtc() => _nowUtc;

  void setNowUtc(DateTime value) {
    _nowUtc = value.toUtc();
  }
}
