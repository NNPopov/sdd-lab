// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delete_tier_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DeleteTierState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTierState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteTierState()';
}


}

/// @nodoc
class $DeleteTierStateCopyWith<$Res>  {
$DeleteTierStateCopyWith(DeleteTierState _, $Res Function(DeleteTierState) __);
}


/// Adds pattern-matching-related methods to [DeleteTierState].
extension DeleteTierStatePatterns on DeleteTierState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DeleteTierInitial value)?  initial,TResult Function( DeleteTierConfirming value)?  confirming,TResult Function( DeleteTierDeleting value)?  deleting,TResult Function( DeleteTierSuccess value)?  success,TResult Function( DeleteTierNotFound value)?  notFound,TResult Function( DeleteTierFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DeleteTierInitial() when initial != null:
return initial(_that);case DeleteTierConfirming() when confirming != null:
return confirming(_that);case DeleteTierDeleting() when deleting != null:
return deleting(_that);case DeleteTierSuccess() when success != null:
return success(_that);case DeleteTierNotFound() when notFound != null:
return notFound(_that);case DeleteTierFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DeleteTierInitial value)  initial,required TResult Function( DeleteTierConfirming value)  confirming,required TResult Function( DeleteTierDeleting value)  deleting,required TResult Function( DeleteTierSuccess value)  success,required TResult Function( DeleteTierNotFound value)  notFound,required TResult Function( DeleteTierFailure value)  failure,}){
final _that = this;
switch (_that) {
case DeleteTierInitial():
return initial(_that);case DeleteTierConfirming():
return confirming(_that);case DeleteTierDeleting():
return deleting(_that);case DeleteTierSuccess():
return success(_that);case DeleteTierNotFound():
return notFound(_that);case DeleteTierFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DeleteTierInitial value)?  initial,TResult? Function( DeleteTierConfirming value)?  confirming,TResult? Function( DeleteTierDeleting value)?  deleting,TResult? Function( DeleteTierSuccess value)?  success,TResult? Function( DeleteTierNotFound value)?  notFound,TResult? Function( DeleteTierFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DeleteTierInitial() when initial != null:
return initial(_that);case DeleteTierConfirming() when confirming != null:
return confirming(_that);case DeleteTierDeleting() when deleting != null:
return deleting(_that);case DeleteTierSuccess() when success != null:
return success(_that);case DeleteTierNotFound() when notFound != null:
return notFound(_that);case DeleteTierFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  confirming,TResult Function()?  deleting,TResult Function()?  success,TResult Function()?  notFound,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DeleteTierInitial() when initial != null:
return initial();case DeleteTierConfirming() when confirming != null:
return confirming();case DeleteTierDeleting() when deleting != null:
return deleting();case DeleteTierSuccess() when success != null:
return success();case DeleteTierNotFound() when notFound != null:
return notFound();case DeleteTierFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  confirming,required TResult Function()  deleting,required TResult Function()  success,required TResult Function()  notFound,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case DeleteTierInitial():
return initial();case DeleteTierConfirming():
return confirming();case DeleteTierDeleting():
return deleting();case DeleteTierSuccess():
return success();case DeleteTierNotFound():
return notFound();case DeleteTierFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  confirming,TResult? Function()?  deleting,TResult? Function()?  success,TResult? Function()?  notFound,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case DeleteTierInitial() when initial != null:
return initial();case DeleteTierConfirming() when confirming != null:
return confirming();case DeleteTierDeleting() when deleting != null:
return deleting();case DeleteTierSuccess() when success != null:
return success();case DeleteTierNotFound() when notFound != null:
return notFound();case DeleteTierFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DeleteTierInitial implements DeleteTierState {
  const DeleteTierInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTierInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteTierState.initial()';
}


}




/// @nodoc


class DeleteTierConfirming implements DeleteTierState {
  const DeleteTierConfirming();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTierConfirming);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteTierState.confirming()';
}


}




/// @nodoc


class DeleteTierDeleting implements DeleteTierState {
  const DeleteTierDeleting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTierDeleting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteTierState.deleting()';
}


}




/// @nodoc


class DeleteTierSuccess implements DeleteTierState {
  const DeleteTierSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTierSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteTierState.success()';
}


}




/// @nodoc


class DeleteTierNotFound implements DeleteTierState {
  const DeleteTierNotFound();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTierNotFound);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DeleteTierState.notFound()';
}


}




/// @nodoc


class DeleteTierFailure implements DeleteTierState {
  const DeleteTierFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DeleteTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeleteTierFailureCopyWith<DeleteTierFailure> get copyWith => _$DeleteTierFailureCopyWithImpl<DeleteTierFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeleteTierFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DeleteTierState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DeleteTierFailureCopyWith<$Res> implements $DeleteTierStateCopyWith<$Res> {
  factory $DeleteTierFailureCopyWith(DeleteTierFailure value, $Res Function(DeleteTierFailure) _then) = _$DeleteTierFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DeleteTierFailureCopyWithImpl<$Res>
    implements $DeleteTierFailureCopyWith<$Res> {
  _$DeleteTierFailureCopyWithImpl(this._self, this._then);

  final DeleteTierFailure _self;
  final $Res Function(DeleteTierFailure) _then;

/// Create a copy of DeleteTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DeleteTierFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DeleteTierState
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
