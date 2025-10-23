class Strictness {
  final String value;
  const Strictness._(this.value);
  static const relaxed = Strictness._('relaxed');
  static const strict = Strictness._('strict');
}

class RuleSet {
  final String template; // "squat"
  final String version; // "1.0.0"
  final Map<String, dynamic>
      counts; // minIntervalMs, windowMs, minValleyKneeAngle{relaxed,strict}
  final Map<String, dynamic> phases; // minMs (可覆盖 250)
  final Map<String, dynamic> metrics; // depth/valgus/trunk/tempo
  final Map<String, num> scoreWeights; // form=0.5, stability=0.25, tempo=0.25
  final Map<String, dynamic> strictness; // 阈值档案
  RuleSet(
      {required this.template,
      required this.version,
      required this.counts,
      required this.phases,
      required this.metrics,
      required this.scoreWeights,
      required this.strictness});
}
