import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'log_editor_dto.dart';

class CalendarSnapshotQuery {
  final DateOnly yearFrom;
  final DateOnly yearTo;
  final DateOnly monthFrom;
  final DateOnly monthTo;

  const CalendarSnapshotQuery({
    required this.yearFrom,
    required this.yearTo,
    required this.monthFrom,
    required this.monthTo,
  });
}

class CalendarSnapshotDTO {
  final List<LogEditorDTO> yearLogs;
  final List<LogEditorDTO> monthLogs;
  final Set<String> yearLogDays;
  final Map<String, int> yearLogCountByDay;
  final Map<String, int> monthLogCountByDay;

  CalendarSnapshotDTO({
    required List<LogEditorDTO> yearLogs,
    required List<LogEditorDTO> monthLogs,
    required Set<String> yearLogDays,
    required Map<String, int> yearLogCountByDay,
    required Map<String, int> monthLogCountByDay,
  })  : yearLogs = List<LogEditorDTO>.unmodifiable(yearLogs),
        monthLogs = List<LogEditorDTO>.unmodifiable(monthLogs),
        yearLogDays = Set<String>.unmodifiable(yearLogDays),
        yearLogCountByDay = Map<String, int>.unmodifiable(yearLogCountByDay),
        monthLogCountByDay = Map<String, int>.unmodifiable(monthLogCountByDay);

  const CalendarSnapshotDTO.empty()
      : yearLogs = const <LogEditorDTO>[],
        monthLogs = const <LogEditorDTO>[],
        yearLogDays = const <String>{},
        yearLogCountByDay = const <String, int>{},
        monthLogCountByDay = const <String, int>{};

  factory CalendarSnapshotDTO.fromJson(Map<String, dynamic> json) =>
      CalendarSnapshotDTO(
        yearLogs: (json['yearLogs'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) =>
                LogEditorDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
        monthLogs: (json['monthLogs'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) =>
                LogEditorDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
        yearLogDays:
            (json['yearLogDays'] as List<dynamic>? ?? const <dynamic>[])
                .map((e) => e as String)
                .toSet(),
        yearLogCountByDay:
            (json['yearLogCountByDay'] as Map? ?? const <String, dynamic>{})
                .map(
          (key, value) => MapEntry(key as String, (value as num).toInt()),
        ),
        monthLogCountByDay:
            (json['monthLogCountByDay'] as Map? ?? const <String, dynamic>{})
                .map(
          (key, value) => MapEntry(key as String, (value as num).toInt()),
        ),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'yearLogs': yearLogs.map((e) => e.toJson()).toList(),
        'monthLogs': monthLogs.map((e) => e.toJson()).toList(),
        'yearLogDays': yearLogDays.toList(growable: false),
        'yearLogCountByDay': yearLogCountByDay,
        'monthLogCountByDay': monthLogCountByDay,
      };
}
