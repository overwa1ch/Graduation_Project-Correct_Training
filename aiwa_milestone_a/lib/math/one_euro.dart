class OneEuroFilter {
  final double minCutoff, beta, dCutoff; // 1.0, 0.005, 1.0
  double? _xHat; double? _dxHat; double? _lastT;
  OneEuroFilter({this.minCutoff=1.0, this.beta=0.005, this.dCutoff=1.0});

  double _alpha(double cutoff, double dt) {
    final tau = 1.0 / (2.0 * 3.141592653589793 * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }
  double _expSmooth(double x, double? xHatPrev, double a) =>
      xHatPrev == null ? x : a*x + (1-a)*xHatPrev;

  double filter(double t, double x) {
    if (_lastT == null) { _lastT = t; _xHat = x; _dxHat = 0; return x; }
    final dt = ((t - _lastT!).abs() < 1e-9) ? 1e-3 : (t - _lastT!); // 秒
    _lastT = t;
    final dx = (x - _xHat!) / dt;
    final aD = _alpha(dCutoff, dt);
    _dxHat = _expSmooth(dx, _dxHat, aD);
    final cutoff = minCutoff + beta * _dxHat!.abs();
    final aX = _alpha(cutoff, dt);
    _xHat = _expSmooth(x, _xHat, aX);
    return _xHat!;
  }
}
