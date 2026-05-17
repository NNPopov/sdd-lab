// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assign_moderator_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AssignModeratorState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignModeratorState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssignModeratorState()';
}


}

/// @nodoc
class $AssignModeratorStateCopyWith<$Res>  {
$AssignModeratorStateCopyWith(AssignModeratorState _, $Res Function(AssignModeratorState) __);
}


/// Adds pattern-matching-related methods to [AssignModeratorState].
extension AssignModeratorStatePatterns on AssignModeratorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AssignModeratorInitial value)?  initial,TResult Function( AssignModeratorLoading value)?  loading,TResult Function( AssignModeratorSuccess value)?  success,TResult Function( AssignModeratorError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AssignModeratorInitial() when initial != null:
return initial(_that);case AssignModeratorLoading() when loading != null:
return loading(_that);case AssignModeratorSuccess() when success != null:
return success(_that);case AssignModeratorError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AssignModeratorInitial value)  initial,required TResult Function( AssignModeratorLoading value)  loading,required TResult Function( AssignModeratorSuccess value)  success,required TResult Function( AssignModeratorError value)  error,}){
final _that = this;
switch (_that) {
case AssignModeratorInitial():
return initial(_that);case AssignModeratorLoading():
return loading(_that);case AssignModeratorSuccess():
return success(_that);case AssignModeratorError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AssignModeratorInitial value)?  initial,TResult? Function( AssignModeratorLoading value)?  loading,TResult? Function( AssignModeratorSuccess value)?  success,TResult? Function( AssignModeratorError value)?  error,}){
final _that = this;
switch (_that) {
case AssignModeratorInitial() when initial != null:
return initial(_that);case AssignModeratorLoading() when loading != null:
return loading(_that);case AssignModeratorSuccess() when success != null:
return success(_that);case AssignModeratorError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( bool isModerator)?  success,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AssignModeratorInitial() when initial != null:
return initial();case AssignModeratorLoading() when loading != null:
return loading();case AssignModeratorSuccess() when success != null:
return success(_that.isModerator);case AssignModeratorError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( bool isModerator)  success,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case AssignModeratorInitial():
return initial();case AssignModeratorLoading():
return loading();case AssignModeratorSuccess():
return success(_that.isModerator);case AssignModeratorError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( bool isModerator)?  success,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case AssignModeratorInitial() when initial != null:
return initial();case AssignModeratorLoading() when loading != null:
return loading();case AssignModeratorSuccess() when success != null:
return success(_that.isModerator);case AssignModeratorError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AssignModeratorInitial implements AssignModeratorState {
  const AssignModeratorInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignModeratorInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssignModeratorState.initial()';
}


}




/// @nodoc


class AssignModeratorLoading implements AssignModeratorState {
  const AssignModeratorLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignModeratorLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AssignModeratorState.loading()';
}


}




/// @nodoc


class AssignModeratorSuccess implements AssignModeratorState {
  const AssignModeratorSuccess({required this.isModerator});
  

 final  bool isModerator;

/// Create a copy of AssignModeratorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignModeratorSuccessCopyWith<AssignModeratorSuccess> get copyWith => _$AssignModeratorSuccessCopyWithImpl<AssignModeratorSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignModeratorSuccess&&(identical(other.isModerator, isModerator) || other.isModerator == isModerator));
}


@override
int get hashCode => Object.hash(runtimeType,isModerator);

@override
String toString() {
  return 'AssignModeratorState.success(isModerator: $isModerator)';
}


}

/// @nodoc
abstract mixin class $AssignModeratorSuccessCopyWith<$Res> implements $AssignModeratorStateCopyWith<$Res> {
  factory $AssignModeratorSuccessCopyWith(AssignModeratorSuccess value, $Res Function(AssignModeratorSuccess) _then) = _$AssignModeratorSuccessCopyWithImpl;
@useResult
$Res call({
 bool isModerator
});




}
/// @nodoc
class _$AssignModeratorSuccessCopyWithImpl<$Res>
    implements $AssignModeratorSuccessCopyWith<$Res> {
  _$AssignModeratorSuccessCopyWithImpl(this._self, this._then);

  final AssignModeratorSuccess _self;
  final $Res Function(AssignModeratorSuccess) _then;

/// Create a copy of AssignModeratorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? isModerator = null,}) {
  return _then(AssignModeratorSuccess(
isModerator: null == isModerator ? _self.isModerator : isModerator // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AssignModeratorError implements AssignModeratorState {
  const AssignModeratorError(this.failure);
  

 final  Failure failure;

/// Create a copy of AssignModeratorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssignModeratorErrorCopyWith<AssignModeratorError> get copyWith => _$AssignModeratorErrorCopyWithImpl<AssignModeratorError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssignModeratorError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'AssignModeratorState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AssignModeratorErrorCopyWith<$Res> implements $AssignModeratorStateCopyWith<$Res> {
  factory $AssignModeratorErrorCopyWith(AssignModeratorError value, $Res Function(AssignModeratorError) _then) = _$AssignModeratorErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$AssignModeratorErrorCopyWithImpl<$Res>
    implements $AssignModeratorErrorCopyWith<$Res> {
  _$AssignModeratorErrorCopyWithImpl(this._self, this._then);

  final AssignModeratorError _self;
  final $Res Function(AssignModeratorError) _then;

/// Create a copy of AssignModeratorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(AssignModeratorError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of AssignModeratorState
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
