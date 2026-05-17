// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'current_user_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CurrentUserDto {

 int get id; String get name; String get username; String get email;@JsonKey(name: 'is_superuser') bool get isSuperuser;@JsonKey(name: 'is_moderator') bool get isModerator;@JsonKey(name: 'profile_image_url') String? get profileImageUrl;@JsonKey(name: 'tier_id') int? get tierId;
/// Create a copy of CurrentUserDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrentUserDtoCopyWith<CurrentUserDto> get copyWith => _$CurrentUserDtoCopyWithImpl<CurrentUserDto>(this as CurrentUserDto, _$identity);

  /// Serializes this CurrentUserDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrentUserDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.isSuperuser, isSuperuser) || other.isSuperuser == isSuperuser)&&(identical(other.isModerator, isModerator) || other.isModerator == isModerator)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.tierId, tierId) || other.tierId == tierId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,isSuperuser,isModerator,profileImageUrl,tierId);

@override
String toString() {
  return 'CurrentUserDto(id: $id, name: $name, username: $username, email: $email, isSuperuser: $isSuperuser, isModerator: $isModerator, profileImageUrl: $profileImageUrl, tierId: $tierId)';
}


}

/// @nodoc
abstract mixin class $CurrentUserDtoCopyWith<$Res>  {
  factory $CurrentUserDtoCopyWith(CurrentUserDto value, $Res Function(CurrentUserDto) _then) = _$CurrentUserDtoCopyWithImpl;
@useResult
$Res call({
 int id, String name, String username, String email,@JsonKey(name: 'is_superuser') bool isSuperuser,@JsonKey(name: 'is_moderator') bool isModerator,@JsonKey(name: 'profile_image_url') String? profileImageUrl,@JsonKey(name: 'tier_id') int? tierId
});




}
/// @nodoc
class _$CurrentUserDtoCopyWithImpl<$Res>
    implements $CurrentUserDtoCopyWith<$Res> {
  _$CurrentUserDtoCopyWithImpl(this._self, this._then);

  final CurrentUserDto _self;
  final $Res Function(CurrentUserDto) _then;

/// Create a copy of CurrentUserDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? username = null,Object? email = null,Object? isSuperuser = null,Object? isModerator = null,Object? profileImageUrl = freezed,Object? tierId = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,isSuperuser: null == isSuperuser ? _self.isSuperuser : isSuperuser // ignore: cast_nullable_to_non_nullable
as bool,isModerator: null == isModerator ? _self.isModerator : isModerator // ignore: cast_nullable_to_non_nullable
as bool,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,tierId: freezed == tierId ? _self.tierId : tierId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CurrentUserDto].
extension CurrentUserDtoPatterns on CurrentUserDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurrentUserDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurrentUserDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurrentUserDto value)  $default,){
final _that = this;
switch (_that) {
case _CurrentUserDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurrentUserDto value)?  $default,){
final _that = this;
switch (_that) {
case _CurrentUserDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String username,  String email, @JsonKey(name: 'is_superuser')  bool isSuperuser, @JsonKey(name: 'is_moderator')  bool isModerator, @JsonKey(name: 'profile_image_url')  String? profileImageUrl, @JsonKey(name: 'tier_id')  int? tierId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurrentUserDto() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.isSuperuser,_that.isModerator,_that.profileImageUrl,_that.tierId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String username,  String email, @JsonKey(name: 'is_superuser')  bool isSuperuser, @JsonKey(name: 'is_moderator')  bool isModerator, @JsonKey(name: 'profile_image_url')  String? profileImageUrl, @JsonKey(name: 'tier_id')  int? tierId)  $default,) {final _that = this;
switch (_that) {
case _CurrentUserDto():
return $default(_that.id,_that.name,_that.username,_that.email,_that.isSuperuser,_that.isModerator,_that.profileImageUrl,_that.tierId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String username,  String email, @JsonKey(name: 'is_superuser')  bool isSuperuser, @JsonKey(name: 'is_moderator')  bool isModerator, @JsonKey(name: 'profile_image_url')  String? profileImageUrl, @JsonKey(name: 'tier_id')  int? tierId)?  $default,) {final _that = this;
switch (_that) {
case _CurrentUserDto() when $default != null:
return $default(_that.id,_that.name,_that.username,_that.email,_that.isSuperuser,_that.isModerator,_that.profileImageUrl,_that.tierId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CurrentUserDto implements CurrentUserDto {
  const _CurrentUserDto({required this.id, required this.name, required this.username, required this.email, @JsonKey(name: 'is_superuser') this.isSuperuser = false, @JsonKey(name: 'is_moderator') this.isModerator = false, @JsonKey(name: 'profile_image_url') this.profileImageUrl, @JsonKey(name: 'tier_id') this.tierId});
  factory _CurrentUserDto.fromJson(Map<String, dynamic> json) => _$CurrentUserDtoFromJson(json);

@override final  int id;
@override final  String name;
@override final  String username;
@override final  String email;
@override@JsonKey(name: 'is_superuser') final  bool isSuperuser;
@override@JsonKey(name: 'is_moderator') final  bool isModerator;
@override@JsonKey(name: 'profile_image_url') final  String? profileImageUrl;
@override@JsonKey(name: 'tier_id') final  int? tierId;

/// Create a copy of CurrentUserDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrentUserDtoCopyWith<_CurrentUserDto> get copyWith => __$CurrentUserDtoCopyWithImpl<_CurrentUserDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CurrentUserDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurrentUserDto&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.isSuperuser, isSuperuser) || other.isSuperuser == isSuperuser)&&(identical(other.isModerator, isModerator) || other.isModerator == isModerator)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl)&&(identical(other.tierId, tierId) || other.tierId == tierId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,username,email,isSuperuser,isModerator,profileImageUrl,tierId);

@override
String toString() {
  return 'CurrentUserDto(id: $id, name: $name, username: $username, email: $email, isSuperuser: $isSuperuser, isModerator: $isModerator, profileImageUrl: $profileImageUrl, tierId: $tierId)';
}


}

/// @nodoc
abstract mixin class _$CurrentUserDtoCopyWith<$Res> implements $CurrentUserDtoCopyWith<$Res> {
  factory _$CurrentUserDtoCopyWith(_CurrentUserDto value, $Res Function(_CurrentUserDto) _then) = __$CurrentUserDtoCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String username, String email,@JsonKey(name: 'is_superuser') bool isSuperuser,@JsonKey(name: 'is_moderator') bool isModerator,@JsonKey(name: 'profile_image_url') String? profileImageUrl,@JsonKey(name: 'tier_id') int? tierId
});




}
/// @nodoc
class __$CurrentUserDtoCopyWithImpl<$Res>
    implements _$CurrentUserDtoCopyWith<$Res> {
  __$CurrentUserDtoCopyWithImpl(this._self, this._then);

  final _CurrentUserDto _self;
  final $Res Function(_CurrentUserDto) _then;

/// Create a copy of CurrentUserDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? username = null,Object? email = null,Object? isSuperuser = null,Object? isModerator = null,Object? profileImageUrl = freezed,Object? tierId = freezed,}) {
  return _then(_CurrentUserDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,isSuperuser: null == isSuperuser ? _self.isSuperuser : isSuperuser // ignore: cast_nullable_to_non_nullable
as bool,isModerator: null == isModerator ? _self.isModerator : isModerator // ignore: cast_nullable_to_non_nullable
as bool,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,tierId: freezed == tierId ? _self.tierId : tierId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
