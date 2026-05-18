// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moderation_log_entry_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ModerationLogEntryDto {

 int get id;@JsonKey(name: 'event_type') String get eventType;@JsonKey(name: 'created_at') DateTime get createdAt;@JsonKey(name: 'actor_user_id') int? get actorUserId;@JsonKey(name: 'actor_username') String? get actorUsername; String? get action; String? get message;
/// Create a copy of ModerationLogEntryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationLogEntryDtoCopyWith<ModerationLogEntryDto> get copyWith => _$ModerationLogEntryDtoCopyWithImpl<ModerationLogEntryDto>(this as ModerationLogEntryDto, _$identity);

  /// Serializes this ModerationLogEntryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationLogEntryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.actorUserId, actorUserId) || other.actorUserId == actorUserId)&&(identical(other.actorUsername, actorUsername) || other.actorUsername == actorUsername)&&(identical(other.action, action) || other.action == action)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventType,createdAt,actorUserId,actorUsername,action,message);

@override
String toString() {
  return 'ModerationLogEntryDto(id: $id, eventType: $eventType, createdAt: $createdAt, actorUserId: $actorUserId, actorUsername: $actorUsername, action: $action, message: $message)';
}


}

/// @nodoc
abstract mixin class $ModerationLogEntryDtoCopyWith<$Res>  {
  factory $ModerationLogEntryDtoCopyWith(ModerationLogEntryDto value, $Res Function(ModerationLogEntryDto) _then) = _$ModerationLogEntryDtoCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'event_type') String eventType,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'actor_user_id') int? actorUserId,@JsonKey(name: 'actor_username') String? actorUsername, String? action, String? message
});




}
/// @nodoc
class _$ModerationLogEntryDtoCopyWithImpl<$Res>
    implements $ModerationLogEntryDtoCopyWith<$Res> {
  _$ModerationLogEntryDtoCopyWithImpl(this._self, this._then);

  final ModerationLogEntryDto _self;
  final $Res Function(ModerationLogEntryDto) _then;

/// Create a copy of ModerationLogEntryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? eventType = null,Object? createdAt = null,Object? actorUserId = freezed,Object? actorUsername = freezed,Object? action = freezed,Object? message = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,actorUserId: freezed == actorUserId ? _self.actorUserId : actorUserId // ignore: cast_nullable_to_non_nullable
as int?,actorUsername: freezed == actorUsername ? _self.actorUsername : actorUsername // ignore: cast_nullable_to_non_nullable
as String?,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ModerationLogEntryDto].
extension ModerationLogEntryDtoPatterns on ModerationLogEntryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ModerationLogEntryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ModerationLogEntryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ModerationLogEntryDto value)  $default,){
final _that = this;
switch (_that) {
case _ModerationLogEntryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ModerationLogEntryDto value)?  $default,){
final _that = this;
switch (_that) {
case _ModerationLogEntryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'actor_user_id')  int? actorUserId, @JsonKey(name: 'actor_username')  String? actorUsername,  String? action,  String? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ModerationLogEntryDto() when $default != null:
return $default(_that.id,_that.eventType,_that.createdAt,_that.actorUserId,_that.actorUsername,_that.action,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'actor_user_id')  int? actorUserId, @JsonKey(name: 'actor_username')  String? actorUsername,  String? action,  String? message)  $default,) {final _that = this;
switch (_that) {
case _ModerationLogEntryDto():
return $default(_that.id,_that.eventType,_that.createdAt,_that.actorUserId,_that.actorUsername,_that.action,_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'event_type')  String eventType, @JsonKey(name: 'created_at')  DateTime createdAt, @JsonKey(name: 'actor_user_id')  int? actorUserId, @JsonKey(name: 'actor_username')  String? actorUsername,  String? action,  String? message)?  $default,) {final _that = this;
switch (_that) {
case _ModerationLogEntryDto() when $default != null:
return $default(_that.id,_that.eventType,_that.createdAt,_that.actorUserId,_that.actorUsername,_that.action,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ModerationLogEntryDto implements ModerationLogEntryDto {
  const _ModerationLogEntryDto({required this.id, @JsonKey(name: 'event_type') required this.eventType, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'actor_user_id') this.actorUserId, @JsonKey(name: 'actor_username') this.actorUsername, this.action, this.message});
  factory _ModerationLogEntryDto.fromJson(Map<String, dynamic> json) => _$ModerationLogEntryDtoFromJson(json);

@override final  int id;
@override@JsonKey(name: 'event_type') final  String eventType;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override@JsonKey(name: 'actor_user_id') final  int? actorUserId;
@override@JsonKey(name: 'actor_username') final  String? actorUsername;
@override final  String? action;
@override final  String? message;

/// Create a copy of ModerationLogEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModerationLogEntryDtoCopyWith<_ModerationLogEntryDto> get copyWith => __$ModerationLogEntryDtoCopyWithImpl<_ModerationLogEntryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModerationLogEntryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ModerationLogEntryDto&&(identical(other.id, id) || other.id == id)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.actorUserId, actorUserId) || other.actorUserId == actorUserId)&&(identical(other.actorUsername, actorUsername) || other.actorUsername == actorUsername)&&(identical(other.action, action) || other.action == action)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,eventType,createdAt,actorUserId,actorUsername,action,message);

@override
String toString() {
  return 'ModerationLogEntryDto(id: $id, eventType: $eventType, createdAt: $createdAt, actorUserId: $actorUserId, actorUsername: $actorUsername, action: $action, message: $message)';
}


}

/// @nodoc
abstract mixin class _$ModerationLogEntryDtoCopyWith<$Res> implements $ModerationLogEntryDtoCopyWith<$Res> {
  factory _$ModerationLogEntryDtoCopyWith(_ModerationLogEntryDto value, $Res Function(_ModerationLogEntryDto) _then) = __$ModerationLogEntryDtoCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'event_type') String eventType,@JsonKey(name: 'created_at') DateTime createdAt,@JsonKey(name: 'actor_user_id') int? actorUserId,@JsonKey(name: 'actor_username') String? actorUsername, String? action, String? message
});




}
/// @nodoc
class __$ModerationLogEntryDtoCopyWithImpl<$Res>
    implements _$ModerationLogEntryDtoCopyWith<$Res> {
  __$ModerationLogEntryDtoCopyWithImpl(this._self, this._then);

  final _ModerationLogEntryDto _self;
  final $Res Function(_ModerationLogEntryDto) _then;

/// Create a copy of ModerationLogEntryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? eventType = null,Object? createdAt = null,Object? actorUserId = freezed,Object? actorUsername = freezed,Object? action = freezed,Object? message = freezed,}) {
  return _then(_ModerationLogEntryDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,actorUserId: freezed == actorUserId ? _self.actorUserId : actorUserId // ignore: cast_nullable_to_non_nullable
as int?,actorUsername: freezed == actorUsername ? _self.actorUsername : actorUsername // ignore: cast_nullable_to_non_nullable
as String?,action: freezed == action ? _self.action : action // ignore: cast_nullable_to_non_nullable
as String?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
