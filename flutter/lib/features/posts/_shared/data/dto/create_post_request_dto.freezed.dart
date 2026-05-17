// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_post_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreatePostRequestDto {

 String get title; String get text;@JsonKey(name: 'media_url') String? get mediaUrl;
/// Create a copy of CreatePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreatePostRequestDtoCopyWith<CreatePostRequestDto> get copyWith => _$CreatePostRequestDtoCopyWithImpl<CreatePostRequestDto>(this as CreatePostRequestDto, _$identity);

  /// Serializes this CreatePostRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreatePostRequestDto&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,mediaUrl);

@override
String toString() {
  return 'CreatePostRequestDto(title: $title, text: $text, mediaUrl: $mediaUrl)';
}


}

/// @nodoc
abstract mixin class $CreatePostRequestDtoCopyWith<$Res>  {
  factory $CreatePostRequestDtoCopyWith(CreatePostRequestDto value, $Res Function(CreatePostRequestDto) _then) = _$CreatePostRequestDtoCopyWithImpl;
@useResult
$Res call({
 String title, String text,@JsonKey(name: 'media_url') String? mediaUrl
});




}
/// @nodoc
class _$CreatePostRequestDtoCopyWithImpl<$Res>
    implements $CreatePostRequestDtoCopyWith<$Res> {
  _$CreatePostRequestDtoCopyWithImpl(this._self, this._then);

  final CreatePostRequestDto _self;
  final $Res Function(CreatePostRequestDto) _then;

/// Create a copy of CreatePostRequestDto
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


/// Adds pattern-matching-related methods to [CreatePostRequestDto].
extension CreatePostRequestDtoPatterns on CreatePostRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreatePostRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreatePostRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreatePostRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _CreatePostRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreatePostRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreatePostRequestDto() when $default != null:
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
case _CreatePostRequestDto() when $default != null:
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
case _CreatePostRequestDto():
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
case _CreatePostRequestDto() when $default != null:
return $default(_that.title,_that.text,_that.mediaUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreatePostRequestDto implements CreatePostRequestDto {
  const _CreatePostRequestDto({required this.title, required this.text, @JsonKey(name: 'media_url') this.mediaUrl});
  factory _CreatePostRequestDto.fromJson(Map<String, dynamic> json) => _$CreatePostRequestDtoFromJson(json);

@override final  String title;
@override final  String text;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;

/// Create a copy of CreatePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreatePostRequestDtoCopyWith<_CreatePostRequestDto> get copyWith => __$CreatePostRequestDtoCopyWithImpl<_CreatePostRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreatePostRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreatePostRequestDto&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,text,mediaUrl);

@override
String toString() {
  return 'CreatePostRequestDto(title: $title, text: $text, mediaUrl: $mediaUrl)';
}


}

/// @nodoc
abstract mixin class _$CreatePostRequestDtoCopyWith<$Res> implements $CreatePostRequestDtoCopyWith<$Res> {
  factory _$CreatePostRequestDtoCopyWith(_CreatePostRequestDto value, $Res Function(_CreatePostRequestDto) _then) = __$CreatePostRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, String text,@JsonKey(name: 'media_url') String? mediaUrl
});




}
/// @nodoc
class __$CreatePostRequestDtoCopyWithImpl<$Res>
    implements _$CreatePostRequestDtoCopyWith<$Res> {
  __$CreatePostRequestDtoCopyWithImpl(this._self, this._then);

  final _CreatePostRequestDto _self;
  final $Res Function(_CreatePostRequestDto) _then;

/// Create a copy of CreatePostRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? text = null,Object? mediaUrl = freezed,}) {
  return _then(_CreatePostRequestDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
