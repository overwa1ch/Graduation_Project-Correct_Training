import 'dart:convert';

import 'package:aiwa_core/fit_application/fit_application.dart';
import 'package:aiwa_core/fit_domain/fit_domain.dart';

import 'package:aiwa_app/ui/models/repeat_config.dart';
import 'package:aiwa_app/ui/widgets/task_template_payload_codec.dart';

class TaskTemplateOccurrenceSyncService {
  final TaskActivationRepository taskActivationRepository;
  final TaskTemplateRepository taskTemplateRepository;
  final WorkoutLogRepository workoutLogRepository;
  final CreateWorkoutLogUseCase createWorkoutLogUseCase;

  const TaskTemplateOccurrenceSyncService({
    required this.taskActivationRepository,
    required this.taskTemplateRepository,
    required this.workoutLogRepository,
    required this.createWorkoutLogUseCase,
  });

  Future<void> syncVisibleYear({
    required DateOnly yearFrom,
    required DateOnly yearTo,
  }) async {
    final activations = await taskActivationRepository.findAll();
    final visibleStart = yearFrom.toDateTimeUtc();
    final visibleEnd = yearTo.toDateTimeUtc();

    for (final activation in activations) {
      final template =
          await taskTemplateRepository.findById(activation.templateId);
      if (template == null) {
        continue;
      }

      final payload = _parseTaskTemplatePayload(template);
      final snapshot = normalizeTaskTemplatePayload(
        payload,
        title: template.title,
      );
      var blocks = snapshot.blocks;
      if (blocks.isEmpty) {
        blocks = parseTaskTemplateBlocksFromPayload(
          payload,
          title: template.title,
        );
      }
      final repeatJson = payload['repeatConfig'];
      final repeatConfig = repeatJson is Map<String, dynamic>
          ? RepeatConfig.fromJson(repeatJson)
          : repeatJson is Map
              ? RepeatConfig.fromJson(Map<String, dynamic>.from(repeatJson))
              : RepeatConfig();

      final scheduleStart = _normalizeRepeatDate(repeatConfig.startDate);
      final scheduleEnd = repeatConfig.neverEnds
          ? visibleEnd
          : _normalizeRepeatDate(
              repeatConfig.endDate ?? repeatConfig.startDate);
      if (scheduleEnd.isBefore(visibleStart) ||
          scheduleStart.isAfter(visibleEnd)) {
        continue;
      }

      final materializeStart =
          scheduleStart.isAfter(visibleStart) ? scheduleStart : visibleStart;
      final materializeEnd =
          scheduleEnd.isBefore(visibleEnd) ? scheduleEnd : visibleEnd;

      final occurrenceByDate = <String, TaskOccurrence>{
        for (final occurrence in activation.occurrences)
          occurrence.date.toString(): occurrence,
      };
      final nextOccurrences = activation.occurrences.toList(growable: true);
      var changed = false;

      for (DateTime day = materializeStart;
          !day.isAfter(materializeEnd);
          day = day.add(const Duration(days: 1))) {
        if (!matchesRepeat(day, scheduleStart, repeatConfig)) {
          continue;
        }
        final date = DateOnly.fromDateTimeUtc(day);
        final key = date.toString();
        final existingOccurrence = occurrenceByDate[key];
        if (existingOccurrence != null) {
          if (existingOccurrence.suppressed) {
            continue;
          }
          final boundLogId = existingOccurrence.boundLogId;
          if (boundLogId != null) {
            final existingLog = await workoutLogRepository.findById(boundLogId);
            if (existingLog != null) {
              continue;
            }
          }
          final recreatedLog = await createWorkoutLogUseCase.execute(
            CreateWorkoutLogInput(
              date: key,
              boundTaskOccurrenceId: existingOccurrence.id,
              blocks: blocks,
            ),
          );
          final repairedOccurrence = existingOccurrence.copyWith(
            boundLogId: recreatedLog.id,
            suppressed: false,
          );
          final repairIndex = nextOccurrences.indexWhere(
            (occurrence) => occurrence.id == existingOccurrence.id,
          );
          if (repairIndex != -1) {
            nextOccurrences[repairIndex] = repairedOccurrence;
          }
          occurrenceByDate[key] = repairedOccurrence;
          changed = true;
          continue;
        }

        final occurrenceId = 'task_occ_${activation.id}_$key';
        final log = await createWorkoutLogUseCase.execute(
          CreateWorkoutLogInput(
            date: key,
            boundTaskOccurrenceId: occurrenceId,
            blocks: blocks,
          ),
        );
        final occurrence = TaskOccurrence(
          id: occurrenceId,
          date: date,
          boundLogId: log.id,
        );
        nextOccurrences.add(occurrence);
        occurrenceByDate[key] = occurrence;
        changed = true;
      }

      if (!changed) {
        continue;
      }
      nextOccurrences.sort((left, right) => left.date.compareTo(right.date));
      await taskActivationRepository.save(
        TaskActivation(
          id: activation.id,
          templateId: activation.templateId,
          startDate: activation.startDate,
          occurrences: nextOccurrences,
          createdAtUtc: activation.createdAtUtc,
        ),
      );
    }
  }

  Map<String, dynamic> _parseTaskTemplatePayload(TaskTemplate template) {
    try {
      final raw = jsonDecode(template.description ?? '{}');
      if (raw is Map<String, dynamic>) {
        return raw;
      }
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  DateTime _normalizeRepeatDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
