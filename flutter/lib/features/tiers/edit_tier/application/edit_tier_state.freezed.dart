// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_tier_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditTierState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditTierState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditTierState()';
}


}

/// @nodoc
class $EditTierStateCopyWith<$Res>  {
$EditTierStateCopyWith(EditTierState _, $Res Function(EditTierState) __);
}


/// Adds pattern-matching-related methods to [EditTierState].
extension EditTierStatePatterns on EditTierState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditTierInitial value)?  initial,TResult Function( EditTierSubmitting value)?  submitting,TResult Function( EditTierSuccess value)?  success,TResult Function( EditTierFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditTierInitial() when initial != null:
return initial(_that);case EditTierSubmitting() when submitting != null:
return submitting(_that);case EditTierSuccess() when success != null:
return success(_that);case EditTierFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditTierInitial value)  initial,required TResult Function( EditTierSubmitting value)  submitting,required TResult Function( EditTierSuccess value)  success,required TResult Function( EditTierFailure value)  failure,}){
final _that = this;
switch (_that) {
case EditTierInitial():
return initial(_that);case EditTierSubmitting():
return submitting(_that);case EditTierSuccess():
return success(_that);case EditTierFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditTierInitial value)?  initial,TResult? Function( EditTierSubmitting value)?  submitting,TResult? Function( EditTierSuccess value)?  success,TResult? Function( EditTierFailure value)?  failure,}){
final _that = this;
switch (_that) {
case EditTierInitial() when initial != null:
return initial(_that);case EditTierSubmitting() when submitting != null:
return submitting(_that);case EditTierSuccess() when success != null:
return success(_that);case EditTierFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( String newName)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditTierInitial() when initial != null:
return initial();case EditTierSubmitting() when submitting != null:
return submitting();case EditTierSuccess() when success != null:
return success(_that.newName);case EditTierFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( String newName)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case EditTierInitial():
return initial();case EditTierSubmitting():
return submitting();case EditTierSuccess():
return success(_that.newName);case EditTierFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( String newName)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case EditTierInitial() when initial != null:
return initial();case EditTierSubmitting() when submitting != null:
return submitting();case EditTierSuccess() when success != null:
return success(_that.newName);case EditTierFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class EditTierInitial implements EditTierState {
  const EditTierInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditTierInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditTierState.initial()';
}


}




/// @nodoc


class EditTierSubmitting implements EditTierState {
  const EditTierSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditTierSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditTierState.submitting()';
}


}




/// @nodoc


class EditTierSuccess implements EditTierState {
  const EditTierSuccess({required this.newName});
  

 final  String newName;

/// Create a copy of EditTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditTierSuccessCopyWith<EditTierSuccess> get copyWith => _$EditTierSuccessCopyWithImpl<EditTierSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditTierSuccess&&(identical(other.newName, newName) || other.newName == newName));
}


@override
int get hashCode => Object.hash(runtimeType,newName);

@override
String toString() {
  return 'EditTierState.success(newName: $newName)';
}


}

/// @nodoc
abstract mixin class $EditTierSuccessCopyWith<$Res> implements $EditTierStateCopyWith<$Res> {
  factory $EditTierSuccessCopyWith(EditTierSuccess value, $Res Function(EditTierSuccess) _then) = _$EditTierSuccessCopyWithImpl;
@useResult
$Res call({
 String newName
});




}
/// @nodoc
class _$EditTierSuccessCopyWithImpl<$Res>
    implements $EditTierSuccessCopyWith<$Res> {
  _$EditTierSuccessCopyWithImpl(this._self, this._then);

  final EditTierSuccess _self;
  final $Res Function(EditTierSuccess) _then;

/// Create a copy of EditTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? newName = null,}) {
  return _then(EditTierSuccess(
newName: null == newName ? _self.newName : newName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class EditTierFailure implements EditTierState {
  const EditTierFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of EditTierState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditTierFailureCopyWith<EditTierFailure> get copyWith => _$EditTierFailureCopyWithImpl<EditTierFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditTierFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EditTierState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EditTierFailureCopyWith<$Res> implements $EditTierStateCopyWith<$Res> {
  factory $EditTierFailureCopyWith(EditTierFailure value, $Res Function(EditTierFailure) _then) = _$EditTierFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EditTierFailureCopyWithImpl<$Res>
    implements $EditTierFailureCopyWith<$Res> {
  _$EditTierFailureCopyWithImpl(this._self, this._then);

  final EditTierFailure _self;
  final $Res Function(EditTierFailure) _then;

/// Create a copy of EditTierState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EditTierFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EditTierState
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
