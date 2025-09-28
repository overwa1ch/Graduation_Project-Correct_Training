import 'package:csv/csv.dart';

// rows: [ [t_ms, knee_L?, knee_R?, trunk_deg?], ... ]
String buildAnglesCsv(List<List<num?>> rows) {
  final header = ['t_ms','knee_L','knee_R','trunk_deg'];
  final data = [header, ...rows.map((r) => r.map((v) => v == null ? '' : v).toList())];
  return const ListToCsvConverter(eol: '\n').convert(data);
}
