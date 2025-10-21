class PerfTimer {
  final DateTime _t0 = DateTime.now();
  final Map<String, int> _marks = <String, int>{};
  int _lap = DateTime.now().microsecondsSinceEpoch;

  void lap(String name) {
    final now = DateTime.now().microsecondsSinceEpoch;
    _marks[name] = (now - _lap) ~/ 1000;
    _lap = now;
  }

  Map<String, int> export() => _marks;

  int elapsedMs() => DateTime.now().difference(_t0).inMilliseconds;
}
