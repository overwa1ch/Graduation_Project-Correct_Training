class SetRecordDTO {
  final double weightKg;
  final int reps;
  final int? restSec;

  const SetRecordDTO({
    required this.weightKg,
    required this.reps,
    this.restSec,
  });

  factory SetRecordDTO.fromJson(Map<String, dynamic> json) => SetRecordDTO(
        weightKg: (json['weightKg'] as num).toDouble(),
        reps: json['reps'] as int,
        restSec: json['restSec'] as int?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'weightKg': weightKg,
        'reps': reps,
        'restSec': restSec,
      };
}

class AttachmentDTO {
  final String id;
  final String mediaType;
  final Map<String, dynamic>? meta;
  final String createdAtUtc;

  const AttachmentDTO({
    required this.id,
    required this.mediaType,
    this.meta,
    required this.createdAtUtc,
  });

  factory AttachmentDTO.fromJson(Map<String, dynamic> json) => AttachmentDTO(
        id: json['id'] as String,
        mediaType: json['mediaType'] as String,
        meta: (json['meta'] as Map?)?.cast<String, dynamic>(),
        createdAtUtc: json['createdAtUtc'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'mediaType': mediaType,
        'meta': meta,
        'createdAtUtc': createdAtUtc,
      };
}

class ChecklistItemDTO {
  final String text;
  final bool checked;

  const ChecklistItemDTO({
    required this.text,
    required this.checked,
  });

  factory ChecklistItemDTO.fromJson(Map<String, dynamic> json) =>
      ChecklistItemDTO(
        text: json['text'] as String,
        checked: json['checked'] as bool,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'text': text,
        'checked': checked,
      };
}

abstract class BlockDTO {
  String get type;
  String get id;
  Map<String, dynamic> toJson();

  static BlockDTO fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'text_block':
        return TextBlockDTO.fromJson(json);
      case 'heading_block':
        return HeadingBlockDTO.fromJson(json);
      case 'divider_block':
        return DividerBlockDTO.fromJson(json);
      case 'exercise_block':
        return ExerciseBlockDTO.fromJson(json);
      case 'image_block':
        return ImageBlockDTO.fromJson(json);
      case 'video_block':
        return VideoBlockDTO.fromJson(json);
      case 'checklist_block':
        return ChecklistBlockDTO.fromJson(json);
      case 'timer_marker_block':
        return TimerMarkerBlockDTO.fromJson(json);
      case 'reference_block':
        return ReferenceBlockDTO.fromJson(json);
      case 'link_block':
        return LinkBlockDTO.fromJson(json);
      case 'table_block':
        return TableBlockDTO.fromJson(json);
      default:
        throw ArgumentError('Unsupported block type: $type');
    }
  }
}

class TextBlockDTO implements BlockDTO {
  @override
  final String id;
  final String text;

  const TextBlockDTO({
    required this.id,
    required this.text,
  });

  @override
  String get type => 'text_block';

  factory TextBlockDTO.fromJson(Map<String, dynamic> json) => TextBlockDTO(
        id: json['id'] as String,
        text: json['text'] as String,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'text': text,
      };
}

class HeadingBlockDTO implements BlockDTO {
  @override
  final String id;
  final String text;
  final int level;

  const HeadingBlockDTO({
    required this.id,
    required this.text,
    required this.level,
  });

  @override
  String get type => 'heading_block';

  factory HeadingBlockDTO.fromJson(Map<String, dynamic> json) =>
      HeadingBlockDTO(
        id: json['id'] as String,
        text: json['text'] as String,
        level: json['level'] as int,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'text': text,
        'level': level,
      };
}

class DividerBlockDTO implements BlockDTO {
  @override
  final String id;

  const DividerBlockDTO({
    required this.id,
  });

  @override
  String get type => 'divider_block';

  factory DividerBlockDTO.fromJson(Map<String, dynamic> json) =>
      DividerBlockDTO(
        id: json['id'] as String,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
      };
}

class ExerciseBlockDTO implements BlockDTO {
  @override
  final String id;
  final String exerciseId;
  final String exerciseNameSnapshot;
  final List<SetRecordDTO> sets;
  final String? note;
  final double? rpe;

  ExerciseBlockDTO({
    required this.id,
    required this.exerciseId,
    required this.exerciseNameSnapshot,
    required List<SetRecordDTO> sets,
    this.note,
    this.rpe,
  }) : sets = List<SetRecordDTO>.unmodifiable(sets);

  @override
  String get type => 'exercise_block';

  factory ExerciseBlockDTO.fromJson(Map<String, dynamic> json) =>
      ExerciseBlockDTO(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        exerciseNameSnapshot: json['exerciseNameSnapshot'] as String,
        sets: (json['sets'] as List<dynamic>)
            .map((e) =>
                SetRecordDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        note: json['note'] as String?,
        rpe: (json['rpe'] as num?)?.toDouble(),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'exerciseId': exerciseId,
        'exerciseNameSnapshot': exerciseNameSnapshot,
        'sets': sets.map((e) => e.toJson()).toList(),
        'note': note,
        'rpe': rpe,
      };
}

class ImageBlockDTO implements BlockDTO {
  @override
  final String id;
  final List<AttachmentDTO> attachments;
  final String? caption;

  ImageBlockDTO({
    required this.id,
    required List<AttachmentDTO> attachments,
    this.caption,
  }) : attachments = List<AttachmentDTO>.unmodifiable(attachments);

  @override
  String get type => 'image_block';

  factory ImageBlockDTO.fromJson(Map<String, dynamic> json) => ImageBlockDTO(
        id: json['id'] as String,
        attachments: (json['attachments'] as List<dynamic>)
            .map((e) =>
                AttachmentDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        caption: json['caption'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'caption': caption,
      };
}

class VideoBlockDTO implements BlockDTO {
  @override
  final String id;
  final List<AttachmentDTO> attachments;
  final String? caption;

  VideoBlockDTO({
    required this.id,
    required List<AttachmentDTO> attachments,
    this.caption,
  }) : attachments = List<AttachmentDTO>.unmodifiable(attachments);

  @override
  String get type => 'video_block';

  factory VideoBlockDTO.fromJson(Map<String, dynamic> json) => VideoBlockDTO(
        id: json['id'] as String,
        attachments: (json['attachments'] as List<dynamic>)
            .map((e) =>
                AttachmentDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        caption: json['caption'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'caption': caption,
      };
}

class ChecklistBlockDTO implements BlockDTO {
  @override
  final String id;
  final List<ChecklistItemDTO> items;

  ChecklistBlockDTO({
    required this.id,
    required List<ChecklistItemDTO> items,
  }) : items = List<ChecklistItemDTO>.unmodifiable(items);

  @override
  String get type => 'checklist_block';

  factory ChecklistBlockDTO.fromJson(Map<String, dynamic> json) =>
      ChecklistBlockDTO(
        id: json['id'] as String,
        items: (json['items'] as List<dynamic>)
            .map((e) =>
                ChecklistItemDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class TimerMarkerBlockDTO implements BlockDTO {
  @override
  final String id;
  final String kind;
  final String atUtc;
  final String? label;

  const TimerMarkerBlockDTO({
    required this.id,
    required this.kind,
    required this.atUtc,
    this.label,
  });

  @override
  String get type => 'timer_marker_block';

  factory TimerMarkerBlockDTO.fromJson(Map<String, dynamic> json) =>
      TimerMarkerBlockDTO(
        id: json['id'] as String,
        kind: json['kind'] as String,
        atUtc: json['atUtc'] as String,
        label: json['label'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'kind': kind,
        'atUtc': atUtc,
        'label': label,
      };
}

class ReferenceBlockDTO implements BlockDTO {
  @override
  final String id;
  final String refType;
  final String refId;
  final String? previewText;

  const ReferenceBlockDTO({
    required this.id,
    required this.refType,
    required this.refId,
    this.previewText,
  });

  @override
  String get type => 'reference_block';

  factory ReferenceBlockDTO.fromJson(Map<String, dynamic> json) =>
      ReferenceBlockDTO(
        id: json['id'] as String,
        refType: json['refType'] as String,
        refId: json['refId'] as String,
        previewText: json['previewText'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'refType': refType,
        'refId': refId,
        'previewText': previewText,
      };
}

class LinkBlockDTO implements BlockDTO {
  @override
  final String id;
  final String url;
  final String? title;
  final String? note;

  const LinkBlockDTO({
    required this.id,
    required this.url,
    this.title,
    this.note,
  });

  @override
  String get type => 'link_block';

  factory LinkBlockDTO.fromJson(Map<String, dynamic> json) => LinkBlockDTO(
        id: json['id'] as String,
        url: json['url'] as String,
        title: json['title'] as String?,
        note: json['note'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'url': url,
        'title': title,
        'note': note,
      };
}

class TableBlockDTO implements BlockDTO {
  @override
  final String id;
  final int columnCount;
  final List<List<String>> rows;

  TableBlockDTO({
    required this.id,
    required this.columnCount,
    required List<List<String>> rows,
  }) : rows = List<List<String>>.unmodifiable(
          rows
              .map((row) => List<String>.unmodifiable(row))
              .toList(growable: false),
        );

  @override
  String get type => 'table_block';

  factory TableBlockDTO.fromJson(Map<String, dynamic> json) => TableBlockDTO(
        id: json['id'] as String,
        columnCount: json['columnCount'] as int? ?? json['columns'] as int,
        rows: (json['rows'] as List<dynamic>? ?? const <dynamic>[])
            .map(
              (row) => (row as List<dynamic>)
                  .map((cell) => (cell as String?) ?? '')
                  .toList(growable: false),
            )
            .toList(growable: false),
      );

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'id': id,
        'columnCount': columnCount,
        'rows': rows
            .map((row) => List<String>.from(row, growable: false))
            .toList(growable: false),
      };
}
