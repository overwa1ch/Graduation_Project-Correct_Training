// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'insights_service.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PrRecord _$PrRecordFromJson(Map<String, dynamic> json) {
  return _PrRecord.fromJson(json);
}

/// @nodoc
mixin _$PrRecord {
  String get exerciseId => throw _privateConstructorUsedError;
  double get weightKg => throw _privateConstructorUsedError;
  String get logId => throw _privateConstructorUsedError;
  @DateOnlyJsonConverter()
  DateOnly get date => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get lastEditedAtUtc => throw _privateConstructorUsedError;

  /// Serializes this PrRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrRecordCopyWith<PrRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrRecordCopyWith<$Res> {
  factory $PrRecordCopyWith(PrRecord value, $Res Function(PrRecord) then) =
      _$PrRecordCopyWithImpl<$Res, PrRecord>;
  @useResult
  $Res call(
      {String exerciseId,
      double weightKg,
      String logId,
      @DateOnlyJsonConverter() DateOnly date,
      @UtcDateTimeConverter() DateTime lastEditedAtUtc});
}

/// @nodoc
class _$PrRecordCopyWithImpl<$Res, $Val extends PrRecord>
    implements $PrRecordCopyWith<$Res> {
  _$PrRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? weightKg = null,
    Object? logId = null,
    Object? date = null,
    Object? lastEditedAtUtc = null,
  }) {
    return _then(_value.copyWith(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      logId: null == logId
          ? _value.logId
          : logId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateOnly,
      lastEditedAtUtc: null == lastEditedAtUtc
          ? _value.lastEditedAtUtc
          : lastEditedAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrRecordImplCopyWith<$Res>
    implements $PrRecordCopyWith<$Res> {
  factory _$$PrRecordImplCopyWith(
          _$PrRecordImpl value, $Res Function(_$PrRecordImpl) then) =
      __$$PrRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String exerciseId,
      double weightKg,
      String logId,
      @DateOnlyJsonConverter() DateOnly date,
      @UtcDateTimeConverter() DateTime lastEditedAtUtc});
}

/// @nodoc
class __$$PrRecordImplCopyWithImpl<$Res>
    extends _$PrRecordCopyWithImpl<$Res, _$PrRecordImpl>
    implements _$$PrRecordImplCopyWith<$Res> {
  __$$PrRecordImplCopyWithImpl(
      _$PrRecordImpl _value, $Res Function(_$PrRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? weightKg = null,
    Object? logId = null,
    Object? date = null,
    Object? lastEditedAtUtc = null,
  }) {
    return _then(_$PrRecordImpl(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      logId: null == logId
          ? _value.logId
          : logId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateOnly,
      lastEditedAtUtc: null == lastEditedAtUtc
          ? _value.lastEditedAtUtc
          : lastEditedAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrRecordImpl extends _PrRecord {
  _$PrRecordImpl(
      {required this.exerciseId,
      required this.weightKg,
      required this.logId,
      @DateOnlyJsonConverter() required this.date,
      @UtcDateTimeConverter() required this.lastEditedAtUtc})
      : assert(exerciseId.isNotEmpty),
        assert(logId.isNotEmpty),
        assert(lastEditedAtUtc.isUtc),
        super._();

  factory _$PrRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrRecordImplFromJson(json);

  @override
  final String exerciseId;
  @override
  final double weightKg;
  @override
  final String logId;
  @override
  @DateOnlyJsonConverter()
  final DateOnly date;
  @override
  @UtcDateTimeConverter()
  final DateTime lastEditedAtUtc;

  @override
  String toString() {
    return 'PrRecord(exerciseId: $exerciseId, weightKg: $weightKg, logId: $logId, date: $date, lastEditedAtUtc: $lastEditedAtUtc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrRecordImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.logId, logId) || other.logId == logId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.lastEditedAtUtc, lastEditedAtUtc) ||
                other.lastEditedAtUtc == lastEditedAtUtc));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, exerciseId, weightKg, logId, date, lastEditedAtUtc);

  /// Create a copy of PrRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrRecordImplCopyWith<_$PrRecordImpl> get copyWith =>
      __$$PrRecordImplCopyWithImpl<_$PrRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrRecordImplToJson(
      this,
    );
  }
}

abstract class _PrRecord extends PrRecord {
  factory _PrRecord(
          {required final String exerciseId,
          required final double weightKg,
          required final String logId,
          @DateOnlyJsonConverter() required final DateOnly date,
          @UtcDateTimeConverter() required final DateTime lastEditedAtUtc}) =
      _$PrRecordImpl;
  _PrRecord._() : super._();

  factory _PrRecord.fromJson(Map<String, dynamic> json) =
      _$PrRecordImpl.fromJson;

  @override
  String get exerciseId;
  @override
  double get weightKg;
  @override
  String get logId;
  @override
  @DateOnlyJsonConverter()
  DateOnly get date;
  @override
  @UtcDateTimeConverter()
  DateTime get lastEditedAtUtc;

  /// Create a copy of PrRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrRecordImplCopyWith<_$PrRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
