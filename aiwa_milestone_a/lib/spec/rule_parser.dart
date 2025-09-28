import 'dart:convert';
import '../core/errors.dart';
import 'rule_models.dart';
import 'rule_schema.dart';

RuleSet parseRuleSet(String jsonStr) {
  try {
    final m = json.decode(jsonStr) as Map<String, dynamic>;
    validateRuleMap(m); // 若无效抛 RulesParseError
    return RuleSet(
      template: m['template'],
      version:  m['version'],
      counts:   m['counts'],
      phases:   m['phases'] ?? {},
      metrics:  m['metrics'],
      scoreWeights: (m['scoreWeights'] as Map).map((k,v)=> MapEntry(k, (v as num))),
      strictness: m['strictness'],
    );
  } catch (e) {
    throw RulesParseError('Invalid rule json: $e');
  }
}
