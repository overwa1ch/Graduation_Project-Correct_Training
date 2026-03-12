// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'milestone_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MilestoneEvent _$MilestoneEventFromJson(Map<String, dynamic> json) {
  return _MilestoneEvent.fromJson(json);
}

/// @nodoc
mixin _$MilestoneEvent {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get exerciseId => throw _privateConstructorUsedError;
  String get logId => throw _privateConstructorUsedError;
  double get metricValue => throw _privateConstructorUsedError;
  String get dedupKey => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAtUtc => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime? get deletedAtUtc => throw _privateConstructorUsedError;

  /// Serializes this MilestoneEvent to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MilestoneEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MilestoneEventCopyWith<MilestoneEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MilestoneEventCopyWith<$Res> {
  factory $MilestoneEventCopyWith(
          MilestoneEvent value, $Res Function(MilestoneEvent) then) =
      _$MilestoneEventCopyWithImpl<$Res, MilestoneEvent>;
  @useResult
  $Res call(
      {String id,
      String type,
      String exerciseId,
      String logId,
      double metricValue,
      String dedupKey,
      @UtcDateTimeConverter() DateTime createdAtUtc,
      @UtcDateTimeConverter() DateTime? deletedAtUtc});
}

/// @nodoc
class _$MilestoneEventCopyWithImpl<$Res, $Val extends MilestoneEvent>
    implements $MilestoneEventCopyWith<$Res> {
  _$MilestoneEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MilestoneEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? exerciseId = null,
    Object? logId = null,
    Object? metricValue = null,
    Object? dedupKey = null,
    Object? createdAtUtc = null,
    Object? deletedAtUtc = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      logId: null == logId
          ? _value.logId
          : logId // ignore: cast_nullable_to_non_nullable
              as String,
      metricValue: null == metricValue
          ? _value.metricValue
          : metricValue // ignore: cast_nullable_to_non_nullable
              as double,
      dedupKey: null == dedupKey
          ? _value.dedupKey
          : dedupKey // ignore: cast_nullable_to_non_nullable
              as String,
      createdAtUtc: null == createdAtUtc
          ? _value.createdAtUtc
          : createdAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAtUtc: freezed == deletedAtUtc
          ? _value.deletedAtUtc
          : deletedAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MilestoneEventImplCopyWith<$Res>
    implements $MilestoneEventCopyWith<$Res> {
  factory _$$MilestoneEventImplCopyWith(_$MilestoneEventImpl value,
          $Res Function(_$MilestoneEventImpl) then) =
      __$$MilestoneEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      String exerciseId,
      String logId,
      double metricValue,
      String dedupKey,
      @UtcDateTimeConverter() DateTime createdAtUtc,
      @UtcDateTimeConverter() DateTime? deletedAtUtc});
}

/// @nodoc
class __$$MilestoneEventImplCopyWithImpl<$Res>
    extends _$MilestoneEventCopyWithImpl<$Res, _$MilestoneEventImpl>
    implements _$$MilestoneEventImplCopyWith<$Res> {
  __$$MilestoneEventImplCopyWithImpl(
      _$MilestoneEventImpl _value, $Res Function(_$MilestoneEventImpl) _then)
      : super(_value, _then);

  /// Create a copy of MilestoneEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? exerciseId = null,
    Object? logId = null,
    Object? metricValue = null,
    Object? dedupKey = null,
    Object? createdAtUtc = null,
    Object? deletedAtUtc = freezed,
  }) {
    return _then(_$MilestoneEventImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      logId: null == logId
          ? _value.logId
          : logId // ignore: cast_nullable_to_non_nullable
              as String,
      metricValue: null == metricValue
          ? _value.metricValue
          : metricValue // ignore: cast_nullable_to_non_nullable
              as double,
      dedupKey: null == dedupKey
          ? _value.dedupKey
          : dedupKey // ignore: cast_nullable_to_non_nullable
              as String,
      createdAtUtc: null == createdAtUtc
          ? _value.createdAtUtc
          : createdAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
      deletedAtUtc: freezed == deletedAtUtc
          ? _value.deletedAtUtc
          : deletedAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MilestoneEventImpl extends _MilestoneEvent {
  _$MilestoneEventImpl(
      {required this.id,
      this.type = 'pr',
      required this.exerciseId,
      required this.logId,
      required this.metricValue,
      required this.dedupKey,
      @UtcDateTimeConverter() required this.createdAtUtc,
      @UtcDateTimeConverter() this.deletedAtUtc})
      : assert(id.isNotEmpty),
        assert(type == "pr"),
        assert(exerciseId.isNotEmpty),
        assert(logId.isNotEmpty),
        assert(dedupKey.isNotEmpty),
        assert(dedupKey == "pr:$exerciseId:$logId"),
        assert(createdAtUtc.isUtc),
        assert(deletedAtUtc == null || deletedAtUtc.isUtc),
        super._();

  factory _$MilestoneEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$MilestoneEventImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final String type;
  @override
  final String exerciseId;
  @override
  final String logId;
  @override
  final double metricValue;
  @override
  final String dedupKey;
  @override
  @UtcDateTimeConverter()
  final DateTime createdAtUtc;
  @override
  @UtcDateTimeConverter()
  final DateTime? deletedAtUtc;

  @override
  String toString() {
    return 'MilestoneEvent(id: $id, type: $type, exerciseId: $exerciseId, logId: $logId, metricValue: $metricValue, dedupKey: $dedupKey, createdAtUtc: $createdAtUtc, deletedAtUtc: $deletedAtUtc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MilestoneEventImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.logId, logId) || other.logId == logId) &&
            (identical(other.metricValue, metricValue) ||
                other.metricValue == metricValue) &&
            (identical(other.dedupKey, dedupKey) ||
                other.dedupKey == dedupKey) &&
            (identical(other.createdAtUtc, createdAtUtc) ||
                other.createdAtUtc == createdAtUtc) &&
            (identical(other.deletedAtUtc, deletedAtUtc) ||
                other.deletedAtUtc == deletedAtUtc));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, type, exerciseId, logId,
      metricValue, dedupKey, createdAtUtc, deletedAtUtc);

  /// Create a copy of MilestoneEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MilestoneEventImplCopyWith<_$MilestoneEventImpl> get copyWith =>
      __$$MilestoneEventImplCopyWithImpl<_$MilestoneEventImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MilestoneEventImplToJson(
      this,
    );
  }
}

abstract class _MilestoneEvent extends MilestoneEvent {
  factory _MilestoneEvent(
          {required final String id,
          final String type,
          required final String exerciseId,
          required final String logId,
          required final double metricValue,
          required final String dedupKey,
          @UtcDateTimeConverter() required final DateTime createdAtUtc,
          @UtcDateTimeConverter() final DateTime? deletedAtUtc}) =
      _$MilestoneEventImpl;
  _MilestoneEvent._() : super._();

  factory _MilestoneEvent.fromJson(Map<String, dynamic> json) =
      _$MilestoneEventImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  String get exerciseId;
  @override
  String get logId;
  @override
  double get metricValue;
  @override
  String get dedupKey;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAtUtc;
  @override
  @UtcDateTimeConverter()
  DateTime? get deletedAtUtc;

  /// Create a copy of MilestoneEvent
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MilestoneEventImplCopyWith<_$MilestoneEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
