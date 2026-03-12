// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChecklistItem _$ChecklistItemFromJson(Map<String, dynamic> json) {
  return _ChecklistItem.fromJson(json);
}

/// @nodoc
mixin _$ChecklistItem {
  String get text => throw _privateConstructorUsedError;
  bool get checked => throw _privateConstructorUsedError;

  /// Serializes this ChecklistItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChecklistItemCopyWith<ChecklistItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChecklistItemCopyWith<$Res> {
  factory $ChecklistItemCopyWith(
          ChecklistItem value, $Res Function(ChecklistItem) then) =
      _$ChecklistItemCopyWithImpl<$Res, ChecklistItem>;
  @useResult
  $Res call({String text, bool checked});
}

/// @nodoc
class _$ChecklistItemCopyWithImpl<$Res, $Val extends ChecklistItem>
    implements $ChecklistItemCopyWith<$Res> {
  _$ChecklistItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? checked = null,
  }) {
    return _then(_value.copyWith(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      checked: null == checked
          ? _value.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChecklistItemImplCopyWith<$Res>
    implements $ChecklistItemCopyWith<$Res> {
  factory _$$ChecklistItemImplCopyWith(
          _$ChecklistItemImpl value, $Res Function(_$ChecklistItemImpl) then) =
      __$$ChecklistItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String text, bool checked});
}

/// @nodoc
class __$$ChecklistItemImplCopyWithImpl<$Res>
    extends _$ChecklistItemCopyWithImpl<$Res, _$ChecklistItemImpl>
    implements _$$ChecklistItemImplCopyWith<$Res> {
  __$$ChecklistItemImplCopyWithImpl(
      _$ChecklistItemImpl _value, $Res Function(_$ChecklistItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
    Object? checked = null,
  }) {
    return _then(_$ChecklistItemImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      checked: null == checked
          ? _value.checked
          : checked // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChecklistItemImpl extends _ChecklistItem {
  _$ChecklistItemImpl({required this.text, required this.checked}) : super._();

  factory _$ChecklistItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChecklistItemImplFromJson(json);

  @override
  final String text;
  @override
  final bool checked;

  @override
  String toString() {
    return 'ChecklistItem(text: $text, checked: $checked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChecklistItemImpl &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.checked, checked) || other.checked == checked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, text, checked);

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChecklistItemImplCopyWith<_$ChecklistItemImpl> get copyWith =>
      __$$ChecklistItemImplCopyWithImpl<_$ChecklistItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChecklistItemImplToJson(
      this,
    );
  }
}

abstract class _ChecklistItem extends ChecklistItem {
  factory _ChecklistItem(
      {required final String text,
      required final bool checked}) = _$ChecklistItemImpl;
  _ChecklistItem._() : super._();

  factory _ChecklistItem.fromJson(Map<String, dynamic> json) =
      _$ChecklistItemImpl.fromJson;

  @override
  String get text;
  @override
  bool get checked;

  /// Create a copy of ChecklistItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChecklistItemImplCopyWith<_$ChecklistItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

LogBlock _$LogBlockFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'text_block':
      return TextBlock.fromJson(json);
    case 'heading_block':
      return HeadingBlock.fromJson(json);
    case 'divider_block':
      return DividerBlock.fromJson(json);
    case 'exercise_block':
      return ExerciseBlock.fromJson(json);
    case 'image_block':
      return ImageBlock.fromJson(json);
    case 'video_block':
      return VideoBlock.fromJson(json);
    case 'checklist_block':
      return ChecklistBlock.fromJson(json);
    case 'timer_marker_block':
      return TimerMarkerBlock.fromJson(json);
    case 'reference_block':
      return ReferenceBlock.fromJson(json);
    case 'link_block':
      return LinkBlock.fromJson(json);
    case 'table_block':
      return TableBlock.fromJson(json);

    default:
      throw CheckedFromJsonException(
          json, 'type', 'LogBlock', 'Invalid union type "${json['type']}"!');
  }
}

/// @nodoc
mixin _$LogBlock {
  String get id => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;

  /// Serializes this LogBlock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LogBlockCopyWith<LogBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LogBlockCopyWith<$Res> {
  factory $LogBlockCopyWith(LogBlock value, $Res Function(LogBlock) then) =
      _$LogBlockCopyWithImpl<$Res, LogBlock>;
  @useResult
  $Res call({String id});
}

/// @nodoc
class _$LogBlockCopyWithImpl<$Res, $Val extends LogBlock>
    implements $LogBlockCopyWith<$Res> {
  _$LogBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TextBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$TextBlockImplCopyWith(
          _$TextBlockImpl value, $Res Function(_$TextBlockImpl) then) =
      __$$TextBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String text});
}

/// @nodoc
class __$$TextBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$TextBlockImpl>
    implements _$$TextBlockImplCopyWith<$Res> {
  __$$TextBlockImplCopyWithImpl(
      _$TextBlockImpl _value, $Res Function(_$TextBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
  }) {
    return _then(_$TextBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TextBlockImpl extends TextBlock {
  _$TextBlockImpl({required this.id, required this.text, final String? $type})
      : assert(id.isNotEmpty),
        $type = $type ?? 'text_block',
        super._();

  factory _$TextBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$TextBlockImplFromJson(json);

  @override
  final String id;
  @override
  final String text;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.textBlock(id: $id, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, text);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TextBlockImplCopyWith<_$TextBlockImpl> get copyWith =>
      __$$TextBlockImplCopyWithImpl<_$TextBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return textBlock(id, text);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return textBlock?.call(id, text);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (textBlock != null) {
      return textBlock(id, text);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return textBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return textBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (textBlock != null) {
      return textBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TextBlockImplToJson(
      this,
    );
  }
}

abstract class TextBlock extends LogBlock {
  factory TextBlock({required final String id, required final String text}) =
      _$TextBlockImpl;
  TextBlock._() : super._();

  factory TextBlock.fromJson(Map<String, dynamic> json) =
      _$TextBlockImpl.fromJson;

  @override
  String get id;
  String get text;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TextBlockImplCopyWith<_$TextBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HeadingBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$HeadingBlockImplCopyWith(
          _$HeadingBlockImpl value, $Res Function(_$HeadingBlockImpl) then) =
      __$$HeadingBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String text, int level});
}

/// @nodoc
class __$$HeadingBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$HeadingBlockImpl>
    implements _$$HeadingBlockImplCopyWith<$Res> {
  __$$HeadingBlockImplCopyWithImpl(
      _$HeadingBlockImpl _value, $Res Function(_$HeadingBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? level = null,
  }) {
    return _then(_$HeadingBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HeadingBlockImpl extends HeadingBlock {
  _$HeadingBlockImpl(
      {required this.id,
      required this.text,
      required this.level,
      final String? $type})
      : assert(id.isNotEmpty),
        assert(level >= 1 && level <= 3),
        $type = $type ?? 'heading_block',
        super._();

  factory _$HeadingBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$HeadingBlockImplFromJson(json);

  @override
  final String id;
  @override
  final String text;
  @override
  final int level;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.headingBlock(id: $id, text: $text, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeadingBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.level, level) || other.level == level));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, text, level);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HeadingBlockImplCopyWith<_$HeadingBlockImpl> get copyWith =>
      __$$HeadingBlockImplCopyWithImpl<_$HeadingBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return headingBlock(id, text, level);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return headingBlock?.call(id, text, level);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (headingBlock != null) {
      return headingBlock(id, text, level);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return headingBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return headingBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (headingBlock != null) {
      return headingBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$HeadingBlockImplToJson(
      this,
    );
  }
}

abstract class HeadingBlock extends LogBlock {
  factory HeadingBlock(
      {required final String id,
      required final String text,
      required final int level}) = _$HeadingBlockImpl;
  HeadingBlock._() : super._();

  factory HeadingBlock.fromJson(Map<String, dynamic> json) =
      _$HeadingBlockImpl.fromJson;

  @override
  String get id;
  String get text;
  int get level;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HeadingBlockImplCopyWith<_$HeadingBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$DividerBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$DividerBlockImplCopyWith(
          _$DividerBlockImpl value, $Res Function(_$DividerBlockImpl) then) =
      __$$DividerBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id});
}

/// @nodoc
class __$$DividerBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$DividerBlockImpl>
    implements _$$DividerBlockImplCopyWith<$Res> {
  __$$DividerBlockImplCopyWithImpl(
      _$DividerBlockImpl _value, $Res Function(_$DividerBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
  }) {
    return _then(_$DividerBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DividerBlockImpl extends DividerBlock {
  _$DividerBlockImpl({required this.id, final String? $type})
      : assert(id.isNotEmpty),
        $type = $type ?? 'divider_block',
        super._();

  factory _$DividerBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$DividerBlockImplFromJson(json);

  @override
  final String id;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.dividerBlock(id: $id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DividerBlockImpl &&
            (identical(other.id, id) || other.id == id));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DividerBlockImplCopyWith<_$DividerBlockImpl> get copyWith =>
      __$$DividerBlockImplCopyWithImpl<_$DividerBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return dividerBlock(id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return dividerBlock?.call(id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (dividerBlock != null) {
      return dividerBlock(id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return dividerBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return dividerBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (dividerBlock != null) {
      return dividerBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$DividerBlockImplToJson(
      this,
    );
  }
}

abstract class DividerBlock extends LogBlock {
  factory DividerBlock({required final String id}) = _$DividerBlockImpl;
  DividerBlock._() : super._();

  factory DividerBlock.fromJson(Map<String, dynamic> json) =
      _$DividerBlockImpl.fromJson;

  @override
  String get id;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DividerBlockImplCopyWith<_$DividerBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ExerciseBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$ExerciseBlockImplCopyWith(
          _$ExerciseBlockImpl value, $Res Function(_$ExerciseBlockImpl) then) =
      __$$ExerciseBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String exerciseId,
      String exerciseNameSnapshot,
      List<SetRecord> sets,
      String? note,
      double? rpe});
}

/// @nodoc
class __$$ExerciseBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$ExerciseBlockImpl>
    implements _$$ExerciseBlockImplCopyWith<$Res> {
  __$$ExerciseBlockImplCopyWithImpl(
      _$ExerciseBlockImpl _value, $Res Function(_$ExerciseBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseId = null,
    Object? exerciseNameSnapshot = null,
    Object? sets = null,
    Object? note = freezed,
    Object? rpe = freezed,
  }) {
    return _then(_$ExerciseBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseNameSnapshot: null == exerciseNameSnapshot
          ? _value.exerciseNameSnapshot
          : exerciseNameSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<SetRecord>,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      rpe: freezed == rpe
          ? _value.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExerciseBlockImpl extends ExerciseBlock {
  _$ExerciseBlockImpl(
      {required this.id,
      required this.exerciseId,
      required this.exerciseNameSnapshot,
      required final List<SetRecord> sets,
      this.note,
      this.rpe,
      final String? $type})
      : assert(id.isNotEmpty),
        assert(exerciseId.isNotEmpty),
        assert(rpe == null || (rpe >= 0 && rpe <= 10)),
        _sets = sets,
        $type = $type ?? 'exercise_block',
        super._();

  factory _$ExerciseBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExerciseBlockImplFromJson(json);

  @override
  final String id;
  @override
  final String exerciseId;
  @override
  final String exerciseNameSnapshot;
  final List<SetRecord> _sets;
  @override
  List<SetRecord> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  final String? note;
  @override
  final double? rpe;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.exerciseBlock(id: $id, exerciseId: $exerciseId, exerciseNameSnapshot: $exerciseNameSnapshot, sets: $sets, note: $note, rpe: $rpe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExerciseBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.exerciseNameSnapshot, exerciseNameSnapshot) ||
                other.exerciseNameSnapshot == exerciseNameSnapshot) &&
            const DeepCollectionEquality().equals(other._sets, _sets) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.rpe, rpe) || other.rpe == rpe));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      exerciseId,
      exerciseNameSnapshot,
      const DeepCollectionEquality().hash(_sets),
      note,
      rpe);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExerciseBlockImplCopyWith<_$ExerciseBlockImpl> get copyWith =>
      __$$ExerciseBlockImplCopyWithImpl<_$ExerciseBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return exerciseBlock(id, exerciseId, exerciseNameSnapshot, sets, note, rpe);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return exerciseBlock?.call(
        id, exerciseId, exerciseNameSnapshot, sets, note, rpe);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (exerciseBlock != null) {
      return exerciseBlock(
          id, exerciseId, exerciseNameSnapshot, sets, note, rpe);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return exerciseBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return exerciseBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (exerciseBlock != null) {
      return exerciseBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ExerciseBlockImplToJson(
      this,
    );
  }
}

abstract class ExerciseBlock extends LogBlock {
  factory ExerciseBlock(
      {required final String id,
      required final String exerciseId,
      required final String exerciseNameSnapshot,
      required final List<SetRecord> sets,
      final String? note,
      final double? rpe}) = _$ExerciseBlockImpl;
  ExerciseBlock._() : super._();

  factory ExerciseBlock.fromJson(Map<String, dynamic> json) =
      _$ExerciseBlockImpl.fromJson;

  @override
  String get id;
  String get exerciseId;
  String get exerciseNameSnapshot;
  List<SetRecord> get sets;
  String? get note;
  double? get rpe;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExerciseBlockImplCopyWith<_$ExerciseBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ImageBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$ImageBlockImplCopyWith(
          _$ImageBlockImpl value, $Res Function(_$ImageBlockImpl) then) =
      __$$ImageBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, List<AttachmentRef> attachments, String? caption});
}

/// @nodoc
class __$$ImageBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$ImageBlockImpl>
    implements _$$ImageBlockImplCopyWith<$Res> {
  __$$ImageBlockImplCopyWithImpl(
      _$ImageBlockImpl _value, $Res Function(_$ImageBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? attachments = null,
    Object? caption = freezed,
  }) {
    return _then(_$ImageBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<AttachmentRef>,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImageBlockImpl extends ImageBlock {
  _$ImageBlockImpl(
      {required this.id,
      required final List<AttachmentRef> attachments,
      this.caption,
      final String? $type})
      : assert(id.isNotEmpty),
        assert(attachments.length >= 1),
        _attachments = attachments,
        $type = $type ?? 'image_block',
        super._();

  factory _$ImageBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImageBlockImplFromJson(json);

  @override
  final String id;
  final List<AttachmentRef> _attachments;
  @override
  List<AttachmentRef> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  final String? caption;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.imageBlock(id: $id, attachments: $attachments, caption: $caption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.caption, caption) || other.caption == caption));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id,
      const DeepCollectionEquality().hash(_attachments), caption);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageBlockImplCopyWith<_$ImageBlockImpl> get copyWith =>
      __$$ImageBlockImplCopyWithImpl<_$ImageBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return imageBlock(id, attachments, caption);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return imageBlock?.call(id, attachments, caption);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (imageBlock != null) {
      return imageBlock(id, attachments, caption);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return imageBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return imageBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (imageBlock != null) {
      return imageBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ImageBlockImplToJson(
      this,
    );
  }
}

abstract class ImageBlock extends LogBlock {
  factory ImageBlock(
      {required final String id,
      required final List<AttachmentRef> attachments,
      final String? caption}) = _$ImageBlockImpl;
  ImageBlock._() : super._();

  factory ImageBlock.fromJson(Map<String, dynamic> json) =
      _$ImageBlockImpl.fromJson;

  @override
  String get id;
  List<AttachmentRef> get attachments;
  String? get caption;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ImageBlockImplCopyWith<_$ImageBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$VideoBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$VideoBlockImplCopyWith(
          _$VideoBlockImpl value, $Res Function(_$VideoBlockImpl) then) =
      __$$VideoBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, List<AttachmentRef> attachments, String? caption});
}

/// @nodoc
class __$$VideoBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$VideoBlockImpl>
    implements _$$VideoBlockImplCopyWith<$Res> {
  __$$VideoBlockImplCopyWithImpl(
      _$VideoBlockImpl _value, $Res Function(_$VideoBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? attachments = null,
    Object? caption = freezed,
  }) {
    return _then(_$VideoBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      attachments: null == attachments
          ? _value._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<AttachmentRef>,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoBlockImpl extends VideoBlock {
  _$VideoBlockImpl(
      {required this.id,
      required final List<AttachmentRef> attachments,
      this.caption,
      final String? $type})
      : assert(id.isNotEmpty),
        assert(attachments.length >= 1),
        _attachments = attachments,
        $type = $type ?? 'video_block',
        super._();

  factory _$VideoBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoBlockImplFromJson(json);

  @override
  final String id;
  final List<AttachmentRef> _attachments;
  @override
  List<AttachmentRef> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  @override
  final String? caption;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.videoBlock(id: $id, attachments: $attachments, caption: $caption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.caption, caption) || other.caption == caption));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id,
      const DeepCollectionEquality().hash(_attachments), caption);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoBlockImplCopyWith<_$VideoBlockImpl> get copyWith =>
      __$$VideoBlockImplCopyWithImpl<_$VideoBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return videoBlock(id, attachments, caption);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return videoBlock?.call(id, attachments, caption);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (videoBlock != null) {
      return videoBlock(id, attachments, caption);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return videoBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return videoBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (videoBlock != null) {
      return videoBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoBlockImplToJson(
      this,
    );
  }
}

abstract class VideoBlock extends LogBlock {
  factory VideoBlock(
      {required final String id,
      required final List<AttachmentRef> attachments,
      final String? caption}) = _$VideoBlockImpl;
  VideoBlock._() : super._();

  factory VideoBlock.fromJson(Map<String, dynamic> json) =
      _$VideoBlockImpl.fromJson;

  @override
  String get id;
  List<AttachmentRef> get attachments;
  String? get caption;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VideoBlockImplCopyWith<_$VideoBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChecklistBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$ChecklistBlockImplCopyWith(_$ChecklistBlockImpl value,
          $Res Function(_$ChecklistBlockImpl) then) =
      __$$ChecklistBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, List<ChecklistItem> items});
}

/// @nodoc
class __$$ChecklistBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$ChecklistBlockImpl>
    implements _$$ChecklistBlockImplCopyWith<$Res> {
  __$$ChecklistBlockImplCopyWithImpl(
      _$ChecklistBlockImpl _value, $Res Function(_$ChecklistBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? items = null,
  }) {
    return _then(_$ChecklistBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<ChecklistItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChecklistBlockImpl extends ChecklistBlock {
  _$ChecklistBlockImpl(
      {required this.id,
      required final List<ChecklistItem> items,
      final String? $type})
      : assert(id.isNotEmpty),
        _items = items,
        $type = $type ?? 'checklist_block',
        super._();

  factory _$ChecklistBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChecklistBlockImplFromJson(json);

  @override
  final String id;
  final List<ChecklistItem> _items;
  @override
  List<ChecklistItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.checklistBlock(id: $id, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChecklistBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, const DeepCollectionEquality().hash(_items));

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChecklistBlockImplCopyWith<_$ChecklistBlockImpl> get copyWith =>
      __$$ChecklistBlockImplCopyWithImpl<_$ChecklistBlockImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return checklistBlock(id, items);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return checklistBlock?.call(id, items);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (checklistBlock != null) {
      return checklistBlock(id, items);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return checklistBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return checklistBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (checklistBlock != null) {
      return checklistBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChecklistBlockImplToJson(
      this,
    );
  }
}

abstract class ChecklistBlock extends LogBlock {
  factory ChecklistBlock(
      {required final String id,
      required final List<ChecklistItem> items}) = _$ChecklistBlockImpl;
  ChecklistBlock._() : super._();

  factory ChecklistBlock.fromJson(Map<String, dynamic> json) =
      _$ChecklistBlockImpl.fromJson;

  @override
  String get id;
  List<ChecklistItem> get items;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChecklistBlockImplCopyWith<_$ChecklistBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TimerMarkerBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$TimerMarkerBlockImplCopyWith(_$TimerMarkerBlockImpl value,
          $Res Function(_$TimerMarkerBlockImpl) then) =
      __$$TimerMarkerBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      TimerKind kind,
      @UtcDateTimeConverter() DateTime atUtc,
      String? label});
}

/// @nodoc
class __$$TimerMarkerBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$TimerMarkerBlockImpl>
    implements _$$TimerMarkerBlockImplCopyWith<$Res> {
  __$$TimerMarkerBlockImplCopyWithImpl(_$TimerMarkerBlockImpl _value,
      $Res Function(_$TimerMarkerBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? kind = null,
    Object? atUtc = null,
    Object? label = freezed,
  }) {
    return _then(_$TimerMarkerBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      kind: null == kind
          ? _value.kind
          : kind // ignore: cast_nullable_to_non_nullable
              as TimerKind,
      atUtc: null == atUtc
          ? _value.atUtc
          : atUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimerMarkerBlockImpl extends TimerMarkerBlock {
  _$TimerMarkerBlockImpl(
      {required this.id,
      required this.kind,
      @UtcDateTimeConverter() required this.atUtc,
      this.label,
      final String? $type})
      : assert(id.isNotEmpty),
        assert(atUtc.isUtc),
        $type = $type ?? 'timer_marker_block',
        super._();

  factory _$TimerMarkerBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimerMarkerBlockImplFromJson(json);

  @override
  final String id;
  @override
  final TimerKind kind;
  @override
  @UtcDateTimeConverter()
  final DateTime atUtc;
  @override
  final String? label;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.timerMarkerBlock(id: $id, kind: $kind, atUtc: $atUtc, label: $label)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimerMarkerBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.atUtc, atUtc) || other.atUtc == atUtc) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, kind, atUtc, label);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimerMarkerBlockImplCopyWith<_$TimerMarkerBlockImpl> get copyWith =>
      __$$TimerMarkerBlockImplCopyWithImpl<_$TimerMarkerBlockImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return timerMarkerBlock(id, kind, atUtc, label);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return timerMarkerBlock?.call(id, kind, atUtc, label);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (timerMarkerBlock != null) {
      return timerMarkerBlock(id, kind, atUtc, label);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return timerMarkerBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return timerMarkerBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (timerMarkerBlock != null) {
      return timerMarkerBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TimerMarkerBlockImplToJson(
      this,
    );
  }
}

abstract class TimerMarkerBlock extends LogBlock {
  factory TimerMarkerBlock(
      {required final String id,
      required final TimerKind kind,
      @UtcDateTimeConverter() required final DateTime atUtc,
      final String? label}) = _$TimerMarkerBlockImpl;
  TimerMarkerBlock._() : super._();

  factory TimerMarkerBlock.fromJson(Map<String, dynamic> json) =
      _$TimerMarkerBlockImpl.fromJson;

  @override
  String get id;
  TimerKind get kind;
  @UtcDateTimeConverter()
  DateTime get atUtc;
  String? get label;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimerMarkerBlockImplCopyWith<_$TimerMarkerBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ReferenceBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$ReferenceBlockImplCopyWith(_$ReferenceBlockImpl value,
          $Res Function(_$ReferenceBlockImpl) then) =
      __$$ReferenceBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String refType, String refId, String? previewText});
}

/// @nodoc
class __$$ReferenceBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$ReferenceBlockImpl>
    implements _$$ReferenceBlockImplCopyWith<$Res> {
  __$$ReferenceBlockImplCopyWithImpl(
      _$ReferenceBlockImpl _value, $Res Function(_$ReferenceBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? refType = null,
    Object? refId = null,
    Object? previewText = freezed,
  }) {
    return _then(_$ReferenceBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      refType: null == refType
          ? _value.refType
          : refType // ignore: cast_nullable_to_non_nullable
              as String,
      refId: null == refId
          ? _value.refId
          : refId // ignore: cast_nullable_to_non_nullable
              as String,
      previewText: freezed == previewText
          ? _value.previewText
          : previewText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReferenceBlockImpl extends ReferenceBlock {
  _$ReferenceBlockImpl(
      {required this.id,
      required this.refType,
      required this.refId,
      this.previewText,
      final String? $type})
      : assert(id.isNotEmpty),
        $type = $type ?? 'reference_block',
        super._();

  factory _$ReferenceBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReferenceBlockImplFromJson(json);

  @override
  final String id;
  @override
  final String refType;
  @override
  final String refId;
  @override
  final String? previewText;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.referenceBlock(id: $id, refType: $refType, refId: $refId, previewText: $previewText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReferenceBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.refType, refType) || other.refType == refType) &&
            (identical(other.refId, refId) || other.refId == refId) &&
            (identical(other.previewText, previewText) ||
                other.previewText == previewText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, refType, refId, previewText);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReferenceBlockImplCopyWith<_$ReferenceBlockImpl> get copyWith =>
      __$$ReferenceBlockImplCopyWithImpl<_$ReferenceBlockImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return referenceBlock(id, refType, refId, previewText);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return referenceBlock?.call(id, refType, refId, previewText);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (referenceBlock != null) {
      return referenceBlock(id, refType, refId, previewText);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return referenceBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return referenceBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (referenceBlock != null) {
      return referenceBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ReferenceBlockImplToJson(
      this,
    );
  }
}

abstract class ReferenceBlock extends LogBlock {
  factory ReferenceBlock(
      {required final String id,
      required final String refType,
      required final String refId,
      final String? previewText}) = _$ReferenceBlockImpl;
  ReferenceBlock._() : super._();

  factory ReferenceBlock.fromJson(Map<String, dynamic> json) =
      _$ReferenceBlockImpl.fromJson;

  @override
  String get id;
  String get refType;
  String get refId;
  String? get previewText;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReferenceBlockImplCopyWith<_$ReferenceBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LinkBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$LinkBlockImplCopyWith(
          _$LinkBlockImpl value, $Res Function(_$LinkBlockImpl) then) =
      __$$LinkBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String url, String? title, String? note});
}

/// @nodoc
class __$$LinkBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$LinkBlockImpl>
    implements _$$LinkBlockImplCopyWith<$Res> {
  __$$LinkBlockImplCopyWithImpl(
      _$LinkBlockImpl _value, $Res Function(_$LinkBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? url = null,
    Object? title = freezed,
    Object? note = freezed,
  }) {
    return _then(_$LinkBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$LinkBlockImpl extends LinkBlock {
  _$LinkBlockImpl(
      {required this.id,
      required this.url,
      this.title,
      this.note,
      final String? $type})
      : assert(id.isNotEmpty),
        $type = $type ?? 'link_block',
        super._();

  factory _$LinkBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$LinkBlockImplFromJson(json);

  @override
  final String id;
  @override
  final String url;
  @override
  final String? title;
  @override
  final String? note;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.linkBlock(id: $id, url: $url, title: $title, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LinkBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, url, title, note);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LinkBlockImplCopyWith<_$LinkBlockImpl> get copyWith =>
      __$$LinkBlockImplCopyWithImpl<_$LinkBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return linkBlock(id, url, title, note);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return linkBlock?.call(id, url, title, note);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (linkBlock != null) {
      return linkBlock(id, url, title, note);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return linkBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return linkBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (linkBlock != null) {
      return linkBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$LinkBlockImplToJson(
      this,
    );
  }
}

abstract class LinkBlock extends LogBlock {
  factory LinkBlock(
      {required final String id,
      required final String url,
      final String? title,
      final String? note}) = _$LinkBlockImpl;
  LinkBlock._() : super._();

  factory LinkBlock.fromJson(Map<String, dynamic> json) =
      _$LinkBlockImpl.fromJson;

  @override
  String get id;
  String get url;
  String? get title;
  String? get note;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LinkBlockImplCopyWith<_$LinkBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$TableBlockImplCopyWith<$Res>
    implements $LogBlockCopyWith<$Res> {
  factory _$$TableBlockImplCopyWith(
          _$TableBlockImpl value, $Res Function(_$TableBlockImpl) then) =
      __$$TableBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, int columnCount, List<List<String>> rows});
}

/// @nodoc
class __$$TableBlockImplCopyWithImpl<$Res>
    extends _$LogBlockCopyWithImpl<$Res, _$TableBlockImpl>
    implements _$$TableBlockImplCopyWith<$Res> {
  __$$TableBlockImplCopyWithImpl(
      _$TableBlockImpl _value, $Res Function(_$TableBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? columnCount = null,
    Object? rows = null,
  }) {
    return _then(_$TableBlockImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      columnCount: null == columnCount
          ? _value.columnCount
          : columnCount // ignore: cast_nullable_to_non_nullable
              as int,
      rows: null == rows
          ? _value._rows
          : rows // ignore: cast_nullable_to_non_nullable
              as List<List<String>>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TableBlockImpl extends TableBlock {
  _$TableBlockImpl(
      {required this.id,
      required this.columnCount,
      required final List<List<String>> rows,
      final String? $type})
      : assert(id.isNotEmpty),
        assert(columnCount >= 1),
        _rows = rows,
        $type = $type ?? 'table_block',
        super._();

  factory _$TableBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$TableBlockImplFromJson(json);

  @override
  final String id;
  @override
  final int columnCount;
  final List<List<String>> _rows;
  @override
  List<List<String>> get rows {
    if (_rows is EqualUnmodifiableListView) return _rows;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_rows);
  }

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'LogBlock.tableBlock(id: $id, columnCount: $columnCount, rows: $rows)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TableBlockImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.columnCount, columnCount) ||
                other.columnCount == columnCount) &&
            const DeepCollectionEquality().equals(other._rows, _rows));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, columnCount, const DeepCollectionEquality().hash(_rows));

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TableBlockImplCopyWith<_$TableBlockImpl> get copyWith =>
      __$$TableBlockImplCopyWithImpl<_$TableBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String id, String text) textBlock,
    required TResult Function(String id, String text, int level) headingBlock,
    required TResult Function(String id) dividerBlock,
    required TResult Function(
            String id,
            String exerciseId,
            String exerciseNameSnapshot,
            List<SetRecord> sets,
            String? note,
            double? rpe)
        exerciseBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        imageBlock,
    required TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)
        videoBlock,
    required TResult Function(String id, List<ChecklistItem> items)
        checklistBlock,
    required TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)
        timerMarkerBlock,
    required TResult Function(
            String id, String refType, String refId, String? previewText)
        referenceBlock,
    required TResult Function(
            String id, String url, String? title, String? note)
        linkBlock,
    required TResult Function(
            String id, int columnCount, List<List<String>> rows)
        tableBlock,
  }) {
    return tableBlock(id, columnCount, rows);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String id, String text)? textBlock,
    TResult? Function(String id, String text, int level)? headingBlock,
    TResult? Function(String id)? dividerBlock,
    TResult? Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult? Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult? Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult? Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult? Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult? Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult? Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
  }) {
    return tableBlock?.call(id, columnCount, rows);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String id, String text)? textBlock,
    TResult Function(String id, String text, int level)? headingBlock,
    TResult Function(String id)? dividerBlock,
    TResult Function(String id, String exerciseId, String exerciseNameSnapshot,
            List<SetRecord> sets, String? note, double? rpe)?
        exerciseBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        imageBlock,
    TResult Function(
            String id, List<AttachmentRef> attachments, String? caption)?
        videoBlock,
    TResult Function(String id, List<ChecklistItem> items)? checklistBlock,
    TResult Function(String id, TimerKind kind,
            @UtcDateTimeConverter() DateTime atUtc, String? label)?
        timerMarkerBlock,
    TResult Function(
            String id, String refType, String refId, String? previewText)?
        referenceBlock,
    TResult Function(String id, String url, String? title, String? note)?
        linkBlock,
    TResult Function(String id, int columnCount, List<List<String>> rows)?
        tableBlock,
    required TResult orElse(),
  }) {
    if (tableBlock != null) {
      return tableBlock(id, columnCount, rows);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) textBlock,
    required TResult Function(HeadingBlock value) headingBlock,
    required TResult Function(DividerBlock value) dividerBlock,
    required TResult Function(ExerciseBlock value) exerciseBlock,
    required TResult Function(ImageBlock value) imageBlock,
    required TResult Function(VideoBlock value) videoBlock,
    required TResult Function(ChecklistBlock value) checklistBlock,
    required TResult Function(TimerMarkerBlock value) timerMarkerBlock,
    required TResult Function(ReferenceBlock value) referenceBlock,
    required TResult Function(LinkBlock value) linkBlock,
    required TResult Function(TableBlock value) tableBlock,
  }) {
    return tableBlock(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? textBlock,
    TResult? Function(HeadingBlock value)? headingBlock,
    TResult? Function(DividerBlock value)? dividerBlock,
    TResult? Function(ExerciseBlock value)? exerciseBlock,
    TResult? Function(ImageBlock value)? imageBlock,
    TResult? Function(VideoBlock value)? videoBlock,
    TResult? Function(ChecklistBlock value)? checklistBlock,
    TResult? Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult? Function(ReferenceBlock value)? referenceBlock,
    TResult? Function(LinkBlock value)? linkBlock,
    TResult? Function(TableBlock value)? tableBlock,
  }) {
    return tableBlock?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? textBlock,
    TResult Function(HeadingBlock value)? headingBlock,
    TResult Function(DividerBlock value)? dividerBlock,
    TResult Function(ExerciseBlock value)? exerciseBlock,
    TResult Function(ImageBlock value)? imageBlock,
    TResult Function(VideoBlock value)? videoBlock,
    TResult Function(ChecklistBlock value)? checklistBlock,
    TResult Function(TimerMarkerBlock value)? timerMarkerBlock,
    TResult Function(ReferenceBlock value)? referenceBlock,
    TResult Function(LinkBlock value)? linkBlock,
    TResult Function(TableBlock value)? tableBlock,
    required TResult orElse(),
  }) {
    if (tableBlock != null) {
      return tableBlock(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TableBlockImplToJson(
      this,
    );
  }
}

abstract class TableBlock extends LogBlock {
  factory TableBlock(
      {required final String id,
      required final int columnCount,
      required final List<List<String>> rows}) = _$TableBlockImpl;
  TableBlock._() : super._();

  factory TableBlock.fromJson(Map<String, dynamic> json) =
      _$TableBlockImpl.fromJson;

  @override
  String get id;
  int get columnCount;
  List<List<String>> get rows;

  /// Create a copy of LogBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TableBlockImplCopyWith<_$TableBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
