import '../core/errors.dart';

void expect(bool cond, String msg) {
  if (!cond) throw RulesParseError(msg);
}

void validateRuleMap(Map<String, dynamic> m) {
  expect(m['template']=='squat', 'template must be "squat" for Milestone A');
  expect(m.containsKey('counts'), 'counts missing');
  final counts = m['counts'] as Map<String,dynamic>;
  expect(counts.containsKey('minIntervalMs'), 'counts.minIntervalMs missing');
  expect(counts.containsKey('windowMs'),      'counts.windowMs missing');
  final s = m['strictness'] as Map<String,dynamic>;
  for (final k in ['relaxed','strict']) {
    expect(s.containsKey(k), 'strictness.$k missing');
    expect((s[k] as Map).containsKey('minValleyKneeAngle'),
           'strictness.$k.minValleyKneeAngle missing');
  }
  // 校验 metrics.depth/valgus/trunk/tempo & scoreWeights ∈ [0,1] 且和≈1.0 等……
}
