// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_user_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UpdateUserRequestDto {

@JsonKey(includeIfNull: false) String? get name;@JsonKey(includeIfNull: false) String? get username;@JsonKey(includeIfNull: false) String? get email;@JsonKey(name: 'profile_image_url', includeIfNull: false) String? get profileImageUrl;
/// Create a copy of UpdateUserRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateUserRequestDtoCopyWith<UpdateUserRequestDto> get copyWith => _$UpdateUserRequestDtoCopyWithImpl<UpdateUserRequestDto>(this as UpdateUserRequestDto, _$identity);

  /// Serializes this UpdateUserRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserRequestDto&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,username,email,profileImageUrl);

@override
String toString() {
  return 'UpdateUserRequestDto(name: $name, username: $username, email: $email, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class $UpdateUserRequestDtoCopyWith<$Res>  {
  factory $UpdateUserRequestDtoCopyWith(UpdateUserRequestDto value, $Res Function(UpdateUserRequestDto) _then) = _$UpdateUserRequestDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false) String? username,@JsonKey(includeIfNull: false) String? email,@JsonKey(name: 'profile_image_url', includeIfNull: false) String? profileImageUrl
});




}
/// @nodoc
class _$UpdateUserRequestDtoCopyWithImpl<$Res>
    implements $UpdateUserRequestDtoCopyWith<$Res> {
  _$UpdateUserRequestDtoCopyWithImpl(this._self, this._then);

  final UpdateUserRequestDto _self;
  final $Res Function(UpdateUserRequestDto) _then;

/// Create a copy of UpdateUserRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = freezed,Object? username = freezed,Object? email = freezed,Object? profileImageUrl = freezed,}) {
  return _then(_self.copyWith(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [UpdateUserRequestDto].
extension UpdateUserRequestDtoPatterns on UpdateUserRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UpdateUserRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UpdateUserRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UpdateUserRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _UpdateUserRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UpdateUserRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _UpdateUserRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)  String? username, @JsonKey(includeIfNull: false)  String? email, @JsonKey(name: 'profile_image_url', includeIfNull: false)  String? profileImageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UpdateUserRequestDto() when $default != null:
return $default(_that.name,_that.username,_that.email,_that.profileImageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)  String? username, @JsonKey(includeIfNull: false)  String? email, @JsonKey(name: 'profile_image_url', includeIfNull: false)  String? profileImageUrl)  $default,) {final _that = this;
switch (_that) {
case _UpdateUserRequestDto():
return $default(_that.name,_that.username,_that.email,_that.profileImageUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? name, @JsonKey(includeIfNull: false)  String? username, @JsonKey(includeIfNull: false)  String? email, @JsonKey(name: 'profile_image_url', includeIfNull: false)  String? profileImageUrl)?  $default,) {final _that = this;
switch (_that) {
case _UpdateUserRequestDto() when $default != null:
return $default(_that.name,_that.username,_that.email,_that.profileImageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UpdateUserRequestDto implements UpdateUserRequestDto {
  const _UpdateUserRequestDto({@JsonKey(includeIfNull: false) this.name, @JsonKey(includeIfNull: false) this.username, @JsonKey(includeIfNull: false) this.email, @JsonKey(name: 'profile_image_url', includeIfNull: false) this.profileImageUrl});
  factory _UpdateUserRequestDto.fromJson(Map<String, dynamic> json) => _$UpdateUserRequestDtoFromJson(json);

@override@JsonKey(includeIfNull: false) final  String? name;
@override@JsonKey(includeIfNull: false) final  String? username;
@override@JsonKey(includeIfNull: false) final  String? email;
@override@JsonKey(name: 'profile_image_url', includeIfNull: false) final  String? profileImageUrl;

/// Create a copy of UpdateUserRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UpdateUserRequestDtoCopyWith<_UpdateUserRequestDto> get copyWith => __$UpdateUserRequestDtoCopyWithImpl<_UpdateUserRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UpdateUserRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UpdateUserRequestDto&&(identical(other.name, name) || other.name == name)&&(identical(other.username, username) || other.username == username)&&(identical(other.email, email) || other.email == email)&&(identical(other.profileImageUrl, profileImageUrl) || other.profileImageUrl == profileImageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,username,email,profileImageUrl);

@override
String toString() {
  return 'UpdateUserRequestDto(name: $name, username: $username, email: $email, profileImageUrl: $profileImageUrl)';
}


}

/// @nodoc
abstract mixin class _$UpdateUserRequestDtoCopyWith<$Res> implements $UpdateUserRequestDtoCopyWith<$Res> {
  factory _$UpdateUserRequestDtoCopyWith(_UpdateUserRequestDto value, $Res Function(_UpdateUserRequestDto) _then) = __$UpdateUserRequestDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? name,@JsonKey(includeIfNull: false) String? username,@JsonKey(includeIfNull: false) String? email,@JsonKey(name: 'profile_image_url', includeIfNull: false) String? profileImageUrl
});




}
/// @nodoc
class __$UpdateUserRequestDtoCopyWithImpl<$Res>
    implements _$UpdateUserRequestDtoCopyWith<$Res> {
  __$UpdateUserRequestDtoCopyWithImpl(this._self, this._then);

  final _UpdateUserRequestDto _self;
  final $Res Function(_UpdateUserRequestDto) _then;

/// Create a copy of UpdateUserRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = freezed,Object? username = freezed,Object? email = freezed,Object? profileImageUrl = freezed,}) {
  return _then(_UpdateUserRequestDto(
name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,profileImageUrl: freezed == profileImageUrl ? _self.profileImageUrl : profileImageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
