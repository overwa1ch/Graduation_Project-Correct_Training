// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChecklistItemImpl _$$ChecklistItemImplFromJson(Map<String, dynamic> json) =>
    _$ChecklistItemImpl(
      text: json['text'] as String,
      checked: json['checked'] as bool,
    );

Map<String, dynamic> _$$ChecklistItemImplToJson(_$ChecklistItemImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'checked': instance.checked,
    };

_$TextBlockImpl _$$TextBlockImplFromJson(Map<String, dynamic> json) =>
    _$TextBlockImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$TextBlockImplToJson(_$TextBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'type': instance.$type,
    };

_$HeadingBlockImpl _$$HeadingBlockImplFromJson(Map<String, dynamic> json) =>
    _$HeadingBlockImpl(
      id: json['id'] as String,
      text: json['text'] as String,
      level: (json['level'] as num).toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$HeadingBlockImplToJson(_$HeadingBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'level': instance.level,
      'type': instance.$type,
    };

_$DividerBlockImpl _$$DividerBlockImplFromJson(Map<String, dynamic> json) =>
    _$DividerBlockImpl(
      id: json['id'] as String,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$DividerBlockImplToJson(_$DividerBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.$type,
    };

_$ExerciseBlockImpl _$$ExerciseBlockImplFromJson(Map<String, dynamic> json) =>
    _$ExerciseBlockImpl(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseNameSnapshot: json['exerciseNameSnapshot'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((e) => SetRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
      rpe: (json['rpe'] as num?)?.toDouble(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ExerciseBlockImplToJson(_$ExerciseBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'exerciseNameSnapshot': instance.exerciseNameSnapshot,
      'sets': instance.sets,
      'note': instance.note,
      'rpe': instance.rpe,
      'type': instance.$type,
    };

_$ImageBlockImpl _$$ImageBlockImplFromJson(Map<String, dynamic> json) =>
    _$ImageBlockImpl(
      id: json['id'] as String,
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => AttachmentRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      caption: json['caption'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ImageBlockImplToJson(_$ImageBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'attachments': instance.attachments,
      'caption': instance.caption,
      'type': instance.$type,
    };

_$VideoBlockImpl _$$VideoBlockImplFromJson(Map<String, dynamic> json) =>
    _$VideoBlockImpl(
      id: json['id'] as String,
      attachments: (json['attachments'] as List<dynamic>)
          .map((e) => AttachmentRef.fromJson(e as Map<String, dynamic>))
          .toList(),
      caption: json['caption'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$VideoBlockImplToJson(_$VideoBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'attachments': instance.attachments,
      'caption': instance.caption,
      'type': instance.$type,
    };

_$ChecklistBlockImpl _$$ChecklistBlockImplFromJson(Map<String, dynamic> json) =>
    _$ChecklistBlockImpl(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => ChecklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChecklistBlockImplToJson(
        _$ChecklistBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'items': instance.items,
      'type': instance.$type,
    };

_$TimerMarkerBlockImpl _$$TimerMarkerBlockImplFromJson(
        Map<String, dynamic> json) =>
    _$TimerMarkerBlockImpl(
      id: json['id'] as String,
      kind: $enumDecode(_$TimerKindEnumMap, json['kind']),
      atUtc: const UtcDateTimeConverter().fromJson(json['atUtc'] as String),
      label: json['label'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$TimerMarkerBlockImplToJson(
        _$TimerMarkerBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$TimerKindEnumMap[instance.kind]!,
      'atUtc': const UtcDateTimeConverter().toJson(instance.atUtc),
      'label': instance.label,
      'type': instance.$type,
    };

const _$TimerKindEnumMap = {
  TimerKind.mark: 'mark',
  TimerKind.restStart: 'rest_start',
  TimerKind.restEnd: 'rest_end',
  TimerKind.custom: 'custom',
};

_$ReferenceBlockImpl _$$ReferenceBlockImplFromJson(Map<String, dynamic> json) =>
    _$ReferenceBlockImpl(
      id: json['id'] as String,
      refType: json['refType'] as String,
      refId: json['refId'] as String,
      previewText: json['previewText'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ReferenceBlockImplToJson(
        _$ReferenceBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'refType': instance.refType,
      'refId': instance.refId,
      'previewText': instance.previewText,
      'type': instance.$type,
    };

_$LinkBlockImpl _$$LinkBlockImplFromJson(Map<String, dynamic> json) =>
    _$LinkBlockImpl(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String?,
      note: json['note'] as String?,
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$LinkBlockImplToJson(_$LinkBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'title': instance.title,
      'note': instance.note,
      'type': instance.$type,
    };

_$TableBlockImpl _$$TableBlockImplFromJson(Map<String, dynamic> json) =>
    _$TableBlockImpl(
      id: json['id'] as String,
      columnCount: (json['columnCount'] as num).toInt(),
      rows: (json['rows'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
          .toList(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$TableBlockImplToJson(_$TableBlockImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'columnCount': instance.columnCount,
      'rows': instance.rows,
      'type': instance.$type,
    };
