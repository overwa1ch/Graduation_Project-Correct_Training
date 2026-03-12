// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_ref.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AttachmentRefImpl _$$AttachmentRefImplFromJson(Map<String, dynamic> json) =>
    _$AttachmentRefImpl(
      id: json['id'] as String,
      mediaType: $enumDecode(_$AttachmentMediaTypeEnumMap, json['mediaType']),
      meta: json['meta'] as Map<String, dynamic>?,
      createdAtUtc:
          const UtcDateTimeConverter().fromJson(json['createdAtUtc'] as String),
    );

Map<String, dynamic> _$$AttachmentRefImplToJson(_$AttachmentRefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaType': _$AttachmentMediaTypeEnumMap[instance.mediaType]!,
      'meta': instance.meta,
      'createdAtUtc':
          const UtcDateTimeConverter().toJson(instance.createdAtUtc),
    };

const _$AttachmentMediaTypeEnumMap = {
  AttachmentMediaType.image: 'image',
  AttachmentMediaType.video: 'video',
};
