import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'log_editor_dto.dart';
import 'pr_summary_dto.dart';

/// Contract for the Home dashboard read model.
///
/// Semantics:
/// - [prSummary] is computed from all historical workout logs, not only [date].
/// - [hasWorkoutToday] is derived from whether [logs] is non-empty.
class HomeDashboardDTO {
  final DateOnly date;
  final List<LogEditorDTO> logs;
  final PRSummaryDTO prSummary;
  final bool hasWorkoutToday;

  HomeDashboardDTO({
    required this.date,
    required List<LogEditorDTO> logs,
    required this.prSummary,
  })  : logs = List<LogEditorDTO>.unmodifiable(logs),
        hasWorkoutToday = logs.isNotEmpty;

  factory HomeDashboardDTO.fromJson(Map<String, dynamic> json) {
    final logs = (json['logs'] as List<dynamic>)
        .map((e) => LogEditorDTO.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    return HomeDashboardDTO(
      date: DateOnly.parse(json['date'] as String),
      logs: logs,
      prSummary: PRSummaryDTO.fromJson(
        (json['prSummary'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'date': date.toString(),
        'logs': logs.map((e) => e.toJson()).toList(),
        'prSummary': prSummary.toJson(),
        'hasWorkoutToday': hasWorkoutToday,
      };
}
