// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moderate_post_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModeratePostResultDto {

@JsonKey(name: 'post_uuid') String get postUuid; String get status;
/// Create a copy of ModeratePostResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModeratePostResultDtoCopyWith<ModeratePostResultDto> get copyWith => _$ModeratePostResultDtoCopyWithImpl<ModeratePostResultDto>(this as ModeratePostResultDto, _$identity);

  /// Serializes this ModeratePostResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratePostResultDto&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postUuid,status);

@override
String toString() {
  return 'ModeratePostResultDto(postUuid: $postUuid, status: $status)';
}


}

/// @nodoc
abstract mixin class $ModeratePostResultDtoCopyWith<$Res>  {
  factory $ModeratePostResultDtoCopyWith(ModeratePostResultDto value, $Res Function(ModeratePostResultDto) _then) = _$ModeratePostResultDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'post_uuid') String postUuid, String status
});




}
/// @nodoc
class _$ModeratePostResultDtoCopyWithImpl<$Res>
    implements $ModeratePostResultDtoCopyWith<$Res> {
  _$ModeratePostResultDtoCopyWithImpl(this._self, this._then);

  final ModeratePostResultDto _self;
  final $Res Function(ModeratePostResultDto) _then;

/// Create a copy of ModeratePostResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? postUuid = null,Object? status = null,}) {
  return _then(_self.copyWith(
postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ModeratePostResultDto].
extension ModeratePostResultDtoPatterns on ModeratePostResultDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModeratePostResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModeratePostResultDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModeratePostResultDto value)  $default,){
final _that = this;
switch (_that) {
case _ModeratePostResultDto():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModeratePostResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModeratePostResultDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_uuid')  String postUuid,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModeratePostResultDto() when $default != null:
return $default(_that.postUuid,_that.status);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_uuid')  String postUuid,  String status)  $default,) {final _that = this;
switch (_that) {
case _ModeratePostResultDto():
return $default(_that.postUuid,_that.status);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'post_uuid')  String postUuid,  String status)?  $default,) {final _that = this;
switch (_that) {
case _ModeratePostResultDto() when $default != null:
return $default(_that.postUuid,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModeratePostResultDto implements ModeratePostResultDto {
  const _ModeratePostResultDto({@JsonKey(name: 'post_uuid') required this.postUuid, required this.status});
  factory _ModeratePostResultDto.fromJson(Map<String, dynamic> json) => _$ModeratePostResultDtoFromJson(json);

@override@JsonKey(name: 'post_uuid') final  String postUuid;
@override final  String status;

/// Create a copy of ModeratePostResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModeratePostResultDtoCopyWith<_ModeratePostResultDto> get copyWith => __$ModeratePostResultDtoCopyWithImpl<_ModeratePostResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModeratePostResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModeratePostResultDto&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postUuid,status);

@override
String toString() {
  return 'ModeratePostResultDto(postUuid: $postUuid, status: $status)';
}


}

/// @nodoc
abstract mixin class _$ModeratePostResultDtoCopyWith<$Res> implements $ModeratePostResultDtoCopyWith<$Res> {
  factory _$ModeratePostResultDtoCopyWith(_ModeratePostResultDto value, $Res Function(_ModeratePostResultDto) _then) = __$ModeratePostResultDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'post_uuid') String postUuid, String status
});




}
/// @nodoc
class __$ModeratePostResultDtoCopyWithImpl<$Res>
    implements _$ModeratePostResultDtoCopyWith<$Res> {
  __$ModeratePostResultDtoCopyWithImpl(this._self, this._then);

  final _ModeratePostResultDto _self;
  final $Res Function(_ModeratePostResultDto) _then;

/// Create a copy of ModeratePostResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? postUuid = null,Object? status = null,}) {
  return _then(_ModeratePostResultDto(
postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
