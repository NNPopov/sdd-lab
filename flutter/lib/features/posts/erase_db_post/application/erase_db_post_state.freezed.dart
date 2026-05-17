// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'erase_db_post_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EraseDbPostState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbPostState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbPostState()';
}


}

/// @nodoc
class $EraseDbPostStateCopyWith<$Res>  {
$EraseDbPostStateCopyWith(EraseDbPostState _, $Res Function(EraseDbPostState) __);
}


/// Adds pattern-matching-related methods to [EraseDbPostState].
extension EraseDbPostStatePatterns on EraseDbPostState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EraseDbPostInitial value)?  initial,TResult Function( EraseDbPostConfirming value)?  confirming,TResult Function( EraseDbPostDeleting value)?  deleting,TResult Function( EraseDbPostSuccess value)?  success,TResult Function( EraseDbPostFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EraseDbPostInitial() when initial != null:
return initial(_that);case EraseDbPostConfirming() when confirming != null:
return confirming(_that);case EraseDbPostDeleting() when deleting != null:
return deleting(_that);case EraseDbPostSuccess() when success != null:
return success(_that);case EraseDbPostFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EraseDbPostInitial value)  initial,required TResult Function( EraseDbPostConfirming value)  confirming,required TResult Function( EraseDbPostDeleting value)  deleting,required TResult Function( EraseDbPostSuccess value)  success,required TResult Function( EraseDbPostFailure value)  failure,}){
final _that = this;
switch (_that) {
case EraseDbPostInitial():
return initial(_that);case EraseDbPostConfirming():
return confirming(_that);case EraseDbPostDeleting():
return deleting(_that);case EraseDbPostSuccess():
return success(_that);case EraseDbPostFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EraseDbPostInitial value)?  initial,TResult? Function( EraseDbPostConfirming value)?  confirming,TResult? Function( EraseDbPostDeleting value)?  deleting,TResult? Function( EraseDbPostSuccess value)?  success,TResult? Function( EraseDbPostFailure value)?  failure,}){
final _that = this;
switch (_that) {
case EraseDbPostInitial() when initial != null:
return initial(_that);case EraseDbPostConfirming() when confirming != null:
return confirming(_that);case EraseDbPostDeleting() when deleting != null:
return deleting(_that);case EraseDbPostSuccess() when success != null:
return success(_that);case EraseDbPostFailure() when failure != null:
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
case EraseDbPostInitial() when initial != null:
return initial();case EraseDbPostConfirming() when confirming != null:
return confirming();case EraseDbPostDeleting() when deleting != null:
return deleting();case EraseDbPostSuccess() when success != null:
return success();case EraseDbPostFailure() when failure != null:
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
case EraseDbPostInitial():
return initial();case EraseDbPostConfirming():
return confirming();case EraseDbPostDeleting():
return deleting();case EraseDbPostSuccess():
return success();case EraseDbPostFailure():
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
case EraseDbPostInitial() when initial != null:
return initial();case EraseDbPostConfirming() when confirming != null:
return confirming();case EraseDbPostDeleting() when deleting != null:
return deleting();case EraseDbPostSuccess() when success != null:
return success();case EraseDbPostFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class EraseDbPostInitial implements EraseDbPostState {
  const EraseDbPostInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbPostInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbPostState.initial()';
}


}




/// @nodoc


class EraseDbPostConfirming implements EraseDbPostState {
  const EraseDbPostConfirming();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbPostConfirming);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbPostState.confirming()';
}


}




/// @nodoc


class EraseDbPostDeleting implements EraseDbPostState {
  const EraseDbPostDeleting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbPostDeleting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbPostState.deleting()';
}


}




/// @nodoc


class EraseDbPostSuccess implements EraseDbPostState {
  const EraseDbPostSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbPostSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EraseDbPostState.success()';
}


}




/// @nodoc


class EraseDbPostFailure implements EraseDbPostState {
  const EraseDbPostFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of EraseDbPostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EraseDbPostFailureCopyWith<EraseDbPostFailure> get copyWith => _$EraseDbPostFailureCopyWithImpl<EraseDbPostFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EraseDbPostFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EraseDbPostState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EraseDbPostFailureCopyWith<$Res> implements $EraseDbPostStateCopyWith<$Res> {
  factory $EraseDbPostFailureCopyWith(EraseDbPostFailure value, $Res Function(EraseDbPostFailure) _then) = _$EraseDbPostFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EraseDbPostFailureCopyWithImpl<$Res>
    implements $EraseDbPostFailureCopyWith<$Res> {
  _$EraseDbPostFailureCopyWithImpl(this._self, this._then);

  final EraseDbPostFailure _self;
  final $Res Function(EraseDbPostFailure) _then;

/// Create a copy of EraseDbPostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EraseDbPostFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EraseDbPostState
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
