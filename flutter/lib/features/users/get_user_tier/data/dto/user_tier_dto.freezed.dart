// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_tier_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserTierDto {

@JsonKey(name: 'tier_id') int get tierId;@JsonKey(name: 'tier_name') String get tierName;@JsonKey(name: 'tier_created_at') DateTime? get tierCreatedAt;
/// Create a copy of UserTierDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserTierDtoCopyWith<UserTierDto> get copyWith => _$UserTierDtoCopyWithImpl<UserTierDto>(this as UserTierDto, _$identity);

  /// Serializes this UserTierDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserTierDto&&(identical(other.tierId, tierId) || other.tierId == tierId)&&(identical(other.tierName, tierName) || other.tierName == tierName)&&(identical(other.tierCreatedAt, tierCreatedAt) || other.tierCreatedAt == tierCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tierId,tierName,tierCreatedAt);

@override
String toString() {
  return 'UserTierDto(tierId: $tierId, tierName: $tierName, tierCreatedAt: $tierCreatedAt)';
}


}

/// @nodoc
abstract mixin class $UserTierDtoCopyWith<$Res>  {
  factory $UserTierDtoCopyWith(UserTierDto value, $Res Function(UserTierDto) _then) = _$UserTierDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'tier_id') int tierId,@JsonKey(name: 'tier_name') String tierName,@JsonKey(name: 'tier_created_at') DateTime? tierCreatedAt
});




}
/// @nodoc
class _$UserTierDtoCopyWithImpl<$Res>
    implements $UserTierDtoCopyWith<$Res> {
  _$UserTierDtoCopyWithImpl(this._self, this._then);

  final UserTierDto _self;
  final $Res Function(UserTierDto) _then;

/// Create a copy of UserTierDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tierId = null,Object? tierName = null,Object? tierCreatedAt = freezed,}) {
  return _then(_self.copyWith(
tierId: null == tierId ? _self.tierId : tierId // ignore: cast_nullable_to_non_nullable
as int,tierName: null == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String,tierCreatedAt: freezed == tierCreatedAt ? _self.tierCreatedAt : tierCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserTierDto].
extension UserTierDtoPatterns on UserTierDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserTierDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserTierDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserTierDto value)  $default,){
final _that = this;
switch (_that) {
case _UserTierDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserTierDto value)?  $default,){
final _that = this;
switch (_that) {
case _UserTierDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'tier_id')  int tierId, @JsonKey(name: 'tier_name')  String tierName, @JsonKey(name: 'tier_created_at')  DateTime? tierCreatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserTierDto() when $default != null:
return $default(_that.tierId,_that.tierName,_that.tierCreatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'tier_id')  int tierId, @JsonKey(name: 'tier_name')  String tierName, @JsonKey(name: 'tier_created_at')  DateTime? tierCreatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserTierDto():
return $default(_that.tierId,_that.tierName,_that.tierCreatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'tier_id')  int tierId, @JsonKey(name: 'tier_name')  String tierName, @JsonKey(name: 'tier_created_at')  DateTime? tierCreatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserTierDto() when $default != null:
return $default(_that.tierId,_that.tierName,_that.tierCreatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserTierDto implements UserTierDto {
  const _UserTierDto({@JsonKey(name: 'tier_id') required this.tierId, @JsonKey(name: 'tier_name') required this.tierName, @JsonKey(name: 'tier_created_at') this.tierCreatedAt});
  factory _UserTierDto.fromJson(Map<String, dynamic> json) => _$UserTierDtoFromJson(json);

@override@JsonKey(name: 'tier_id') final  int tierId;
@override@JsonKey(name: 'tier_name') final  String tierName;
@override@JsonKey(name: 'tier_created_at') final  DateTime? tierCreatedAt;

/// Create a copy of UserTierDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserTierDtoCopyWith<_UserTierDto> get copyWith => __$UserTierDtoCopyWithImpl<_UserTierDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserTierDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserTierDto&&(identical(other.tierId, tierId) || other.tierId == tierId)&&(identical(other.tierName, tierName) || other.tierName == tierName)&&(identical(other.tierCreatedAt, tierCreatedAt) || other.tierCreatedAt == tierCreatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tierId,tierName,tierCreatedAt);

@override
String toString() {
  return 'UserTierDto(tierId: $tierId, tierName: $tierName, tierCreatedAt: $tierCreatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserTierDtoCopyWith<$Res> implements $UserTierDtoCopyWith<$Res> {
  factory _$UserTierDtoCopyWith(_UserTierDto value, $Res Function(_UserTierDto) _then) = __$UserTierDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'tier_id') int tierId,@JsonKey(name: 'tier_name') String tierName,@JsonKey(name: 'tier_created_at') DateTime? tierCreatedAt
});




}
/// @nodoc
class __$UserTierDtoCopyWithImpl<$Res>
    implements _$UserTierDtoCopyWith<$Res> {
  __$UserTierDtoCopyWithImpl(this._self, this._then);

  final _UserTierDto _self;
  final $Res Function(_UserTierDto) _then;

/// Create a copy of UserTierDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tierId = null,Object? tierName = null,Object? tierCreatedAt = freezed,}) {
  return _then(_UserTierDto(
tierId: null == tierId ? _self.tierId : tierId // ignore: cast_nullable_to_non_nullable
as int,tierName: null == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String,tierCreatedAt: freezed == tierCreatedAt ? _self.tierCreatedAt : tierCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
