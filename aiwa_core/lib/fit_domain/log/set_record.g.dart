// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SetRecordImpl _$$SetRecordImplFromJson(Map<String, dynamic> json) =>
    _$SetRecordImpl(
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      restSec: (json['restSec'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$SetRecordImplToJson(_$SetRecordImpl instance) =>
    <String, dynamic>{
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'restSec': instance.restSec,
    };
