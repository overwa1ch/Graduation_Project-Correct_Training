import 'dart:collection';

import '../common/date_only.dart';
import '../common/domain_exception.dart';
import '../common/typedef_ids.dart';
import 'task_occurrence.dart';

class TaskActivation {
  final TaskActivationId id;
  final TaskTemplateId templateId;
  final DateOnly startDate;
  final List<TaskOccurrence> _occurrences;
  final DateTime createdAtUtc;

  TaskActivation({
    required this.id,
    required this.templateId,
    required this.startDate,
    required List<TaskOccurrence> occurrences,
    required this.createdAtUtc,
  }) : _occurrences = List<TaskOccurrence>.from(occurrences) {
    requireNonEmpty(id, 'id');
    requireNonEmpty(templateId, 'templateId');
    requireUtc(createdAtUtc, 'createdAtUtc');
  }

  UnmodifiableListView<TaskOccurrence> get occurrences =>
      UnmodifiableListView<TaskOccurrence>(_occurrences);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'templateId': templateId,
        'startDate': startDate.toJson(),
        'occurrences': _occurrences.map((entry) => entry.toJson()).toList(),
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
      };

  factory TaskActivation.fromJson(Map<String, dynamic> json) => TaskActivation(
        id: json['id'] as String,
        templateId: json['templateId'] as String,
        startDate: DateOnly.fromJson(json['startDate'] as String),
        occurrences: (json['occurrences'] as List<dynamic>? ?? <dynamic>[])
            .map((raw) => TaskOccurrence.fromJson(raw as Map<String, dynamic>))
            .toList(growable: false),
        createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      );
}
