// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delete_user_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeleteUserState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteUserState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteUserState()';
}


}

/// @nodoc
class $DeleteUserStateCopyWith<$Res>  {
$DeleteUserStateCopyWith(DeleteUserState _, $Res Function(DeleteUserState) __);
}


/// Adds pattern-matching-related methods to [DeleteUserState].
extension DeleteUserStatePatterns on DeleteUserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteUserInitial value)?  initial,TResult Function( DeleteUserConfirming value)?  confirming,TResult Function( DeleteUserDeleting value)?  deleting,TResult Function( DeleteUserSuccess value)?  success,TResult Function( DeleteUserFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteUserInitial() when initial != null:
return initial(_that);case DeleteUserConfirming() when confirming != null:
return confirming(_that);case DeleteUserDeleting() when deleting != null:
return deleting(_that);case DeleteUserSuccess() when success != null:
return success(_that);case DeleteUserFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteUserInitial value)  initial,required TResult Function( DeleteUserConfirming value)  confirming,required TResult Function( DeleteUserDeleting value)  deleting,required TResult Function( DeleteUserSuccess value)  success,required TResult Function( DeleteUserFailure value)  failure,}){
final _that = this;
switch (_that) {
case DeleteUserInitial():
return initial(_that);case DeleteUserConfirming():
return confirming(_that);case DeleteUserDeleting():
return deleting(_that);case DeleteUserSuccess():
return success(_that);case DeleteUserFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteUserInitial value)?  initial,TResult? Function( DeleteUserConfirming value)?  confirming,TResult? Function( DeleteUserDeleting value)?  deleting,TResult? Function( DeleteUserSuccess value)?  success,TResult? Function( DeleteUserFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DeleteUserInitial() when initial != null:
return initial(_that);case DeleteUserConfirming() when confirming != null:
return confirming(_that);case DeleteUserDeleting() when deleting != null:
return deleting(_that);case DeleteUserSuccess() when success != null:
return success(_that);case DeleteUserFailure() when failure != null:
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
case DeleteUserInitial() when initial != null:
return initial();case DeleteUserConfirming() when confirming != null:
return confirming();case DeleteUserDeleting() when deleting != null:
return deleting();case DeleteUserSuccess() when success != null:
return success();case DeleteUserFailure() when failure != null:
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
case DeleteUserInitial():
return initial();case DeleteUserConfirming():
return confirming();case DeleteUserDeleting():
return deleting();case DeleteUserSuccess():
return success();case DeleteUserFailure():
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
case DeleteUserInitial() when initial != null:
return initial();case DeleteUserConfirming() when confirming != null:
return confirming();case DeleteUserDeleting() when deleting != null:
return deleting();case DeleteUserSuccess() when success != null:
return success();case DeleteUserFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DeleteUserInitial implements DeleteUserState {
  const DeleteUserInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteUserInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteUserState.initial()';
}


}




/// @nodoc


class DeleteUserConfirming implements DeleteUserState {
  const DeleteUserConfirming();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteUserConfirming);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteUserState.confirming()';
}


}




/// @nodoc


class DeleteUserDeleting implements DeleteUserState {
  const DeleteUserDeleting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteUserDeleting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteUserState.deleting()';
}


}




/// @nodoc


class DeleteUserSuccess implements DeleteUserState {
  const DeleteUserSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteUserSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteUserState.success()';
}


}




/// @nodoc


class DeleteUserFailure implements DeleteUserState {
  const DeleteUserFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DeleteUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteUserFailureCopyWith<DeleteUserFailure> get copyWith => _$DeleteUserFailureCopyWithImpl<DeleteUserFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteUserFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DeleteUserState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DeleteUserFailureCopyWith<$Res> implements $DeleteUserStateCopyWith<$Res> {
  factory $DeleteUserFailureCopyWith(DeleteUserFailure value, $Res Function(DeleteUserFailure) _then) = _$DeleteUserFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DeleteUserFailureCopyWithImpl<$Res>
    implements $DeleteUserFailureCopyWith<$Res> {
  _$DeleteUserFailureCopyWithImpl(this._self, this._then);

  final DeleteUserFailure _self;
  final $Res Function(DeleteUserFailure) _then;

/// Create a copy of DeleteUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DeleteUserFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DeleteUserState
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
