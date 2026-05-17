// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_post_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdatePostRequestDto {

 String get title; String get text;@JsonKey(name: 'media_url') String? get mediaUrl;
/// Create a copy of UpdatePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdatePostRequestDtoCopyWith<UpdatePostRequestDto> get copyWith => _$UpdatePostRequestDtoCopyWithImpl<UpdatePostRequestDto>(this as UpdatePostRequestDto, _$identity);

  /// Serializes this UpdatePostRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdatePostRequestDto&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,mediaUrl);

@override
String toString() {
  return 'UpdatePostRequestDto(title: $title, text: $text, mediaUrl: $mediaUrl)';
}


}

/// @nodoc
abstract mixin class $UpdatePostRequestDtoCopyWith<$Res>  {
  factory $UpdatePostRequestDtoCopyWith(UpdatePostRequestDto value, $Res Function(UpdatePostRequestDto) _then) = _$UpdatePostRequestDtoCopyWithImpl;
@useResult
$Res call({
 String title, String text,@JsonKey(name: 'media_url') String? mediaUrl
});




}
/// @nodoc
class _$UpdatePostRequestDtoCopyWithImpl<$Res>
    implements $UpdatePostRequestDtoCopyWith<$Res> {
  _$UpdatePostRequestDtoCopyWithImpl(this._self, this._then);

  final UpdatePostRequestDto _self;
  final $Res Function(UpdatePostRequestDto) _then;

/// Create a copy of UpdatePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? text = null,Object? mediaUrl = freezed,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdatePostRequestDto].
extension UpdatePostRequestDtoPatterns on UpdatePostRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdatePostRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdatePostRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdatePostRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdatePostRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdatePostRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdatePostRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String text, @JsonKey(name: 'media_url')  String? mediaUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdatePostRequestDto() when $default != null:
return $default(_that.title,_that.text,_that.mediaUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String text, @JsonKey(name: 'media_url')  String? mediaUrl)  $default,) {final _that = this;
switch (_that) {
case _UpdatePostRequestDto():
return $default(_that.title,_that.text,_that.mediaUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String text, @JsonKey(name: 'media_url')  String? mediaUrl)?  $default,) {final _that = this;
switch (_that) {
case _UpdatePostRequestDto() when $default != null:
return $default(_that.title,_that.text,_that.mediaUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdatePostRequestDto implements UpdatePostRequestDto {
  const _UpdatePostRequestDto({required this.title, required this.text, @JsonKey(name: 'media_url') this.mediaUrl});
  factory _UpdatePostRequestDto.fromJson(Map<String, dynamic> json) => _$UpdatePostRequestDtoFromJson(json);

@override final  String title;
@override final  String text;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;

/// Create a copy of UpdatePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdatePostRequestDtoCopyWith<_UpdatePostRequestDto> get copyWith => __$UpdatePostRequestDtoCopyWithImpl<_UpdatePostRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdatePostRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdatePostRequestDto&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,mediaUrl);

@override
String toString() {
  return 'UpdatePostRequestDto(title: $title, text: $text, mediaUrl: $mediaUrl)';
}


}

/// @nodoc
abstract mixin class _$UpdatePostRequestDtoCopyWith<$Res> implements $UpdatePostRequestDtoCopyWith<$Res> {
  factory _$UpdatePostRequestDtoCopyWith(_UpdatePostRequestDto value, $Res Function(_UpdatePostRequestDto) _then) = __$UpdatePostRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, String text,@JsonKey(name: 'media_url') String? mediaUrl
});




}
/// @nodoc
class __$UpdatePostRequestDtoCopyWithImpl<$Res>
    implements _$UpdatePostRequestDtoCopyWith<$Res> {
  __$UpdatePostRequestDtoCopyWithImpl(this._self, this._then);

  final _UpdatePostRequestDto _self;
  final $Res Function(_UpdatePostRequestDto) _then;

/// Create a copy of UpdatePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? text = null,Object? mediaUrl = freezed,}) {
  return _then(_UpdatePostRequestDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
