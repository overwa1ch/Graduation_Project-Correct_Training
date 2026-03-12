import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/date_only.dart';
import '../common/typedef_ids.dart';

part 'attachment_ref.freezed.dart';
part 'attachment_ref.g.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum AttachmentMediaType {
  image,
  video,
}

@freezed
class AttachmentRef with _$AttachmentRef {
  const AttachmentRef._();

  @Assert('id.isNotEmpty')
  @Assert('createdAtUtc.isUtc')
  factory AttachmentRef({
    required AttachmentId id,
    required AttachmentMediaType mediaType,
    Map<String, dynamic>? meta,
    @UtcDateTimeConverter() required DateTime createdAtUtc,
  }) = _AttachmentRef;

  factory AttachmentRef.fromJson(Map<String, dynamic> json) =>
      _$AttachmentRefFromJson(json);
}
