import 'package:aiwa_core/fit_application/fit_application.dart';

import 'package:aiwa_app/services/exercise/exercise_library_service.dart';
import 'package:aiwa_app/ui/widgets/appflowy_block_dto_codec.dart';
import 'package:aiwa_app/ui/widgets/rich_text_document_codec.dart';

class TaskTemplatePayloadSnapshot {
  const TaskTemplatePayloadSnapshot({
    required this.title,
    required this.body,
    required this.blocks,
    required this.payload,
  });

  final String title;
  final String body;
  final List<BlockDTO> blocks;
  final Map<String, dynamic> payload;
}

class TaskTemplateActionProgressionConfig {
  const TaskTemplateActionProgressionConfig({
    required this.exerciseId,
    required this.targetWeightKg,
    required this.openingPercent,
    required this.endingPercent,
    required this.incrementWeightKg,
  });

  static const double defaultOpeningPercent = 65.0;
  static const double defaultEndingPercent = 95.0;
  static const double defaultIncrementWeightKg = 2.5;

  final String exerciseId;
  final double targetWeightKg;
  final double openingPercent;
  final double endingPercent;
  final double incrementWeightKg;

  factory TaskTemplateActionProgressionConfig.defaultsFor(ExerciseEntry entry) {
    final target = normalizeExerciseWeight(
      deriveTargetWeightFromRecords(entry.records),
    );
    return TaskTemplateActionProgressionConfig(
      exerciseId: entry.id,
      targetWeightKg: target,
      openingPercent: defaultOpeningPercent,
      endingPercent: defaultEndingPercent,
      incrementWeightKg: defaultIncrementWeightKg,
    );
  }

  factory TaskTemplateActionProgressionConfig.fromJson(
    Map<String, dynamic> json,
  ) {
    return TaskTemplateActionProgressionConfig(
      exerciseId: json['exerciseId'] as String? ?? '',
      targetWeightKg: normalizeExerciseWeight(
        (json['targetWeightKg'] as num?)?.toDouble() ?? 0,
      ),
      openingPercent: normalizeExerciseWeight(
        (json['openingPercent'] as num?)?.toDouble() ?? defaultOpeningPercent,
      ),
      endingPercent: normalizeExerciseWeight(
        (json['endingPercent'] as num?)?.toDouble() ?? defaultEndingPercent,
      ),
      incrementWeightKg: normalizeExerciseWeight(
        (json['incrementWeightKg'] as num?)?.toDouble() ??
            defaultIncrementWeightKg,
      ),
    );
  }

  TaskTemplateActionProgressionConfig copyWith({
    String? exerciseId,
    double? targetWeightKg,
    double? openingPercent,
    double? endingPercent,
    double? incrementWeightKg,
  }) {
    return TaskTemplateActionProgressionConfig(
      exerciseId: exerciseId ?? this.exerciseId,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      openingPercent: openingPercent ?? this.openingPercent,
      endingPercent: endingPercent ?? this.endingPercent,
      incrementWeightKg: incrementWeightKg ?? this.incrementWeightKg,
    );
  }

  double get openingWeightKg => normalizeExerciseWeight(
        targetWeightKg * openingPercent / 100,
      );

  double get endingWeightKg => normalizeExerciseWeight(
        targetWeightKg * endingPercent / 100,
      );

  bool get isConfigured {
    return exerciseId.trim().isNotEmpty &&
        targetWeightKg > 0 &&
        openingPercent > 0 &&
        endingPercent >= openingPercent &&
        incrementWeightKg > 0;
  }

  List<double> buildProgression() {
    return buildWeightProgression(
      startWeightKg: openingWeightKg,
      endWeightKg: endingWeightKg,
      incrementWeightKg: incrementWeightKg,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'exerciseId': exerciseId,
        'targetWeightKg': targetWeightKg,
        'openingPercent': openingPercent,
        'endingPercent': endingPercent,
        'incrementWeightKg': incrementWeightKg,
      };
}

List<TaskTemplateActionProgressionConfig> parseTaskTemplateActionProgressions(
  Map<String, dynamic>? payload,
) {
  if (payload == null) {
    return const <TaskTemplateActionProgressionConfig>[];
  }
  final raw = payload['actionProgressions'];
  if (raw is! Iterable) {
    return const <TaskTemplateActionProgressionConfig>[];
  }
  return raw
      .whereType<Map<dynamic, dynamic>>()
      .map((item) {
        return TaskTemplateActionProgressionConfig.fromJson(
          Map<String, dynamic>.from(item),
        );
      })
      .where((item) => item.exerciseId.trim().isNotEmpty)
      .toList(growable: false);
}

Map<String, String> extractExerciseLibraryActionLabels(Iterable<BlockDTO> blocks) {
  final labels = <String, String>{};
  for (final block in blocks) {
    if (block is! LinkBlockDTO) {
      continue;
    }
    final exerciseId = parseExerciseLibraryLinkId(block.url);
    if (exerciseId == null || labels.containsKey(exerciseId)) {
      continue;
    }
    labels[exerciseId] = (block.title ?? '').trim();
  }
  return labels;
}

List<String> extractExerciseLibraryActionIds(Iterable<BlockDTO> blocks) {
  return extractExerciseLibraryActionLabels(blocks).keys.toList(growable: false);
}

List<BlockDTO> parseTaskTemplateBlocksFromPayload(
  Map<String, dynamic>? payload, {
  required String title,
}) {
  if (payload == null) {
    return buildTaskTemplateBlocks(title: title, body: '');
  }

  final rawBlocks = payload['taskBlocks'];
  if (rawBlocks is Iterable) {
    final blocks = rawBlocks
        .whereType<Map<dynamic, dynamic>>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map(BlockDTO.fromJson)
        .toList();
    if (blocks.isNotEmpty) {
      return blocks;
    }
  }

  final rawBody = payload['taskBody'];
  if (rawBody is String && rawBody.trim().isNotEmpty) {
    return buildTaskTemplateBlocks(title: title, body: rawBody);
  }

  final rawNote = payload['taskNote'];
  if (rawNote is String && rawNote.trim().isNotEmpty) {
    return buildTaskTemplateBlocks(title: title, body: rawNote);
  }

  return buildTaskTemplateBlocks(title: title, body: '');
}

TaskTemplatePayloadSnapshot normalizeTaskTemplatePayload(
  Map<String, dynamic>? payload, {
  required String title,
}) {
  final normalizedPayload = Map<String, dynamic>.from(
    payload ?? const <String, dynamic>{},
  );
  final body = readTaskTemplateBodyFromPayload(normalizedPayload, title: title);
  final blocks = parseTaskTemplateBlocksFromPayload(
    normalizedPayload,
    title: title,
  );

  normalizedPayload.addAll(
    buildTaskTemplatePayload(
      title: title,
      body: body,
      basePayload: normalizedPayload,
    ),
  );

  return TaskTemplatePayloadSnapshot(
    title: title,
    body: body,
    blocks: blocks,
    payload: normalizedPayload,
  );
}

List<BlockDTO> extractTaskTemplateEditorBlocks(Iterable<BlockDTO> blocks) {
  final values = List<BlockDTO>.from(blocks);
  if (values.isNotEmpty && values.first is HeadingBlockDTO) {
    return values.skip(1).toList(growable: false);
  }
  return values;
}

List<BlockDTO> composeTaskTemplateBlocks({
  required String title,
  required Iterable<BlockDTO> bodyBlocks,
}) {
  final blocks = <BlockDTO>[];
  final trimmedTitle = title.trim();
  if (trimmedTitle.isNotEmpty) {
    blocks.add(
      HeadingBlockDTO(
        id: 'heading_${DateTime.now().microsecondsSinceEpoch}',
        text: trimmedTitle,
        level: 1,
      ),
    );
  }
  blocks.addAll(bodyBlocks);
  return blocks;
}

String readTaskTemplateBodyFromPayload(
  Map<String, dynamic>? payload, {
  required String title,
}) {
  if (payload == null) {
    return '';
  }

  final rawBody = payload['taskBody'];
  if (rawBody is String && rawBody.trim().isNotEmpty) {
    return rawBody;
  }

  return buildTaskTemplateBodyFromBlocks(
    parseTaskTemplateBlocksFromPayload(payload, title: title),
  );
}

Map<String, dynamic> buildTaskTemplatePayload({
  required String title,
  required String body,
  Map<String, dynamic>? basePayload,
}) {
  final payload =
      Map<String, dynamic>.from(basePayload ?? const <String, dynamic>{});
  final normalizedBody = body.trim();

  payload['taskBody'] = body;
  payload['taskBlocks'] = buildTaskTemplateBlocks(
    title: title,
    body: body,
  ).map((block) => block.toJson()).toList();
  payload['taskNote'] = normalizedBody.isEmpty
      ? ''
      : describeRichTextDocument(parseRichTextDocument(body));

  return payload;
}

Map<String, dynamic> buildTaskTemplatePayloadFromBlocks({
  required String title,
  required Iterable<BlockDTO> bodyBlocks,
  Map<String, dynamic>? basePayload,
}) {
  final payload =
      Map<String, dynamic>.from(basePayload ?? const <String, dynamic>{});
  final blocks =
      composeTaskTemplateBlocks(title: title, bodyBlocks: bodyBlocks);

  payload['taskBody'] = buildTaskTemplateBodyFromBlocks(blocks);
  payload['taskBlocks'] = blocks.map((block) => block.toJson()).toList();
  payload['taskNote'] = describeTaskTemplateBlocks(blocks);

  return payload;
}

String describeTaskTemplateBlocks(Iterable<BlockDTO> blocks) {
  final buffer = <String>[];
  for (final block in extractTaskTemplateEditorBlocks(blocks)) {
    final summary = describeBlockDto(block).trim();
    if (summary.isNotEmpty) {
      buffer.add(summary);
    }
  }
  return buffer.join('\n').trim();
}
