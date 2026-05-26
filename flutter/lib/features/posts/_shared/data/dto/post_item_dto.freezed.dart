// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PostItemDto {

 int get id; String get username;@JsonKey(name: 'post_uuid') String get postUuid; String get status; String get title; String get text;@JsonKey(name: 'media_url') String? get mediaUrl;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'created_by_user_id') int get createdByUserId;
/// Create a copy of PostItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostItemDtoCopyWith<PostItemDto> get copyWith => _$PostItemDtoCopyWithImpl<PostItemDto>(this as PostItemDto, _$identity);

  /// Serializes this PostItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,postUuid,status,title,text,mediaUrl,createdAt,createdByUserId);

@override
String toString() {
  return 'PostItemDto(id: $id, username: $username, postUuid: $postUuid, status: $status, title: $title, text: $text, mediaUrl: $mediaUrl, createdAt: $createdAt, createdByUserId: $createdByUserId)';
}


}

/// @nodoc
abstract mixin class $PostItemDtoCopyWith<$Res>  {
  factory $PostItemDtoCopyWith(PostItemDto value, $Res Function(PostItemDto) _then) = _$PostItemDtoCopyWithImpl;
@useResult
$Res call({
 int id, String username,@JsonKey(name: 'post_uuid') String postUuid, String status, String title, String text,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'created_by_user_id') int createdByUserId
});




}
/// @nodoc
class _$PostItemDtoCopyWithImpl<$Res>
    implements $PostItemDtoCopyWith<$Res> {
  _$PostItemDtoCopyWithImpl(this._self, this._then);

  final PostItemDto _self;
  final $Res Function(PostItemDto) _then;

/// Create a copy of PostItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? username = null,Object? postUuid = null,Object? status = null,Object? title = null,Object? text = null,Object? mediaUrl = freezed,Object? createdAt = freezed,Object? createdByUserId = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByUserId: null == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PostItemDto].
extension PostItemDtoPatterns on PostItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PostItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PostItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PostItemDto value)  $default,){
final _that = this;
switch (_that) {
case _PostItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PostItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _PostItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String username, @JsonKey(name: 'post_uuid')  String postUuid,  String status,  String title,  String text, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'created_by_user_id')  int createdByUserId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PostItemDto() when $default != null:
return $default(_that.id,_that.username,_that.postUuid,_that.status,_that.title,_that.text,_that.mediaUrl,_that.createdAt,_that.createdByUserId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String username, @JsonKey(name: 'post_uuid')  String postUuid,  String status,  String title,  String text, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'created_by_user_id')  int createdByUserId)  $default,) {final _that = this;
switch (_that) {
case _PostItemDto():
return $default(_that.id,_that.username,_that.postUuid,_that.status,_that.title,_that.text,_that.mediaUrl,_that.createdAt,_that.createdByUserId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String username, @JsonKey(name: 'post_uuid')  String postUuid,  String status,  String title,  String text, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'created_by_user_id')  int createdByUserId)?  $default,) {final _that = this;
switch (_that) {
case _PostItemDto() when $default != null:
return $default(_that.id,_that.username,_that.postUuid,_that.status,_that.title,_that.text,_that.mediaUrl,_that.createdAt,_that.createdByUserId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PostItemDto implements PostItemDto {
  const _PostItemDto({required this.id, required this.username, @JsonKey(name: 'post_uuid') required this.postUuid, required this.status, this.title = '', this.text = '', @JsonKey(name: 'media_url') this.mediaUrl, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'created_by_user_id') required this.createdByUserId});
  factory _PostItemDto.fromJson(Map<String, dynamic> json) => _$PostItemDtoFromJson(json);

@override final  int id;
@override final  String username;
@override@JsonKey(name: 'post_uuid') final  String postUuid;
@override final  String status;
@override@JsonKey() final  String title;
@override@JsonKey() final  String text;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'created_by_user_id') final  int createdByUserId;

/// Create a copy of PostItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PostItemDtoCopyWith<_PostItemDto> get copyWith => __$PostItemDtoCopyWithImpl<_PostItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PostItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PostItemDto&&(identical(other.id, id) || other.id == id)&&(identical(other.username, username) || other.username == username)&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.status, status) || other.status == status)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,username,postUuid,status,title,text,mediaUrl,createdAt,createdByUserId);

@override
String toString() {
  return 'PostItemDto(id: $id, username: $username, postUuid: $postUuid, status: $status, title: $title, text: $text, mediaUrl: $mediaUrl, createdAt: $createdAt, createdByUserId: $createdByUserId)';
}


}

/// @nodoc
abstract mixin class _$PostItemDtoCopyWith<$Res> implements $PostItemDtoCopyWith<$Res> {
  factory _$PostItemDtoCopyWith(_PostItemDto value, $Res Function(_PostItemDto) _then) = __$PostItemDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, String username,@JsonKey(name: 'post_uuid') String postUuid, String status, String title, String text,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'created_by_user_id') int createdByUserId
});




}
/// @nodoc
class __$PostItemDtoCopyWithImpl<$Res>
    implements _$PostItemDtoCopyWith<$Res> {
  __$PostItemDtoCopyWithImpl(this._self, this._then);

  final _PostItemDto _self;
  final $Res Function(_PostItemDto) _then;

/// Create a copy of PostItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? username = null,Object? postUuid = null,Object? status = null,Object? title = null,Object? text = null,Object? mediaUrl = freezed,Object? createdAt = freezed,Object? createdByUserId = null,}) {
  return _then(_PostItemDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdByUserId: null == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
