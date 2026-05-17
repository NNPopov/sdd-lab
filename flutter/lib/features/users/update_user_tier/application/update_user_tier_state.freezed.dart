// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'update_user_tier_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UpdateUserTierState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserTierState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateUserTierState()';
}


}

/// @nodoc
class $UpdateUserTierStateCopyWith<$Res>  {
$UpdateUserTierStateCopyWith(UpdateUserTierState _, $Res Function(UpdateUserTierState) __);
}


/// Adds pattern-matching-related methods to [UpdateUserTierState].
extension UpdateUserTierStatePatterns on UpdateUserTierState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UpdateUserTierInitial value)?  initial,TResult Function( UpdateUserTierLoadingTiers value)?  loadingTiers,TResult Function( UpdateUserTierTiersLoaded value)?  tiersLoaded,TResult Function( UpdateUserTierSubmitting value)?  submitting,TResult Function( UpdateUserTierSuccess value)?  success,TResult Function( UpdateUserTierError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UpdateUserTierInitial() when initial != null:
return initial(_that);case UpdateUserTierLoadingTiers() when loadingTiers != null:
return loadingTiers(_that);case UpdateUserTierTiersLoaded() when tiersLoaded != null:
return tiersLoaded(_that);case UpdateUserTierSubmitting() when submitting != null:
return submitting(_that);case UpdateUserTierSuccess() when success != null:
return success(_that);case UpdateUserTierError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UpdateUserTierInitial value)  initial,required TResult Function( UpdateUserTierLoadingTiers value)  loadingTiers,required TResult Function( UpdateUserTierTiersLoaded value)  tiersLoaded,required TResult Function( UpdateUserTierSubmitting value)  submitting,required TResult Function( UpdateUserTierSuccess value)  success,required TResult Function( UpdateUserTierError value)  error,}){
final _that = this;
switch (_that) {
case UpdateUserTierInitial():
return initial(_that);case UpdateUserTierLoadingTiers():
return loadingTiers(_that);case UpdateUserTierTiersLoaded():
return tiersLoaded(_that);case UpdateUserTierSubmitting():
return submitting(_that);case UpdateUserTierSuccess():
return success(_that);case UpdateUserTierError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UpdateUserTierInitial value)?  initial,TResult? Function( UpdateUserTierLoadingTiers value)?  loadingTiers,TResult? Function( UpdateUserTierTiersLoaded value)?  tiersLoaded,TResult? Function( UpdateUserTierSubmitting value)?  submitting,TResult? Function( UpdateUserTierSuccess value)?  success,TResult? Function( UpdateUserTierError value)?  error,}){
final _that = this;
switch (_that) {
case UpdateUserTierInitial() when initial != null:
return initial(_that);case UpdateUserTierLoadingTiers() when loadingTiers != null:
return loadingTiers(_that);case UpdateUserTierTiersLoaded() when tiersLoaded != null:
return tiersLoaded(_that);case UpdateUserTierSubmitting() when submitting != null:
return submitting(_that);case UpdateUserTierSuccess() when success != null:
return success(_that);case UpdateUserTierError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loadingTiers,TResult Function( List<TierOption> tiers,  int? selectedTierId)?  tiersLoaded,TResult Function( List<TierOption> tiers,  int selectedTierId)?  submitting,TResult Function()?  success,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UpdateUserTierInitial() when initial != null:
return initial();case UpdateUserTierLoadingTiers() when loadingTiers != null:
return loadingTiers();case UpdateUserTierTiersLoaded() when tiersLoaded != null:
return tiersLoaded(_that.tiers,_that.selectedTierId);case UpdateUserTierSubmitting() when submitting != null:
return submitting(_that.tiers,_that.selectedTierId);case UpdateUserTierSuccess() when success != null:
return success();case UpdateUserTierError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loadingTiers,required TResult Function( List<TierOption> tiers,  int? selectedTierId)  tiersLoaded,required TResult Function( List<TierOption> tiers,  int selectedTierId)  submitting,required TResult Function()  success,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case UpdateUserTierInitial():
return initial();case UpdateUserTierLoadingTiers():
return loadingTiers();case UpdateUserTierTiersLoaded():
return tiersLoaded(_that.tiers,_that.selectedTierId);case UpdateUserTierSubmitting():
return submitting(_that.tiers,_that.selectedTierId);case UpdateUserTierSuccess():
return success();case UpdateUserTierError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loadingTiers,TResult? Function( List<TierOption> tiers,  int? selectedTierId)?  tiersLoaded,TResult? Function( List<TierOption> tiers,  int selectedTierId)?  submitting,TResult? Function()?  success,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case UpdateUserTierInitial() when initial != null:
return initial();case UpdateUserTierLoadingTiers() when loadingTiers != null:
return loadingTiers();case UpdateUserTierTiersLoaded() when tiersLoaded != null:
return tiersLoaded(_that.tiers,_that.selectedTierId);case UpdateUserTierSubmitting() when submitting != null:
return submitting(_that.tiers,_that.selectedTierId);case UpdateUserTierSuccess() when success != null:
return success();case UpdateUserTierError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class UpdateUserTierInitial implements UpdateUserTierState {
  const UpdateUserTierInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserTierInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateUserTierState.initial()';
}


}




/// @nodoc


class UpdateUserTierLoadingTiers implements UpdateUserTierState {
  const UpdateUserTierLoadingTiers();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserTierLoadingTiers);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateUserTierState.loadingTiers()';
}


}




/// @nodoc


class UpdateUserTierTiersLoaded implements UpdateUserTierState {
  const UpdateUserTierTiersLoaded({required final  List<TierOption> tiers, this.selectedTierId}): _tiers = tiers;
  

 final  List<TierOption> _tiers;
 List<TierOption> get tiers {
  if (_tiers is EqualUnmodifiableListView) return _tiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tiers);
}

 final  int? selectedTierId;

/// Create a copy of UpdateUserTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateUserTierTiersLoadedCopyWith<UpdateUserTierTiersLoaded> get copyWith => _$UpdateUserTierTiersLoadedCopyWithImpl<UpdateUserTierTiersLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserTierTiersLoaded&&const DeepCollectionEquality().equals(other._tiers, _tiers)&&(identical(other.selectedTierId, selectedTierId) || other.selectedTierId == selectedTierId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tiers),selectedTierId);

@override
String toString() {
  return 'UpdateUserTierState.tiersLoaded(tiers: $tiers, selectedTierId: $selectedTierId)';
}


}

/// @nodoc
abstract mixin class $UpdateUserTierTiersLoadedCopyWith<$Res> implements $UpdateUserTierStateCopyWith<$Res> {
  factory $UpdateUserTierTiersLoadedCopyWith(UpdateUserTierTiersLoaded value, $Res Function(UpdateUserTierTiersLoaded) _then) = _$UpdateUserTierTiersLoadedCopyWithImpl;
@useResult
$Res call({
 List<TierOption> tiers, int? selectedTierId
});




}
/// @nodoc
class _$UpdateUserTierTiersLoadedCopyWithImpl<$Res>
    implements $UpdateUserTierTiersLoadedCopyWith<$Res> {
  _$UpdateUserTierTiersLoadedCopyWithImpl(this._self, this._then);

  final UpdateUserTierTiersLoaded _self;
  final $Res Function(UpdateUserTierTiersLoaded) _then;

/// Create a copy of UpdateUserTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tiers = null,Object? selectedTierId = freezed,}) {
  return _then(UpdateUserTierTiersLoaded(
tiers: null == tiers ? _self._tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<TierOption>,selectedTierId: freezed == selectedTierId ? _self.selectedTierId : selectedTierId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class UpdateUserTierSubmitting implements UpdateUserTierState {
  const UpdateUserTierSubmitting({required final  List<TierOption> tiers, required this.selectedTierId}): _tiers = tiers;
  

 final  List<TierOption> _tiers;
 List<TierOption> get tiers {
  if (_tiers is EqualUnmodifiableListView) return _tiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tiers);
}

 final  int selectedTierId;

/// Create a copy of UpdateUserTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateUserTierSubmittingCopyWith<UpdateUserTierSubmitting> get copyWith => _$UpdateUserTierSubmittingCopyWithImpl<UpdateUserTierSubmitting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserTierSubmitting&&const DeepCollectionEquality().equals(other._tiers, _tiers)&&(identical(other.selectedTierId, selectedTierId) || other.selectedTierId == selectedTierId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tiers),selectedTierId);

@override
String toString() {
  return 'UpdateUserTierState.submitting(tiers: $tiers, selectedTierId: $selectedTierId)';
}


}

/// @nodoc
abstract mixin class $UpdateUserTierSubmittingCopyWith<$Res> implements $UpdateUserTierStateCopyWith<$Res> {
  factory $UpdateUserTierSubmittingCopyWith(UpdateUserTierSubmitting value, $Res Function(UpdateUserTierSubmitting) _then) = _$UpdateUserTierSubmittingCopyWithImpl;
@useResult
$Res call({
 List<TierOption> tiers, int selectedTierId
});




}
/// @nodoc
class _$UpdateUserTierSubmittingCopyWithImpl<$Res>
    implements $UpdateUserTierSubmittingCopyWith<$Res> {
  _$UpdateUserTierSubmittingCopyWithImpl(this._self, this._then);

  final UpdateUserTierSubmitting _self;
  final $Res Function(UpdateUserTierSubmitting) _then;

/// Create a copy of UpdateUserTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tiers = null,Object? selectedTierId = null,}) {
  return _then(UpdateUserTierSubmitting(
tiers: null == tiers ? _self._tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<TierOption>,selectedTierId: null == selectedTierId ? _self.selectedTierId : selectedTierId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class UpdateUserTierSuccess implements UpdateUserTierState {
  const UpdateUserTierSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserTierSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UpdateUserTierState.success()';
}


}




/// @nodoc


class UpdateUserTierError implements UpdateUserTierState {
  const UpdateUserTierError(this.failure);
  

 final  Failure failure;

/// Create a copy of UpdateUserTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UpdateUserTierErrorCopyWith<UpdateUserTierError> get copyWith => _$UpdateUserTierErrorCopyWithImpl<UpdateUserTierError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UpdateUserTierError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'UpdateUserTierState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $UpdateUserTierErrorCopyWith<$Res> implements $UpdateUserTierStateCopyWith<$Res> {
  factory $UpdateUserTierErrorCopyWith(UpdateUserTierError value, $Res Function(UpdateUserTierError) _then) = _$UpdateUserTierErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$UpdateUserTierErrorCopyWithImpl<$Res>
    implements $UpdateUserTierErrorCopyWith<$Res> {
  _$UpdateUserTierErrorCopyWithImpl(this._self, this._then);

  final UpdateUserTierError _self;
  final $Res Function(UpdateUserTierError) _then;

/// Create a copy of UpdateUserTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(UpdateUserTierError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of UpdateUserTierState
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
