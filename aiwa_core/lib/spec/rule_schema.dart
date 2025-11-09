import '../core/errors.dart';

void expect(bool cond, String msg) {
  if (!cond) throw RulesParseError(msg);
}

double _ensureNum(Object? v, String path) {
  expect(v is num, '$path must be a number, got ${v.runtimeType}');
  final value = (v as num).toDouble();
  expect(value.isFinite, '$path must be finite, got $value');
  return value;
}

Map<String, dynamic> _ensureMap(Object? v, String path) {
  expect(
      v is Map<String, dynamic>, '$path must be a map, got ${v.runtimeType}');
  return v as Map<String, dynamic>;
}

List _ensureList(Object? v, String path) {
  expect(v is List, '$path must be a list, got ${v.runtimeType}');
  return v as List;
}

void _validateStrictnessMap(
  Map<String, dynamic> map,
  String path, {
  required double min,
  required double max,
  int? strictVsRelaxed,
}) {
  expect(map.containsKey('relaxed'), '$path.relaxed missing');
  expect(map.containsKey('strict'), '$path.strict missing');
  final relaxed = _ensureNum(map['relaxed'], '$path.relaxed');
  final strict = _ensureNum(map['strict'], '$path.strict');
  expect(relaxed >= min && relaxed <= max,
      '$path.relaxed must be within [$min,$max], got $relaxed');
  expect(strict >= min && strict <= max,
      '$path.strict must be within [$min,$max], got $strict');

  if (strictVsRelaxed != null) {
    const eps = 1e-6;
    if (strictVsRelaxed < 0) {
      expect(strict <= relaxed + eps,
          '$path.strict must be <= $path.relaxed (got $strict vs $relaxed)');
    } else if (strictVsRelaxed > 0) {
      expect(strict >= relaxed - eps,
          '$path.strict must be >= $path.relaxed (got $strict vs $relaxed)');
    } else {
      expect((strict - relaxed).abs() <= eps,
          '$path.strict must equal $path.relaxed (got $strict vs $relaxed)');
    }
  }
}

void validateRuleMap(Map<String, dynamic> m) {
  expect(m['template'] == 'squat', 'template must be "squat" for Milestone A');

  expect(m.containsKey('counts'), 'counts missing');
  final counts = _ensureMap(m['counts'], 'counts');
  final minInterval =
      _ensureNum(counts['minIntervalMs'], 'counts.minIntervalMs');
  final windowMs = _ensureNum(counts['windowMs'], 'counts.windowMs');
  expect(minInterval > 0, 'counts.minIntervalMs must be > 0');
  expect(windowMs > 0, 'counts.windowMs must be > 0');

  if (m.containsKey('phases')) {
    final phases = _ensureMap(m['phases'], 'phases');
    if (phases.containsKey('minMs')) {
      final minMs = _ensureNum(phases['minMs'], 'phases.minMs');
      expect(minMs >= 0, 'phases.minMs must be >= 0');
    }
  }

  expect(m.containsKey('metrics'), 'metrics missing');
  final metrics = _ensureMap(m['metrics'], 'metrics');

  final depth = _ensureMap(metrics['depth'], 'metrics.depth');
  expect(
      depth.containsKey('kneeAngleMin'), 'metrics.depth.kneeAngleMin missing');
  _validateStrictnessMap(
      _ensureMap(depth['kneeAngleMin'], 'metrics.depth.kneeAngleMin'),
      'metrics.depth.kneeAngleMin',
      min: 0,
      max: 180,
      strictVsRelaxed: -1);

  final valgus = _ensureMap(metrics['valgus'], 'metrics.valgus');
  expect(valgus.containsKey('kneeOutAngleMin'),
      'metrics.valgus.kneeOutAngleMin missing');
  _validateStrictnessMap(
      _ensureMap(valgus['kneeOutAngleMin'], 'metrics.valgus.kneeOutAngleMin'),
      'metrics.valgus.kneeOutAngleMin',
      min: 0,
      max: 90,
      strictVsRelaxed: 1);
  if (valgus.containsKey('windowMs')) {
    final window = _ensureNum(valgus['windowMs'], 'metrics.valgus.windowMs');
    expect(window > 0, 'metrics.valgus.windowMs must be > 0');
  }

  final trunk = _ensureMap(metrics['trunk'], 'metrics.trunk');
  expect(trunk.containsKey('maxForwardLean'),
      'metrics.trunk.maxForwardLean missing');
  _validateStrictnessMap(
      _ensureMap(trunk['maxForwardLean'], 'metrics.trunk.maxForwardLean'),
      'metrics.trunk.maxForwardLean',
      min: 0,
      max: 90,
      strictVsRelaxed: -1);

  final tempo = _ensureMap(metrics['tempo'], 'metrics.tempo');
  expect(tempo.containsKey('eccentricMs'), 'metrics.tempo.eccentricMs missing');
  final eccentric =
      _ensureList(tempo['eccentricMs'], 'metrics.tempo.eccentricMs');
  expect(eccentric.length == 2, 'metrics.tempo.eccentricMs must have length 2');
  final eccLow = _ensureNum(eccentric[0], 'metrics.tempo.eccentricMs[0]');
  final eccHigh = _ensureNum(eccentric[1], 'metrics.tempo.eccentricMs[1]');
  expect(eccLow > 0 && eccHigh > 0, 'metrics.tempo.eccentricMs must be > 0');
  expect(eccLow <= eccHigh,
      'metrics.tempo.eccentricMs lower bound must be <= upper bound');

  expect(tempo.containsKey('ratio'), 'metrics.tempo.ratio missing');
  final ratio = _ensureList(tempo['ratio'], 'metrics.tempo.ratio');
  expect(ratio.length == 2, 'metrics.tempo.ratio must have length 2');
  final ratioLow = _ensureNum(ratio[0], 'metrics.tempo.ratio[0]');
  final ratioHigh = _ensureNum(ratio[1], 'metrics.tempo.ratio[1]');
  expect(ratioLow > 0 && ratioHigh > 0, 'metrics.tempo.ratio must be > 0');
  expect(ratioLow <= ratioHigh,
      'metrics.tempo.ratio lower bound must be <= upper bound');

  if (tempo.containsKey('concentricMs')) {
    final concentric =
        _ensureList(tempo['concentricMs'], 'metrics.tempo.concentricMs');
    expect(concentric.length == 2,
        'metrics.tempo.concentricMs must have length 2 when provided');
    final conLow = _ensureNum(concentric[0], 'metrics.tempo.concentricMs[0]');
    final conHigh = _ensureNum(concentric[1], 'metrics.tempo.concentricMs[1]');
    expect(conLow > 0 && conHigh > 0, 'metrics.tempo.concentricMs must be > 0');
    expect(conLow <= conHigh,
        'metrics.tempo.concentricMs lower bound must be <= upper bound');
  }

  expect(m.containsKey('scoreWeights'), 'scoreWeights missing');
  final weights = _ensureMap(m['scoreWeights'], 'scoreWeights');
  final requiredWeights = ['form', 'stability', 'tempo'];
  double sum = 0.0;
  for (final key in requiredWeights) {
    expect(weights.containsKey(key), 'scoreWeights.$key missing');
    final value = _ensureNum(weights[key], 'scoreWeights.$key');
    expect(value >= 0 && value <= 1, 'scoreWeights.$key must be within [0,1]');
    sum += value;
  }
  expect((sum - 1.0).abs() <= 0.01,
      'scoreWeights must sum to 1 (±0.01), actual=$sum');

  final strictness = _ensureMap(m['strictness'], 'strictness');
  for (final k in ['relaxed', 'strict']) {
    expect(strictness.containsKey(k), 'strictness.$k missing');
    final profile = _ensureMap(strictness[k], 'strictness.$k');
    final minValley = _ensureNum(
        profile['minValleyKneeAngle'], 'strictness.$k.minValleyKneeAngle');
    expect(minValley >= 0 && minValley <= 180,
        'strictness.$k.minValleyKneeAngle must be within [0,180]');
  }
}
