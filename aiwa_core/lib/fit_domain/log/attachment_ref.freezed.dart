// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment_ref.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AttachmentRef _$AttachmentRefFromJson(Map<String, dynamic> json) {
  return _AttachmentRef.fromJson(json);
}

/// @nodoc
mixin _$AttachmentRef {
  String get id => throw _privateConstructorUsedError;
  AttachmentMediaType get mediaType => throw _privateConstructorUsedError;
  Map<String, dynamic>? get meta => throw _privateConstructorUsedError;
  @UtcDateTimeConverter()
  DateTime get createdAtUtc => throw _privateConstructorUsedError;

  /// Serializes this AttachmentRef to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AttachmentRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AttachmentRefCopyWith<AttachmentRef> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttachmentRefCopyWith<$Res> {
  factory $AttachmentRefCopyWith(
          AttachmentRef value, $Res Function(AttachmentRef) then) =
      _$AttachmentRefCopyWithImpl<$Res, AttachmentRef>;
  @useResult
  $Res call(
      {String id,
      AttachmentMediaType mediaType,
      Map<String, dynamic>? meta,
      @UtcDateTimeConverter() DateTime createdAtUtc});
}

/// @nodoc
class _$AttachmentRefCopyWithImpl<$Res, $Val extends AttachmentRef>
    implements $AttachmentRefCopyWith<$Res> {
  _$AttachmentRefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AttachmentRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaType = null,
    Object? meta = freezed,
    Object? createdAtUtc = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaType: null == mediaType
          ? _value.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as AttachmentMediaType,
      meta: freezed == meta
          ? _value.meta
          : meta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAtUtc: null == createdAtUtc
          ? _value.createdAtUtc
          : createdAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttachmentRefImplCopyWith<$Res>
    implements $AttachmentRefCopyWith<$Res> {
  factory _$$AttachmentRefImplCopyWith(
          _$AttachmentRefImpl value, $Res Function(_$AttachmentRefImpl) then) =
      __$$AttachmentRefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      AttachmentMediaType mediaType,
      Map<String, dynamic>? meta,
      @UtcDateTimeConverter() DateTime createdAtUtc});
}

/// @nodoc
class __$$AttachmentRefImplCopyWithImpl<$Res>
    extends _$AttachmentRefCopyWithImpl<$Res, _$AttachmentRefImpl>
    implements _$$AttachmentRefImplCopyWith<$Res> {
  __$$AttachmentRefImplCopyWithImpl(
      _$AttachmentRefImpl _value, $Res Function(_$AttachmentRefImpl) _then)
      : super(_value, _then);

  /// Create a copy of AttachmentRef
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaType = null,
    Object? meta = freezed,
    Object? createdAtUtc = null,
  }) {
    return _then(_$AttachmentRefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaType: null == mediaType
          ? _value.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as AttachmentMediaType,
      meta: freezed == meta
          ? _value._meta
          : meta // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAtUtc: null == createdAtUtc
          ? _value.createdAtUtc
          : createdAtUtc // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttachmentRefImpl extends _AttachmentRef {
  _$AttachmentRefImpl(
      {required this.id,
      required this.mediaType,
      final Map<String, dynamic>? meta,
      @UtcDateTimeConverter() required this.createdAtUtc})
      : assert(id.isNotEmpty),
        assert(createdAtUtc.isUtc),
        _meta = meta,
        super._();

  factory _$AttachmentRefImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttachmentRefImplFromJson(json);

  @override
  final String id;
  @override
  final AttachmentMediaType mediaType;
  final Map<String, dynamic>? _meta;
  @override
  Map<String, dynamic>? get meta {
    final value = _meta;
    if (value == null) return null;
    if (_meta is EqualUnmodifiableMapView) return _meta;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @UtcDateTimeConverter()
  final DateTime createdAtUtc;

  @override
  String toString() {
    return 'AttachmentRef(id: $id, mediaType: $mediaType, meta: $meta, createdAtUtc: $createdAtUtc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttachmentRefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            const DeepCollectionEquality().equals(other._meta, _meta) &&
            (identical(other.createdAtUtc, createdAtUtc) ||
                other.createdAtUtc == createdAtUtc));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, mediaType,
      const DeepCollectionEquality().hash(_meta), createdAtUtc);

  /// Create a copy of AttachmentRef
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AttachmentRefImplCopyWith<_$AttachmentRefImpl> get copyWith =>
      __$$AttachmentRefImplCopyWithImpl<_$AttachmentRefImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttachmentRefImplToJson(
      this,
    );
  }
}

abstract class _AttachmentRef extends AttachmentRef {
  factory _AttachmentRef(
          {required final String id,
          required final AttachmentMediaType mediaType,
          final Map<String, dynamic>? meta,
          @UtcDateTimeConverter() required final DateTime createdAtUtc}) =
      _$AttachmentRefImpl;
  _AttachmentRef._() : super._();

  factory _AttachmentRef.fromJson(Map<String, dynamic> json) =
      _$AttachmentRefImpl.fromJson;

  @override
  String get id;
  @override
  AttachmentMediaType get mediaType;
  @override
  Map<String, dynamic>? get meta;
  @override
  @UtcDateTimeConverter()
  DateTime get createdAtUtc;

  /// Create a copy of AttachmentRef
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AttachmentRefImplCopyWith<_$AttachmentRefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
