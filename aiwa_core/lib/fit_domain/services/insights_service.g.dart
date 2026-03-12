// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'insights_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PrRecordImpl _$$PrRecordImplFromJson(Map<String, dynamic> json) =>
    _$PrRecordImpl(
      exerciseId: json['exerciseId'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      logId: json['logId'] as String,
      date: const DateOnlyJsonConverter().fromJson(json['date'] as String),
      lastEditedAtUtc: const UtcDateTimeConverter()
          .fromJson(json['lastEditedAtUtc'] as String),
    );

Map<String, dynamic> _$$PrRecordImplToJson(_$PrRecordImpl instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'weightKg': instance.weightKg,
      'logId': instance.logId,
      'date': const DateOnlyJsonConverter().toJson(instance.date),
      'lastEditedAtUtc':
          const UtcDateTimeConverter().toJson(instance.lastEditedAtUtc),
    };
