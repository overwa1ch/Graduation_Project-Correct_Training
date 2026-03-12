// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'milestone_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MilestoneEventImpl _$$MilestoneEventImplFromJson(Map<String, dynamic> json) =>
    _$MilestoneEventImpl(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'pr',
      exerciseId: json['exerciseId'] as String,
      logId: json['logId'] as String,
      metricValue: (json['metricValue'] as num).toDouble(),
      dedupKey: json['dedupKey'] as String,
      createdAtUtc:
          const UtcDateTimeConverter().fromJson(json['createdAtUtc'] as String),
      deletedAtUtc: _$JsonConverterFromJson<String, DateTime>(
          json['deletedAtUtc'], const UtcDateTimeConverter().fromJson),
    );

Map<String, dynamic> _$$MilestoneEventImplToJson(
        _$MilestoneEventImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'exerciseId': instance.exerciseId,
      'logId': instance.logId,
      'metricValue': instance.metricValue,
      'dedupKey': instance.dedupKey,
      'createdAtUtc':
          const UtcDateTimeConverter().toJson(instance.createdAtUtc),
      'deletedAtUtc': _$JsonConverterToJson<String, DateTime>(
          instance.deletedAtUtc, const UtcDateTimeConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
