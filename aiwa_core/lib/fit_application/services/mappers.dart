import 'package:aiwa_core/fit_domain/fit_domain.dart';

import '../dtos/block_dto.dart';
import '../dtos/exercise_dto.dart';
import '../dtos/exercise_pr_dto.dart';
import '../dtos/log_editor_dto.dart';
import '../dtos/pr_summary_dto.dart';
import '../dtos/tag_dto.dart';

class ApplicationMappers {
  static LogEditorDTO toLogEditorDTO(WorkoutLog log) => LogEditorDTO(
        id: log.id,
        date: log.date.toString(),
        boundTaskOccurrenceId: log.boundTaskOccurrenceId,
        createdAtUtc: log.createdAtUtc.toIso8601String(),
        lastEditedAtUtc: log.lastEditedAtUtc.toIso8601String(),
        metadata: log.metadata,
        blocks: log.blocks.map(toBlockDTO).toList(),
      );

  static ExerciseDTO toExerciseDTO(Exercise exercise) => ExerciseDTO(
        id: exercise.id,
        name: exercise.name,
        tagIds: exercise.tagIds.toList(),
        deprecated: exercise.deprecated,
      );

  static TagDTO toTagDTO(Tag tag) => TagDTO(
        id: tag.id,
        name: tag.name,
      );

  static ExercisePRDTO toExercisePrDTO(PrRecord record) => ExercisePRDTO(
        exerciseId: record.exerciseId,
        prWeightKg: record.weightKg,
        achievedOnDate: record.date,
        achievedInLogId: record.logId,
      );

  static PRSummaryDTO toPRSummaryDTO(
    List<ExercisePRDTO> prs,
    DateTime computedAtUtc,
  ) =>
      PRSummaryDTO(
        prs: prs,
        computedAtUtc: computedAtUtc.toUtc(),
      );

  static LogBlock toDomainBlock(BlockDTO dto) {
    if (dto is TextBlockDTO) {
      return LogBlock.textBlock(id: dto.id, text: dto.text);
    }
    if (dto is HeadingBlockDTO) {
      return LogBlock.headingBlock(
        id: dto.id,
        text: dto.text,
        level: dto.level,
      );
    }
    if (dto is DividerBlockDTO) {
      return LogBlock.dividerBlock(id: dto.id);
    }
    if (dto is ExerciseBlockDTO) {
      return LogBlock.exerciseBlock(
        id: dto.id,
        exerciseId: dto.exerciseId,
        exerciseNameSnapshot: dto.exerciseNameSnapshot,
        sets: dto.sets.map(toDomainSet).toList(),
        note: dto.note,
        rpe: dto.rpe,
      );
    }
    if (dto is ImageBlockDTO) {
      return LogBlock.imageBlock(
        id: dto.id,
        attachments: dto.attachments.map(toDomainAttachment).toList(),
        caption: dto.caption,
      );
    }
    if (dto is VideoBlockDTO) {
      return LogBlock.videoBlock(
        id: dto.id,
        attachments: dto.attachments.map(toDomainAttachment).toList(),
        caption: dto.caption,
      );
    }
    if (dto is ChecklistBlockDTO) {
      return LogBlock.checklistBlock(
        id: dto.id,
        items: dto.items
            .map((e) => ChecklistItem(text: e.text, checked: e.checked))
            .toList(),
      );
    }
    if (dto is TimerMarkerBlockDTO) {
      return LogBlock.timerMarkerBlock(
        id: dto.id,
        kind: _toTimerKind(dto.kind),
        atUtc: DateTime.parse(dto.atUtc).toUtc(),
        label: dto.label,
      );
    }
    if (dto is ReferenceBlockDTO) {
      return LogBlock.referenceBlock(
        id: dto.id,
        refType: dto.refType,
        refId: dto.refId,
        previewText: dto.previewText,
      );
    }
    if (dto is LinkBlockDTO) {
      return LogBlock.linkBlock(
        id: dto.id,
        url: dto.url,
        title: dto.title,
        note: dto.note,
      );
    }
    if (dto is TableBlockDTO) {
      return LogBlock.tableBlock(
        id: dto.id,
        columnCount: dto.columnCount,
        rows: dto.rows,
      );
    }
    throw ArgumentError('Unsupported BlockDTO: ${dto.runtimeType}');
  }

  static BlockDTO toBlockDTO(LogBlock block) => block.map(
        textBlock: (b) => TextBlockDTO(id: b.id, text: b.text),
        headingBlock: (b) => HeadingBlockDTO(
          id: b.id,
          text: b.text,
          level: b.level,
        ),
        dividerBlock: (b) => DividerBlockDTO(id: b.id),
        exerciseBlock: (b) => ExerciseBlockDTO(
          id: b.id,
          exerciseId: b.exerciseId,
          exerciseNameSnapshot: b.exerciseNameSnapshot,
          sets: b.sets.map(toSetRecordDTO).toList(),
          note: b.note,
          rpe: b.rpe,
        ),
        imageBlock: (b) => ImageBlockDTO(
          id: b.id,
          attachments: b.attachments.map(toAttachmentDTO).toList(),
          caption: b.caption,
        ),
        videoBlock: (b) => VideoBlockDTO(
          id: b.id,
          attachments: b.attachments.map(toAttachmentDTO).toList(),
          caption: b.caption,
        ),
        checklistBlock: (b) => ChecklistBlockDTO(
          id: b.id,
          items: b.items
              .map((e) => ChecklistItemDTO(text: e.text, checked: e.checked))
              .toList(),
        ),
        timerMarkerBlock: (b) => TimerMarkerBlockDTO(
          id: b.id,
          kind: _fromTimerKind(b.kind),
          atUtc: b.atUtc.toIso8601String(),
          label: b.label,
        ),
        referenceBlock: (b) => ReferenceBlockDTO(
          id: b.id,
          refType: b.refType,
          refId: b.refId,
          previewText: b.previewText,
        ),
        linkBlock: (b) => LinkBlockDTO(
          id: b.id,
          url: b.url,
          title: b.title,
          note: b.note,
        ),
        tableBlock: (b) => TableBlockDTO(
          id: b.id,
          columnCount: b.columnCount,
          rows: b.rows,
        ),
      );

  static SetRecord toDomainSet(SetRecordDTO dto) => SetRecord(
        weightKg: dto.weightKg,
        reps: dto.reps,
        restSec: dto.restSec,
      );

  static SetRecordDTO toSetRecordDTO(SetRecord set) => SetRecordDTO(
        weightKg: set.weightKg,
        reps: set.reps,
        restSec: set.restSec,
      );

  static AttachmentRef toDomainAttachment(AttachmentDTO dto) => AttachmentRef(
        id: dto.id,
        mediaType: _toMediaType(dto.mediaType),
        meta: dto.meta,
        createdAtUtc: DateTime.parse(dto.createdAtUtc).toUtc(),
      );

  static AttachmentDTO toAttachmentDTO(AttachmentRef ref) => AttachmentDTO(
        id: ref.id,
        mediaType: ref.mediaType.name,
        meta: ref.meta,
        createdAtUtc: ref.createdAtUtc.toIso8601String(),
      );

  static TimerKind _toTimerKind(String value) {
    switch (value) {
      case 'mark':
        return TimerKind.mark;
      case 'rest_start':
        return TimerKind.restStart;
      case 'rest_end':
        return TimerKind.restEnd;
      case 'custom':
        return TimerKind.custom;
      default:
        throw ArgumentError('Unsupported timer kind: $value');
    }
  }

  static String _fromTimerKind(TimerKind value) {
    switch (value) {
      case TimerKind.mark:
        return 'mark';
      case TimerKind.restStart:
        return 'rest_start';
      case TimerKind.restEnd:
        return 'rest_end';
      case TimerKind.custom:
        return 'custom';
    }
  }

  static AttachmentMediaType _toMediaType(String value) {
    switch (value) {
      case 'image':
        return AttachmentMediaType.image;
      case 'video':
        return AttachmentMediaType.video;
      default:
        throw ArgumentError('Unsupported media type: $value');
    }
  }
}
