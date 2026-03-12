// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'set_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SetRecord _$SetRecordFromJson(Map<String, dynamic> json) {
  return _SetRecord.fromJson(json);
}

/// @nodoc
mixin _$SetRecord {
  double get weightKg => throw _privateConstructorUsedError;
  int get reps => throw _privateConstructorUsedError;
  int? get restSec => throw _privateConstructorUsedError;

  /// Serializes this SetRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SetRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SetRecordCopyWith<SetRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SetRecordCopyWith<$Res> {
  factory $SetRecordCopyWith(SetRecord value, $Res Function(SetRecord) then) =
      _$SetRecordCopyWithImpl<$Res, SetRecord>;
  @useResult
  $Res call({double weightKg, int reps, int? restSec});
}

/// @nodoc
class _$SetRecordCopyWithImpl<$Res, $Val extends SetRecord>
    implements $SetRecordCopyWith<$Res> {
  _$SetRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SetRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightKg = null,
    Object? reps = null,
    Object? restSec = freezed,
  }) {
    return _then(_value.copyWith(
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      restSec: freezed == restSec
          ? _value.restSec
          : restSec // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SetRecordImplCopyWith<$Res>
    implements $SetRecordCopyWith<$Res> {
  factory _$$SetRecordImplCopyWith(
          _$SetRecordImpl value, $Res Function(_$SetRecordImpl) then) =
      __$$SetRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double weightKg, int reps, int? restSec});
}

/// @nodoc
class __$$SetRecordImplCopyWithImpl<$Res>
    extends _$SetRecordCopyWithImpl<$Res, _$SetRecordImpl>
    implements _$$SetRecordImplCopyWith<$Res> {
  __$$SetRecordImplCopyWithImpl(
      _$SetRecordImpl _value, $Res Function(_$SetRecordImpl) _then)
      : super(_value, _then);

  /// Create a copy of SetRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightKg = null,
    Object? reps = null,
    Object? restSec = freezed,
  }) {
    return _then(_$SetRecordImpl(
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      reps: null == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      restSec: freezed == restSec
          ? _value.restSec
          : restSec // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SetRecordImpl extends _SetRecord {
  _$SetRecordImpl({required this.weightKg, required this.reps, this.restSec})
      : assert(weightKg >= 0),
        assert(reps >= 0),
        assert(restSec == null || restSec >= 0),
        super._();

  factory _$SetRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$SetRecordImplFromJson(json);

  @override
  final double weightKg;
  @override
  final int reps;
  @override
  final int? restSec;

  @override
  String toString() {
    return 'SetRecord(weightKg: $weightKg, reps: $reps, restSec: $restSec)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SetRecordImpl &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.restSec, restSec) || other.restSec == restSec));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, weightKg, reps, restSec);

  /// Create a copy of SetRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SetRecordImplCopyWith<_$SetRecordImpl> get copyWith =>
      __$$SetRecordImplCopyWithImpl<_$SetRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SetRecordImplToJson(
      this,
    );
  }
}

abstract class _SetRecord extends SetRecord {
  factory _SetRecord(
      {required final double weightKg,
      required final int reps,
      final int? restSec}) = _$SetRecordImpl;
  _SetRecord._() : super._();

  factory _SetRecord.fromJson(Map<String, dynamic> json) =
      _$SetRecordImpl.fromJson;

  @override
  double get weightKg;
  @override
  int get reps;
  @override
  int? get restSec;

  /// Create a copy of SetRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SetRecordImplCopyWith<_$SetRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
