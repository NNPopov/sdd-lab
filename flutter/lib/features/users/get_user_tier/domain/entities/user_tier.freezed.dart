// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_tier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserTier {

 String get tierName; DateTime? get tierCreatedAt;
/// Create a copy of UserTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserTierCopyWith<UserTier> get copyWith => _$UserTierCopyWithImpl<UserTier>(this as UserTier, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserTier&&(identical(other.tierName, tierName) || other.tierName == tierName)&&(identical(other.tierCreatedAt, tierCreatedAt) || other.tierCreatedAt == tierCreatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,tierName,tierCreatedAt);

@override
String toString() {
  return 'UserTier(tierName: $tierName, tierCreatedAt: $tierCreatedAt)';
}


}

/// @nodoc
abstract mixin class $UserTierCopyWith<$Res>  {
  factory $UserTierCopyWith(UserTier value, $Res Function(UserTier) _then) = _$UserTierCopyWithImpl;
@useResult
$Res call({
 String tierName, DateTime? tierCreatedAt
});




}
/// @nodoc
class _$UserTierCopyWithImpl<$Res>
    implements $UserTierCopyWith<$Res> {
  _$UserTierCopyWithImpl(this._self, this._then);

  final UserTier _self;
  final $Res Function(UserTier) _then;

/// Create a copy of UserTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tierName = null,Object? tierCreatedAt = freezed,}) {
  return _then(_self.copyWith(
tierName: null == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String,tierCreatedAt: freezed == tierCreatedAt ? _self.tierCreatedAt : tierCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserTier].
extension UserTierPatterns on UserTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserTier value)  $default,){
final _that = this;
switch (_that) {
case _UserTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserTier value)?  $default,){
final _that = this;
switch (_that) {
case _UserTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tierName,  DateTime? tierCreatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserTier() when $default != null:
return $default(_that.tierName,_that.tierCreatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tierName,  DateTime? tierCreatedAt)  $default,) {final _that = this;
switch (_that) {
case _UserTier():
return $default(_that.tierName,_that.tierCreatedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tierName,  DateTime? tierCreatedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserTier() when $default != null:
return $default(_that.tierName,_that.tierCreatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _UserTier implements UserTier {
  const _UserTier({required this.tierName, this.tierCreatedAt});
  

@override final  String tierName;
@override final  DateTime? tierCreatedAt;

/// Create a copy of UserTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserTierCopyWith<_UserTier> get copyWith => __$UserTierCopyWithImpl<_UserTier>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserTier&&(identical(other.tierName, tierName) || other.tierName == tierName)&&(identical(other.tierCreatedAt, tierCreatedAt) || other.tierCreatedAt == tierCreatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,tierName,tierCreatedAt);

@override
String toString() {
  return 'UserTier(tierName: $tierName, tierCreatedAt: $tierCreatedAt)';
}


}

/// @nodoc
abstract mixin class _$UserTierCopyWith<$Res> implements $UserTierCopyWith<$Res> {
  factory _$UserTierCopyWith(_UserTier value, $Res Function(_UserTier) _then) = __$UserTierCopyWithImpl;
@override @useResult
$Res call({
 String tierName, DateTime? tierCreatedAt
});




}
/// @nodoc
class __$UserTierCopyWithImpl<$Res>
    implements _$UserTierCopyWith<$Res> {
  __$UserTierCopyWithImpl(this._self, this._then);

  final _UserTier _self;
  final $Res Function(_UserTier) _then;

/// Create a copy of UserTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tierName = null,Object? tierCreatedAt = freezed,}) {
  return _then(_UserTier(
tierName: null == tierName ? _self.tierName : tierName // ignore: cast_nullable_to_non_nullable
as String,tierCreatedAt: freezed == tierCreatedAt ? _self.tierCreatedAt : tierCreatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
