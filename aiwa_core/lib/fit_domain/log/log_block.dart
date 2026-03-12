import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/date_only.dart';
import '../common/typedef_ids.dart';
import 'attachment_ref.dart';
import 'set_record.dart';

part 'log_block.freezed.dart';
part 'log_block.g.dart';

@freezed
class ChecklistItem with _$ChecklistItem {
  const ChecklistItem._();

  factory ChecklistItem({
    required String text,
    required bool checked,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum TimerKind {
  mark,
  restStart,
  restEnd,
  custom,
}

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.snake)
class LogBlock with _$LogBlock {
  const LogBlock._();

  @Assert('id.isNotEmpty')
  factory LogBlock.textBlock({
    required BlockId id,
    required String text,
  }) = TextBlock;

  @Assert('id.isNotEmpty')
  @Assert('level >= 1 && level <= 3')
  factory LogBlock.headingBlock({
    required BlockId id,
    required String text,
    required int level,
  }) = HeadingBlock;

  @Assert('id.isNotEmpty')
  factory LogBlock.dividerBlock({
    required BlockId id,
  }) = DividerBlock;

  @Assert('id.isNotEmpty')
  @Assert('exerciseId.isNotEmpty')
  @Assert('rpe == null || (rpe >= 0 && rpe <= 10)')
  factory LogBlock.exerciseBlock({
    required BlockId id,
    required ExerciseId exerciseId,
    required String exerciseNameSnapshot,
    required List<SetRecord> sets,
    String? note,
    double? rpe,
  }) = ExerciseBlock;

  @Assert('id.isNotEmpty')
  @Assert('attachments.length >= 1')
  factory LogBlock.imageBlock({
    required BlockId id,
    required List<AttachmentRef> attachments,
    String? caption,
  }) = ImageBlock;

  @Assert('id.isNotEmpty')
  @Assert('attachments.length >= 1')
  factory LogBlock.videoBlock({
    required BlockId id,
    required List<AttachmentRef> attachments,
    String? caption,
  }) = VideoBlock;

  @Assert('id.isNotEmpty')
  factory LogBlock.checklistBlock({
    required BlockId id,
    required List<ChecklistItem> items,
  }) = ChecklistBlock;

  @Assert('id.isNotEmpty')
  @Assert('atUtc.isUtc')
  factory LogBlock.timerMarkerBlock({
    required BlockId id,
    required TimerKind kind,
    @UtcDateTimeConverter() required DateTime atUtc,
    String? label,
  }) = TimerMarkerBlock;

  @Assert('id.isNotEmpty')
  factory LogBlock.referenceBlock({
    required BlockId id,
    required String refType,
    required String refId,
    String? previewText,
  }) = ReferenceBlock;

  @Assert('id.isNotEmpty')
  factory LogBlock.linkBlock({
    required BlockId id,
    required String url,
    String? title,
    String? note,
  }) = LinkBlock;

  @Assert('id.isNotEmpty')
  @Assert('columnCount >= 1')
  factory LogBlock.tableBlock({
    required BlockId id,
    required int columnCount,
    required List<List<String>> rows,
  }) = TableBlock;

  factory LogBlock.fromJson(Map<String, dynamic> json) =>
      _$LogBlockFromJson(json);
}
