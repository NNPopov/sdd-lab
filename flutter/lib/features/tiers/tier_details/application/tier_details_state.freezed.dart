// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tier_details_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TierDetailsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TierDetailsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TierDetailsState()';
}


}

/// @nodoc
class $TierDetailsStateCopyWith<$Res>  {
$TierDetailsStateCopyWith(TierDetailsState _, $Res Function(TierDetailsState) __);
}


/// Adds pattern-matching-related methods to [TierDetailsState].
extension TierDetailsStatePatterns on TierDetailsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TierDetailsInitial value)?  initial,TResult Function( TierDetailsLoading value)?  loading,TResult Function( TierDetailsLoaded value)?  loaded,TResult Function( TierDetailsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TierDetailsInitial() when initial != null:
return initial(_that);case TierDetailsLoading() when loading != null:
return loading(_that);case TierDetailsLoaded() when loaded != null:
return loaded(_that);case TierDetailsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TierDetailsInitial value)  initial,required TResult Function( TierDetailsLoading value)  loading,required TResult Function( TierDetailsLoaded value)  loaded,required TResult Function( TierDetailsError value)  error,}){
final _that = this;
switch (_that) {
case TierDetailsInitial():
return initial(_that);case TierDetailsLoading():
return loading(_that);case TierDetailsLoaded():
return loaded(_that);case TierDetailsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TierDetailsInitial value)?  initial,TResult? Function( TierDetailsLoading value)?  loading,TResult? Function( TierDetailsLoaded value)?  loaded,TResult? Function( TierDetailsError value)?  error,}){
final _that = this;
switch (_that) {
case TierDetailsInitial() when initial != null:
return initial(_that);case TierDetailsLoading() when loading != null:
return loading(_that);case TierDetailsLoaded() when loaded != null:
return loaded(_that);case TierDetailsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( TierDetail tier)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TierDetailsInitial() when initial != null:
return initial();case TierDetailsLoading() when loading != null:
return loading();case TierDetailsLoaded() when loaded != null:
return loaded(_that.tier);case TierDetailsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( TierDetail tier)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case TierDetailsInitial():
return initial();case TierDetailsLoading():
return loading();case TierDetailsLoaded():
return loaded(_that.tier);case TierDetailsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( TierDetail tier)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case TierDetailsInitial() when initial != null:
return initial();case TierDetailsLoading() when loading != null:
return loading();case TierDetailsLoaded() when loaded != null:
return loaded(_that.tier);case TierDetailsError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TierDetailsInitial implements TierDetailsState {
  const TierDetailsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TierDetailsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TierDetailsState.initial()';
}


}




/// @nodoc


class TierDetailsLoading implements TierDetailsState {
  const TierDetailsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TierDetailsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TierDetailsState.loading()';
}


}




/// @nodoc


class TierDetailsLoaded implements TierDetailsState {
  const TierDetailsLoaded({required this.tier});
  

 final  TierDetail tier;

/// Create a copy of TierDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TierDetailsLoadedCopyWith<TierDetailsLoaded> get copyWith => _$TierDetailsLoadedCopyWithImpl<TierDetailsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TierDetailsLoaded&&(identical(other.tier, tier) || other.tier == tier));
}


@override
int get hashCode => Object.hash(runtimeType,tier);

@override
String toString() {
  return 'TierDetailsState.loaded(tier: $tier)';
}


}

/// @nodoc
abstract mixin class $TierDetailsLoadedCopyWith<$Res> implements $TierDetailsStateCopyWith<$Res> {
  factory $TierDetailsLoadedCopyWith(TierDetailsLoaded value, $Res Function(TierDetailsLoaded) _then) = _$TierDetailsLoadedCopyWithImpl;
@useResult
$Res call({
 TierDetail tier
});




}
/// @nodoc
class _$TierDetailsLoadedCopyWithImpl<$Res>
    implements $TierDetailsLoadedCopyWith<$Res> {
  _$TierDetailsLoadedCopyWithImpl(this._self, this._then);

  final TierDetailsLoaded _self;
  final $Res Function(TierDetailsLoaded) _then;

/// Create a copy of TierDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tier = null,}) {
  return _then(TierDetailsLoaded(
tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as TierDetail,
  ));
}


}

/// @nodoc


class TierDetailsError implements TierDetailsState {
  const TierDetailsError({required this.failure});
  

 final  Failure failure;

/// Create a copy of TierDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TierDetailsErrorCopyWith<TierDetailsError> get copyWith => _$TierDetailsErrorCopyWithImpl<TierDetailsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TierDetailsError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TierDetailsState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TierDetailsErrorCopyWith<$Res> implements $TierDetailsStateCopyWith<$Res> {
  factory $TierDetailsErrorCopyWith(TierDetailsError value, $Res Function(TierDetailsError) _then) = _$TierDetailsErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TierDetailsErrorCopyWithImpl<$Res>
    implements $TierDetailsErrorCopyWith<$Res> {
  _$TierDetailsErrorCopyWithImpl(this._self, this._then);

  final TierDetailsError _self;
  final $Res Function(TierDetailsError) _then;

/// Create a copy of TierDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TierDetailsError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TierDetailsState
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
