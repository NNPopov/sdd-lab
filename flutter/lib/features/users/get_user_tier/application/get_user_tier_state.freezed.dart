// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'get_user_tier_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GetUserTierState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetUserTierState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GetUserTierState()';
}


}

/// @nodoc
class $GetUserTierStateCopyWith<$Res>  {
$GetUserTierStateCopyWith(GetUserTierState _, $Res Function(GetUserTierState) __);
}


/// Adds pattern-matching-related methods to [GetUserTierState].
extension GetUserTierStatePatterns on GetUserTierState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( GetUserTierInitial value)?  initial,TResult Function( GetUserTierLoading value)?  loading,TResult Function( GetUserTierLoaded value)?  loaded,TResult Function( GetUserTierError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case GetUserTierInitial() when initial != null:
return initial(_that);case GetUserTierLoading() when loading != null:
return loading(_that);case GetUserTierLoaded() when loaded != null:
return loaded(_that);case GetUserTierError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( GetUserTierInitial value)  initial,required TResult Function( GetUserTierLoading value)  loading,required TResult Function( GetUserTierLoaded value)  loaded,required TResult Function( GetUserTierError value)  error,}){
final _that = this;
switch (_that) {
case GetUserTierInitial():
return initial(_that);case GetUserTierLoading():
return loading(_that);case GetUserTierLoaded():
return loaded(_that);case GetUserTierError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( GetUserTierInitial value)?  initial,TResult? Function( GetUserTierLoading value)?  loading,TResult? Function( GetUserTierLoaded value)?  loaded,TResult? Function( GetUserTierError value)?  error,}){
final _that = this;
switch (_that) {
case GetUserTierInitial() when initial != null:
return initial(_that);case GetUserTierLoading() when loading != null:
return loading(_that);case GetUserTierLoaded() when loaded != null:
return loaded(_that);case GetUserTierError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( UserTier tier)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case GetUserTierInitial() when initial != null:
return initial();case GetUserTierLoading() when loading != null:
return loading();case GetUserTierLoaded() when loaded != null:
return loaded(_that.tier);case GetUserTierError() when error != null:
return error(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( UserTier tier)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case GetUserTierInitial():
return initial();case GetUserTierLoading():
return loading();case GetUserTierLoaded():
return loaded(_that.tier);case GetUserTierError():
return error(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( UserTier tier)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case GetUserTierInitial() when initial != null:
return initial();case GetUserTierLoading() when loading != null:
return loading();case GetUserTierLoaded() when loaded != null:
return loaded(_that.tier);case GetUserTierError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class GetUserTierInitial implements GetUserTierState {
  const GetUserTierInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetUserTierInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GetUserTierState.initial()';
}


}




/// @nodoc


class GetUserTierLoading implements GetUserTierState {
  const GetUserTierLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetUserTierLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'GetUserTierState.loading()';
}


}




/// @nodoc


class GetUserTierLoaded implements GetUserTierState {
  const GetUserTierLoaded(this.tier);
  

 final  UserTier tier;

/// Create a copy of GetUserTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetUserTierLoadedCopyWith<GetUserTierLoaded> get copyWith => _$GetUserTierLoadedCopyWithImpl<GetUserTierLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetUserTierLoaded&&(identical(other.tier, tier) || other.tier == tier));
}


@override
int get hashCode => Object.hash(runtimeType,tier);

@override
String toString() {
  return 'GetUserTierState.loaded(tier: $tier)';
}


}

/// @nodoc
abstract mixin class $GetUserTierLoadedCopyWith<$Res> implements $GetUserTierStateCopyWith<$Res> {
  factory $GetUserTierLoadedCopyWith(GetUserTierLoaded value, $Res Function(GetUserTierLoaded) _then) = _$GetUserTierLoadedCopyWithImpl;
@useResult
$Res call({
 UserTier tier
});


$UserTierCopyWith<$Res> get tier;

}
/// @nodoc
class _$GetUserTierLoadedCopyWithImpl<$Res>
    implements $GetUserTierLoadedCopyWith<$Res> {
  _$GetUserTierLoadedCopyWithImpl(this._self, this._then);

  final GetUserTierLoaded _self;
  final $Res Function(GetUserTierLoaded) _then;

/// Create a copy of GetUserTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tier = null,}) {
  return _then(GetUserTierLoaded(
null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as UserTier,
  ));
}

/// Create a copy of GetUserTierState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserTierCopyWith<$Res> get tier {
  
  return $UserTierCopyWith<$Res>(_self.tier, (value) {
    return _then(_self.copyWith(tier: value));
  });
}
}

/// @nodoc


class GetUserTierError implements GetUserTierState {
  const GetUserTierError(this.failure);
  

 final  Failure failure;

/// Create a copy of GetUserTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GetUserTierErrorCopyWith<GetUserTierError> get copyWith => _$GetUserTierErrorCopyWithImpl<GetUserTierError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GetUserTierError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'GetUserTierState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $GetUserTierErrorCopyWith<$Res> implements $GetUserTierStateCopyWith<$Res> {
  factory $GetUserTierErrorCopyWith(GetUserTierError value, $Res Function(GetUserTierError) _then) = _$GetUserTierErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$GetUserTierErrorCopyWithImpl<$Res>
    implements $GetUserTierErrorCopyWith<$Res> {
  _$GetUserTierErrorCopyWithImpl(this._self, this._then);

  final GetUserTierError _self;
  final $Res Function(GetUserTierError) _then;

/// Create a copy of GetUserTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(GetUserTierError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of GetUserTierState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
