// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostDto {

 int get id;@JsonKey(name: 'post_uuid') String get postUuid; String get status; String get title; String get text;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'media_url') String? get mediaUrl;@JsonKey(name: 'created_by_user_id') int get createdByUserId;
/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostDtoCopyWith<PostDto> get copyWith => _$PostDtoCopyWithImpl<PostDto>(this as PostDto, _$identity);

  /// Serializes this PostDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDto&&(identical(other.id, id) || other.id == id)&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,postUuid,status,title,text,createdAt,mediaUrl,createdByUserId);

@override
String toString() {
  return 'PostDto(id: $id, postUuid: $postUuid, status: $status, title: $title, text: $text, createdAt: $createdAt, mediaUrl: $mediaUrl, createdByUserId: $createdByUserId)';
}


}

/// @nodoc
abstract mixin class $PostDtoCopyWith<$Res>  {
  factory $PostDtoCopyWith(PostDto value, $Res Function(PostDto) _then) = _$PostDtoCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'post_uuid') String postUuid, String status, String title, String text,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'created_by_user_id') int createdByUserId
});




}
/// @nodoc
class _$PostDtoCopyWithImpl<$Res>
    implements $PostDtoCopyWith<$Res> {
  _$PostDtoCopyWithImpl(this._self, this._then);

  final PostDto _self;
  final $Res Function(PostDto) _then;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? postUuid = null,Object? status = null,Object? title = null,Object? text = null,Object? createdAt = freezed,Object? mediaUrl = freezed,Object? createdByUserId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,createdByUserId: null == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PostDto].
extension PostDtoPatterns on PostDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostDto value)  $default,){
final _that = this;
switch (_that) {
case _PostDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'post_uuid')  String postUuid,  String status,  String title,  String text, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'created_by_user_id')  int createdByUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostDto() when $default != null:
return $default(_that.id,_that.postUuid,_that.status,_that.title,_that.text,_that.createdAt,_that.mediaUrl,_that.createdByUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'post_uuid')  String postUuid,  String status,  String title,  String text, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'created_by_user_id')  int createdByUserId)  $default,) {final _that = this;
switch (_that) {
case _PostDto():
return $default(_that.id,_that.postUuid,_that.status,_that.title,_that.text,_that.createdAt,_that.mediaUrl,_that.createdByUserId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'post_uuid')  String postUuid,  String status,  String title,  String text, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'created_by_user_id')  int createdByUserId)?  $default,) {final _that = this;
switch (_that) {
case _PostDto() when $default != null:
return $default(_that.id,_that.postUuid,_that.status,_that.title,_that.text,_that.createdAt,_that.mediaUrl,_that.createdByUserId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostDto implements PostDto {
  const _PostDto({required this.id, @JsonKey(name: 'post_uuid') required this.postUuid, required this.status, this.title = '', this.text = '', @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'media_url') this.mediaUrl, @JsonKey(name: 'created_by_user_id') required this.createdByUserId});
  factory _PostDto.fromJson(Map<String, dynamic> json) => _$PostDtoFromJson(json);

@override final  int id;
@override@JsonKey(name: 'post_uuid') final  String postUuid;
@override final  String status;
@override@JsonKey() final  String title;
@override@JsonKey() final  String text;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;
@override@JsonKey(name: 'created_by_user_id') final  int createdByUserId;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostDtoCopyWith<_PostDto> get copyWith => __$PostDtoCopyWithImpl<_PostDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostDto&&(identical(other.id, id) || other.id == id)&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,postUuid,status,title,text,createdAt,mediaUrl,createdByUserId);

@override
String toString() {
  return 'PostDto(id: $id, postUuid: $postUuid, status: $status, title: $title, text: $text, createdAt: $createdAt, mediaUrl: $mediaUrl, createdByUserId: $createdByUserId)';
}


}

/// @nodoc
abstract mixin class _$PostDtoCopyWith<$Res> implements $PostDtoCopyWith<$Res> {
  factory _$PostDtoCopyWith(_PostDto value, $Res Function(_PostDto) _then) = __$PostDtoCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'post_uuid') String postUuid, String status, String title, String text,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'created_by_user_id') int createdByUserId
});




}
/// @nodoc
class __$PostDtoCopyWithImpl<$Res>
    implements _$PostDtoCopyWith<$Res> {
  __$PostDtoCopyWithImpl(this._self, this._then);

  final _PostDto _self;
  final $Res Function(_PostDto) _then;

/// Create a copy of PostDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? postUuid = null,Object? status = null,Object? title = null,Object? text = null,Object? createdAt = freezed,Object? mediaUrl = freezed,Object? createdByUserId = null,}) {
  return _then(_PostDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,createdByUserId: null == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
