import 'package:csv/csv.dart';

import '../core/rounding.dart';

// rows: [ [t_ms, knee_L?, knee_R?, trunk_deg?], ... ]
String buildAnglesCsv(List<List<num?>> rows) {
  final header = ['t_ms', 'knee_L', 'knee_R', 'trunk_deg'];
  final data = [
    header,
    ...rows.map((row) {
      final converted = <Object?>[row[0]];
      for (var i = 1; i < row.length; i++) {
        final value = row[i];
        if (value == null) {
          converted.add('');
        } else {
          final rounded = round3(value as num);
          converted.add(rounded.toStringAsFixed(3));
        }
      }
      return converted;
    })
  ];
  return const ListToCsvConverter(eol: '\n').convert(data);
}
