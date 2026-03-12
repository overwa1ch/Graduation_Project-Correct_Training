import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/date_only.dart';
import '../common/typedef_ids.dart';

part 'milestone_event.freezed.dart';
part 'milestone_event.g.dart';

@freezed
class MilestoneEvent with _$MilestoneEvent {
  const MilestoneEvent._();

  @Assert('id.isNotEmpty')
  @Assert('type == "pr"')
  @Assert('exerciseId.isNotEmpty')
  @Assert('logId.isNotEmpty')
  @Assert('dedupKey.isNotEmpty')
  @Assert(r'dedupKey == "pr:$exerciseId:$logId"')
  @Assert('createdAtUtc.isUtc')
  @Assert('deletedAtUtc == null || deletedAtUtc.isUtc')
  factory MilestoneEvent({
    required MilestoneEventId id,
    @Default('pr') String type,
    required ExerciseId exerciseId,
    required LogId logId,
    required double metricValue,
    required String dedupKey,
    @UtcDateTimeConverter() required DateTime createdAtUtc,
    @UtcDateTimeConverter() DateTime? deletedAtUtc,
  }) = _MilestoneEvent;

  factory MilestoneEvent.pr({
    required MilestoneEventId id,
    required ExerciseId exerciseId,
    required LogId logId,
    required double metricValue,
    required DateTime createdAtUtc,
  }) {
    return MilestoneEvent(
      id: id,
      exerciseId: exerciseId,
      logId: logId,
      metricValue: metricValue,
      dedupKey: 'pr:$exerciseId:$logId',
      createdAtUtc: createdAtUtc,
    );
  }

  factory MilestoneEvent.fromJson(Map<String, dynamic> json) =>
      _$MilestoneEventFromJson(json);
}
