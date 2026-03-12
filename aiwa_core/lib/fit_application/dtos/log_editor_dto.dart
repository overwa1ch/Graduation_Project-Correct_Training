import 'block_dto.dart';

class LogEditorDTO {
  final String id;
  final String date;
  final String? boundTaskOccurrenceId;
  final String createdAtUtc;
  final String lastEditedAtUtc;
  final Map<String, dynamic> metadata;
  final List<BlockDTO> blocks;

  LogEditorDTO({
    required this.id,
    required this.date,
    required this.boundTaskOccurrenceId,
    required this.createdAtUtc,
    required this.lastEditedAtUtc,
    Map<String, dynamic> metadata = const <String, dynamic>{},
    required List<BlockDTO> blocks,
  })  : metadata = Map<String, dynamic>.unmodifiable(metadata),
        blocks = List<BlockDTO>.unmodifiable(blocks);

  factory LogEditorDTO.fromJson(Map<String, dynamic> json) => LogEditorDTO(
        id: json['id'] as String,
        date: json['date'] as String,
        boundTaskOccurrenceId: json['boundTaskOccurrenceId'] as String?,
        createdAtUtc: json['createdAtUtc'] as String,
        lastEditedAtUtc: json['lastEditedAtUtc'] as String,
        metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
        blocks: (json['blocks'] as List<dynamic>)
            .map((e) => BlockDTO.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date,
        'boundTaskOccurrenceId': boundTaskOccurrenceId,
        'createdAtUtc': createdAtUtc,
        'lastEditedAtUtc': lastEditedAtUtc,
        'metadata': metadata,
        'blocks': blocks.map((e) => e.toJson()).toList(),
      };
}
