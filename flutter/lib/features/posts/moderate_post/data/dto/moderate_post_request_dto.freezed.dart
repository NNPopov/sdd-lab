// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moderate_post_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModeratePostRequestDto {

 String get action; String? get message;
/// Create a copy of ModeratePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModeratePostRequestDtoCopyWith<ModeratePostRequestDto> get copyWith => _$ModeratePostRequestDtoCopyWithImpl<ModeratePostRequestDto>(this as ModeratePostRequestDto, _$identity);

  /// Serializes this ModeratePostRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratePostRequestDto&&(identical(other.action, action) || other.action == action)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,message);

@override
String toString() {
  return 'ModeratePostRequestDto(action: $action, message: $message)';
}


}

/// @nodoc
abstract mixin class $ModeratePostRequestDtoCopyWith<$Res>  {
  factory $ModeratePostRequestDtoCopyWith(ModeratePostRequestDto value, $Res Function(ModeratePostRequestDto) _then) = _$ModeratePostRequestDtoCopyWithImpl;
@useResult
$Res call({
 String action, String? message
});




}
/// @nodoc
class _$ModeratePostRequestDtoCopyWithImpl<$Res>
    implements $ModeratePostRequestDtoCopyWith<$Res> {
  _$ModeratePostRequestDtoCopyWithImpl(this._self, this._then);

  final ModeratePostRequestDto _self;
  final $Res Function(ModeratePostRequestDto) _then;

/// Create a copy of ModeratePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? action = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModeratePostRequestDto].
extension ModeratePostRequestDtoPatterns on ModeratePostRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModeratePostRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModeratePostRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModeratePostRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _ModeratePostRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModeratePostRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModeratePostRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String action,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModeratePostRequestDto() when $default != null:
return $default(_that.action,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String action,  String? message)  $default,) {final _that = this;
switch (_that) {
case _ModeratePostRequestDto():
return $default(_that.action,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String action,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _ModeratePostRequestDto() when $default != null:
return $default(_that.action,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModeratePostRequestDto implements ModeratePostRequestDto {
  const _ModeratePostRequestDto({required this.action, this.message});
  factory _ModeratePostRequestDto.fromJson(Map<String, dynamic> json) => _$ModeratePostRequestDtoFromJson(json);

@override final  String action;
@override final  String? message;

/// Create a copy of ModeratePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModeratePostRequestDtoCopyWith<_ModeratePostRequestDto> get copyWith => __$ModeratePostRequestDtoCopyWithImpl<_ModeratePostRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModeratePostRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModeratePostRequestDto&&(identical(other.action, action) || other.action == action)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,action,message);

@override
String toString() {
  return 'ModeratePostRequestDto(action: $action, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ModeratePostRequestDtoCopyWith<$Res> implements $ModeratePostRequestDtoCopyWith<$Res> {
  factory _$ModeratePostRequestDtoCopyWith(_ModeratePostRequestDto value, $Res Function(_ModeratePostRequestDto) _then) = __$ModeratePostRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String action, String? message
});




}
/// @nodoc
class __$ModeratePostRequestDtoCopyWithImpl<$Res>
    implements _$ModeratePostRequestDtoCopyWith<$Res> {
  __$ModeratePostRequestDtoCopyWithImpl(this._self, this._then);

  final _ModeratePostRequestDto _self;
  final $Res Function(_ModeratePostRequestDto) _then;

/// Create a copy of ModeratePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? action = null,Object? message = freezed,}) {
  return _then(_ModeratePostRequestDto(
action: null == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
