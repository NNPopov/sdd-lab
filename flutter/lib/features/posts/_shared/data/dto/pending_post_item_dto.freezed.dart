// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_post_item_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingPostItemDto {

@JsonKey(name: 'post_uuid') String get postUuid; String get title; String get text; String get status;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'author_username') String get authorUsername;@JsonKey(name: 'moderation_log') List<ModerationLogEntryDto> get moderationLog;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'media_url') String? get mediaUrl;
/// Create a copy of PendingPostItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingPostItemDtoCopyWith<PendingPostItemDto> get copyWith => _$PendingPostItemDtoCopyWithImpl<PendingPostItemDto>(this as PendingPostItemDto, _$identity);

  /// Serializes this PendingPostItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPostItemDto&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.authorUsername, authorUsername) || other.authorUsername == authorUsername)&&const DeepCollectionEquality().equals(other.moderationLog, moderationLog)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postUuid,title,text,status,createdAt,authorUsername,const DeepCollectionEquality().hash(moderationLog),updatedAt,mediaUrl);

@override
String toString() {
  return 'PendingPostItemDto(postUuid: $postUuid, title: $title, text: $text, status: $status, createdAt: $createdAt, authorUsername: $authorUsername, moderationLog: $moderationLog, updatedAt: $updatedAt, mediaUrl: $mediaUrl)';
}


}

/// @nodoc
abstract mixin class $PendingPostItemDtoCopyWith<$Res>  {
  factory $PendingPostItemDtoCopyWith(PendingPostItemDto value, $Res Function(PendingPostItemDto) _then) = _$PendingPostItemDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'post_uuid') String postUuid, String title, String text, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'author_username') String authorUsername,@JsonKey(name: 'moderation_log') List<ModerationLogEntryDto> moderationLog,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'media_url') String? mediaUrl
});




}
/// @nodoc
class _$PendingPostItemDtoCopyWithImpl<$Res>
    implements $PendingPostItemDtoCopyWith<$Res> {
  _$PendingPostItemDtoCopyWithImpl(this._self, this._then);

  final PendingPostItemDto _self;
  final $Res Function(PendingPostItemDto) _then;

/// Create a copy of PendingPostItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? postUuid = null,Object? title = null,Object? text = null,Object? status = null,Object? createdAt = null,Object? authorUsername = null,Object? moderationLog = null,Object? updatedAt = freezed,Object? mediaUrl = freezed,}) {
  return _then(_self.copyWith(
postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,authorUsername: null == authorUsername ? _self.authorUsername : authorUsername // ignore: cast_nullable_to_non_nullable
as String,moderationLog: null == moderationLog ? _self.moderationLog : moderationLog // ignore: cast_nullable_to_non_nullable
as List<ModerationLogEntryDto>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingPostItemDto].
extension PendingPostItemDtoPatterns on PendingPostItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingPostItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingPostItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingPostItemDto value)  $default,){
final _that = this;
switch (_that) {
case _PendingPostItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingPostItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _PendingPostItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_uuid')  String postUuid,  String title,  String text,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'author_username')  String authorUsername, @JsonKey(name: 'moderation_log')  List<ModerationLogEntryDto> moderationLog, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'media_url')  String? mediaUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingPostItemDto() when $default != null:
return $default(_that.postUuid,_that.title,_that.text,_that.status,_that.createdAt,_that.authorUsername,_that.moderationLog,_that.updatedAt,_that.mediaUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'post_uuid')  String postUuid,  String title,  String text,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'author_username')  String authorUsername, @JsonKey(name: 'moderation_log')  List<ModerationLogEntryDto> moderationLog, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'media_url')  String? mediaUrl)  $default,) {final _that = this;
switch (_that) {
case _PendingPostItemDto():
return $default(_that.postUuid,_that.title,_that.text,_that.status,_that.createdAt,_that.authorUsername,_that.moderationLog,_that.updatedAt,_that.mediaUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'post_uuid')  String postUuid,  String title,  String text,  String status, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'author_username')  String authorUsername, @JsonKey(name: 'moderation_log')  List<ModerationLogEntryDto> moderationLog, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'media_url')  String? mediaUrl)?  $default,) {final _that = this;
switch (_that) {
case _PendingPostItemDto() when $default != null:
return $default(_that.postUuid,_that.title,_that.text,_that.status,_that.createdAt,_that.authorUsername,_that.moderationLog,_that.updatedAt,_that.mediaUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingPostItemDto implements PendingPostItemDto {
  const _PendingPostItemDto({@JsonKey(name: 'post_uuid') required this.postUuid, required this.title, required this.text, required this.status, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'author_username') required this.authorUsername, @JsonKey(name: 'moderation_log') final  List<ModerationLogEntryDto> moderationLog = const [], @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'media_url') this.mediaUrl}): _moderationLog = moderationLog;
  factory _PendingPostItemDto.fromJson(Map<String, dynamic> json) => _$PendingPostItemDtoFromJson(json);

@override@JsonKey(name: 'post_uuid') final  String postUuid;
@override final  String title;
@override final  String text;
@override final  String status;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'author_username') final  String authorUsername;
 final  List<ModerationLogEntryDto> _moderationLog;
@override@JsonKey(name: 'moderation_log') List<ModerationLogEntryDto> get moderationLog {
  if (_moderationLog is EqualUnmodifiableListView) return _moderationLog;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_moderationLog);
}

@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;

/// Create a copy of PendingPostItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingPostItemDtoCopyWith<_PendingPostItemDto> get copyWith => __$PendingPostItemDtoCopyWithImpl<_PendingPostItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingPostItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingPostItemDto&&(identical(other.postUuid, postUuid) || other.postUuid == postUuid)&&(identical(other.title, title) || other.title == title)&&(identical(other.text, text) || other.text == text)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.authorUsername, authorUsername) || other.authorUsername == authorUsername)&&const DeepCollectionEquality().equals(other._moderationLog, _moderationLog)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,postUuid,title,text,status,createdAt,authorUsername,const DeepCollectionEquality().hash(_moderationLog),updatedAt,mediaUrl);

@override
String toString() {
  return 'PendingPostItemDto(postUuid: $postUuid, title: $title, text: $text, status: $status, createdAt: $createdAt, authorUsername: $authorUsername, moderationLog: $moderationLog, updatedAt: $updatedAt, mediaUrl: $mediaUrl)';
}


}

/// @nodoc
abstract mixin class _$PendingPostItemDtoCopyWith<$Res> implements $PendingPostItemDtoCopyWith<$Res> {
  factory _$PendingPostItemDtoCopyWith(_PendingPostItemDto value, $Res Function(_PendingPostItemDto) _then) = __$PendingPostItemDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'post_uuid') String postUuid, String title, String text, String status,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'author_username') String authorUsername,@JsonKey(name: 'moderation_log') List<ModerationLogEntryDto> moderationLog,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'media_url') String? mediaUrl
});




}
/// @nodoc
class __$PendingPostItemDtoCopyWithImpl<$Res>
    implements _$PendingPostItemDtoCopyWith<$Res> {
  __$PendingPostItemDtoCopyWithImpl(this._self, this._then);

  final _PendingPostItemDto _self;
  final $Res Function(_PendingPostItemDto) _then;

/// Create a copy of PendingPostItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? postUuid = null,Object? title = null,Object? text = null,Object? status = null,Object? createdAt = null,Object? authorUsername = null,Object? moderationLog = null,Object? updatedAt = freezed,Object? mediaUrl = freezed,}) {
  return _then(_PendingPostItemDto(
postUuid: null == postUuid ? _self.postUuid : postUuid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,authorUsername: null == authorUsername ? _self.authorUsername : authorUsername // ignore: cast_nullable_to_non_nullable
as String,moderationLog: null == moderationLog ? _self._moderationLog : moderationLog // ignore: cast_nullable_to_non_nullable
as List<ModerationLogEntryDto>,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
