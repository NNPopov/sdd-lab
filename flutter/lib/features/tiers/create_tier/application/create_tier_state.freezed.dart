// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_tier_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateTierState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTierState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreateTierState()';
}


}

/// @nodoc
class $CreateTierStateCopyWith<$Res>  {
$CreateTierStateCopyWith(CreateTierState _, $Res Function(CreateTierState) __);
}


/// Adds pattern-matching-related methods to [CreateTierState].
extension CreateTierStatePatterns on CreateTierState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreateTierIdle value)?  idle,TResult Function( CreateTierSubmitting value)?  submitting,TResult Function( CreateTierSuccess value)?  success,TResult Function( CreateTierFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreateTierIdle() when idle != null:
return idle(_that);case CreateTierSubmitting() when submitting != null:
return submitting(_that);case CreateTierSuccess() when success != null:
return success(_that);case CreateTierFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreateTierIdle value)  idle,required TResult Function( CreateTierSubmitting value)  submitting,required TResult Function( CreateTierSuccess value)  success,required TResult Function( CreateTierFailure value)  failure,}){
final _that = this;
switch (_that) {
case CreateTierIdle():
return idle(_that);case CreateTierSubmitting():
return submitting(_that);case CreateTierSuccess():
return success(_that);case CreateTierFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreateTierIdle value)?  idle,TResult? Function( CreateTierSubmitting value)?  submitting,TResult? Function( CreateTierSuccess value)?  success,TResult? Function( CreateTierFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CreateTierIdle() when idle != null:
return idle(_that);case CreateTierSubmitting() when submitting != null:
return submitting(_that);case CreateTierSuccess() when success != null:
return success(_that);case CreateTierFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  submitting,TResult Function( Tier tier)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreateTierIdle() when idle != null:
return idle();case CreateTierSubmitting() when submitting != null:
return submitting();case CreateTierSuccess() when success != null:
return success(_that.tier);case CreateTierFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  submitting,required TResult Function( Tier tier)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CreateTierIdle():
return idle();case CreateTierSubmitting():
return submitting();case CreateTierSuccess():
return success(_that.tier);case CreateTierFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  submitting,TResult? Function( Tier tier)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CreateTierIdle() when idle != null:
return idle();case CreateTierSubmitting() when submitting != null:
return submitting();case CreateTierSuccess() when success != null:
return success(_that.tier);case CreateTierFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CreateTierIdle implements CreateTierState {
  const CreateTierIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTierIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreateTierState.idle()';
}


}




/// @nodoc


class CreateTierSubmitting implements CreateTierState {
  const CreateTierSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTierSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreateTierState.submitting()';
}


}




/// @nodoc


class CreateTierSuccess implements CreateTierState {
  const CreateTierSuccess(this.tier);
  

 final  Tier tier;

/// Create a copy of CreateTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTierSuccessCopyWith<CreateTierSuccess> get copyWith => _$CreateTierSuccessCopyWithImpl<CreateTierSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTierSuccess&&(identical(other.tier, tier) || other.tier == tier));
}


@override
int get hashCode => Object.hash(runtimeType,tier);

@override
String toString() {
  return 'CreateTierState.success(tier: $tier)';
}


}

/// @nodoc
abstract mixin class $CreateTierSuccessCopyWith<$Res> implements $CreateTierStateCopyWith<$Res> {
  factory $CreateTierSuccessCopyWith(CreateTierSuccess value, $Res Function(CreateTierSuccess) _then) = _$CreateTierSuccessCopyWithImpl;
@useResult
$Res call({
 Tier tier
});




}
/// @nodoc
class _$CreateTierSuccessCopyWithImpl<$Res>
    implements $CreateTierSuccessCopyWith<$Res> {
  _$CreateTierSuccessCopyWithImpl(this._self, this._then);

  final CreateTierSuccess _self;
  final $Res Function(CreateTierSuccess) _then;

/// Create a copy of CreateTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tier = null,}) {
  return _then(CreateTierSuccess(
null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as Tier,
  ));
}


}

/// @nodoc


class CreateTierFailure implements CreateTierState {
  const CreateTierFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CreateTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTierFailureCopyWith<CreateTierFailure> get copyWith => _$CreateTierFailureCopyWithImpl<CreateTierFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTierFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CreateTierState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CreateTierFailureCopyWith<$Res> implements $CreateTierStateCopyWith<$Res> {
  factory $CreateTierFailureCopyWith(CreateTierFailure value, $Res Function(CreateTierFailure) _then) = _$CreateTierFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CreateTierFailureCopyWithImpl<$Res>
    implements $CreateTierFailureCopyWith<$Res> {
  _$CreateTierFailureCopyWithImpl(this._self, this._then);

  final CreateTierFailure _self;
  final $Res Function(CreateTierFailure) _then;

/// Create a copy of CreateTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CreateTierFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CreateTierState
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
