// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'revise_post_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RevisePostRequestDto {

 String? get title; String? get text;@JsonKey(name: 'message') String get message;
/// Create a copy of RevisePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevisePostRequestDtoCopyWith<RevisePostRequestDto> get copyWith => _$RevisePostRequestDtoCopyWithImpl<RevisePostRequestDto>(this as RevisePostRequestDto, _$identity);

  /// Serializes this RevisePostRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevisePostRequestDto&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,message);

@override
String toString() {
  return 'RevisePostRequestDto(title: $title, text: $text, message: $message)';
}


}

/// @nodoc
abstract mixin class $RevisePostRequestDtoCopyWith<$Res>  {
  factory $RevisePostRequestDtoCopyWith(RevisePostRequestDto value, $Res Function(RevisePostRequestDto) _then) = _$RevisePostRequestDtoCopyWithImpl;
@useResult
$Res call({
 String? title, String? text,@JsonKey(name: 'message') String message
});




}
/// @nodoc
class _$RevisePostRequestDtoCopyWithImpl<$Res>
    implements $RevisePostRequestDtoCopyWith<$Res> {
  _$RevisePostRequestDtoCopyWithImpl(this._self, this._then);

  final RevisePostRequestDto _self;
  final $Res Function(RevisePostRequestDto) _then;

/// Create a copy of RevisePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? text = freezed,Object? message = null,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RevisePostRequestDto].
extension RevisePostRequestDtoPatterns on RevisePostRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevisePostRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevisePostRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevisePostRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _RevisePostRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevisePostRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _RevisePostRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? text, @JsonKey(name: 'message')  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevisePostRequestDto() when $default != null:
return $default(_that.title,_that.text,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? text, @JsonKey(name: 'message')  String message)  $default,) {final _that = this;
switch (_that) {
case _RevisePostRequestDto():
return $default(_that.title,_that.text,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? text, @JsonKey(name: 'message')  String message)?  $default,) {final _that = this;
switch (_that) {
case _RevisePostRequestDto() when $default != null:
return $default(_that.title,_that.text,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RevisePostRequestDto implements RevisePostRequestDto {
  const _RevisePostRequestDto({this.title, this.text, @JsonKey(name: 'message') required this.message});
  factory _RevisePostRequestDto.fromJson(Map<String, dynamic> json) => _$RevisePostRequestDtoFromJson(json);

@override final  String? title;
@override final  String? text;
@override@JsonKey(name: 'message') final  String message;

/// Create a copy of RevisePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevisePostRequestDtoCopyWith<_RevisePostRequestDto> get copyWith => __$RevisePostRequestDtoCopyWithImpl<_RevisePostRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RevisePostRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevisePostRequestDto&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,message);

@override
String toString() {
  return 'RevisePostRequestDto(title: $title, text: $text, message: $message)';
}


}

/// @nodoc
abstract mixin class _$RevisePostRequestDtoCopyWith<$Res> implements $RevisePostRequestDtoCopyWith<$Res> {
  factory _$RevisePostRequestDtoCopyWith(_RevisePostRequestDto value, $Res Function(_RevisePostRequestDto) _then) = __$RevisePostRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? text,@JsonKey(name: 'message') String message
});




}
/// @nodoc
class __$RevisePostRequestDtoCopyWithImpl<$Res>
    implements _$RevisePostRequestDtoCopyWith<$Res> {
  __$RevisePostRequestDtoCopyWithImpl(this._self, this._then);

  final _RevisePostRequestDto _self;
  final $Res Function(_RevisePostRequestDto) _then;

/// Create a copy of RevisePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? text = freezed,Object? message = null,}) {
  return _then(_RevisePostRequestDto(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
