// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'erase_db_user_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EraseDbUserState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbUserState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbUserState()';
}


}

/// @nodoc
class $EraseDbUserStateCopyWith<$Res>  {
$EraseDbUserStateCopyWith(EraseDbUserState _, $Res Function(EraseDbUserState) __);
}


/// Adds pattern-matching-related methods to [EraseDbUserState].
extension EraseDbUserStatePatterns on EraseDbUserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EraseDbUserInitial value)?  initial,TResult Function( EraseDbUserConfirming value)?  confirming,TResult Function( EraseDbUserDeleting value)?  deleting,TResult Function( EraseDbUserSuccess value)?  success,TResult Function( EraseDbUserFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EraseDbUserInitial() when initial != null:
return initial(_that);case EraseDbUserConfirming() when confirming != null:
return confirming(_that);case EraseDbUserDeleting() when deleting != null:
return deleting(_that);case EraseDbUserSuccess() when success != null:
return success(_that);case EraseDbUserFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EraseDbUserInitial value)  initial,required TResult Function( EraseDbUserConfirming value)  confirming,required TResult Function( EraseDbUserDeleting value)  deleting,required TResult Function( EraseDbUserSuccess value)  success,required TResult Function( EraseDbUserFailure value)  failure,}){
final _that = this;
switch (_that) {
case EraseDbUserInitial():
return initial(_that);case EraseDbUserConfirming():
return confirming(_that);case EraseDbUserDeleting():
return deleting(_that);case EraseDbUserSuccess():
return success(_that);case EraseDbUserFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EraseDbUserInitial value)?  initial,TResult? Function( EraseDbUserConfirming value)?  confirming,TResult? Function( EraseDbUserDeleting value)?  deleting,TResult? Function( EraseDbUserSuccess value)?  success,TResult? Function( EraseDbUserFailure value)?  failure,}){
final _that = this;
switch (_that) {
case EraseDbUserInitial() when initial != null:
return initial(_that);case EraseDbUserConfirming() when confirming != null:
return confirming(_that);case EraseDbUserDeleting() when deleting != null:
return deleting(_that);case EraseDbUserSuccess() when success != null:
return success(_that);case EraseDbUserFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  confirming,TResult Function()?  deleting,TResult Function()?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EraseDbUserInitial() when initial != null:
return initial();case EraseDbUserConfirming() when confirming != null:
return confirming();case EraseDbUserDeleting() when deleting != null:
return deleting();case EraseDbUserSuccess() when success != null:
return success();case EraseDbUserFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  confirming,required TResult Function()  deleting,required TResult Function()  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case EraseDbUserInitial():
return initial();case EraseDbUserConfirming():
return confirming();case EraseDbUserDeleting():
return deleting();case EraseDbUserSuccess():
return success();case EraseDbUserFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  confirming,TResult? Function()?  deleting,TResult? Function()?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case EraseDbUserInitial() when initial != null:
return initial();case EraseDbUserConfirming() when confirming != null:
return confirming();case EraseDbUserDeleting() when deleting != null:
return deleting();case EraseDbUserSuccess() when success != null:
return success();case EraseDbUserFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class EraseDbUserInitial implements EraseDbUserState {
  const EraseDbUserInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbUserInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbUserState.initial()';
}


}




/// @nodoc


class EraseDbUserConfirming implements EraseDbUserState {
  const EraseDbUserConfirming();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbUserConfirming);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbUserState.confirming()';
}


}




/// @nodoc


class EraseDbUserDeleting implements EraseDbUserState {
  const EraseDbUserDeleting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbUserDeleting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbUserState.deleting()';
}


}




/// @nodoc


class EraseDbUserSuccess implements EraseDbUserState {
  const EraseDbUserSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbUserSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbUserState.success()';
}


}




/// @nodoc


class EraseDbUserFailure implements EraseDbUserState {
  const EraseDbUserFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of EraseDbUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EraseDbUserFailureCopyWith<EraseDbUserFailure> get copyWith => _$EraseDbUserFailureCopyWithImpl<EraseDbUserFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbUserFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EraseDbUserState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EraseDbUserFailureCopyWith<$Res> implements $EraseDbUserStateCopyWith<$Res> {
  factory $EraseDbUserFailureCopyWith(EraseDbUserFailure value, $Res Function(EraseDbUserFailure) _then) = _$EraseDbUserFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EraseDbUserFailureCopyWithImpl<$Res>
    implements $EraseDbUserFailureCopyWith<$Res> {
  _$EraseDbUserFailureCopyWithImpl(this._self, this._then);

  final EraseDbUserFailure _self;
  final $Res Function(EraseDbUserFailure) _then;

/// Create a copy of EraseDbUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EraseDbUserFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EraseDbUserState
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
