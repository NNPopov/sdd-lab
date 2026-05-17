// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_user_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreateUserState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateUserState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreateUserState()';
}


}

/// @nodoc
class $CreateUserStateCopyWith<$Res>  {
$CreateUserStateCopyWith(CreateUserState _, $Res Function(CreateUserState) __);
}


/// Adds pattern-matching-related methods to [CreateUserState].
extension CreateUserStatePatterns on CreateUserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreateUserInitial value)?  initial,TResult Function( CreateUserSubmitting value)?  submitting,TResult Function( CreateUserSuccess value)?  success,TResult Function( CreateUserFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreateUserInitial() when initial != null:
return initial(_that);case CreateUserSubmitting() when submitting != null:
return submitting(_that);case CreateUserSuccess() when success != null:
return success(_that);case CreateUserFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreateUserInitial value)  initial,required TResult Function( CreateUserSubmitting value)  submitting,required TResult Function( CreateUserSuccess value)  success,required TResult Function( CreateUserFailure value)  failure,}){
final _that = this;
switch (_that) {
case CreateUserInitial():
return initial(_that);case CreateUserSubmitting():
return submitting(_that);case CreateUserSuccess():
return success(_that);case CreateUserFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreateUserInitial value)?  initial,TResult? Function( CreateUserSubmitting value)?  submitting,TResult? Function( CreateUserSuccess value)?  success,TResult? Function( CreateUserFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CreateUserInitial() when initial != null:
return initial(_that);case CreateUserSubmitting() when submitting != null:
return submitting(_that);case CreateUserSuccess() when success != null:
return success(_that);case CreateUserFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( User user)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreateUserInitial() when initial != null:
return initial();case CreateUserSubmitting() when submitting != null:
return submitting();case CreateUserSuccess() when success != null:
return success(_that.user);case CreateUserFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( User user)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CreateUserInitial():
return initial();case CreateUserSubmitting():
return submitting();case CreateUserSuccess():
return success(_that.user);case CreateUserFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( User user)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CreateUserInitial() when initial != null:
return initial();case CreateUserSubmitting() when submitting != null:
return submitting();case CreateUserSuccess() when success != null:
return success(_that.user);case CreateUserFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CreateUserInitial implements CreateUserState {
  const CreateUserInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateUserInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreateUserState.initial()';
}


}




/// @nodoc


class CreateUserSubmitting implements CreateUserState {
  const CreateUserSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateUserSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreateUserState.submitting()';
}


}




/// @nodoc


class CreateUserSuccess implements CreateUserState {
  const CreateUserSuccess(this.user);
  

 final  User user;

/// Create a copy of CreateUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateUserSuccessCopyWith<CreateUserSuccess> get copyWith => _$CreateUserSuccessCopyWithImpl<CreateUserSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateUserSuccess&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'CreateUserState.success(user: $user)';
}


}

/// @nodoc
abstract mixin class $CreateUserSuccessCopyWith<$Res> implements $CreateUserStateCopyWith<$Res> {
  factory $CreateUserSuccessCopyWith(CreateUserSuccess value, $Res Function(CreateUserSuccess) _then) = _$CreateUserSuccessCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$CreateUserSuccessCopyWithImpl<$Res>
    implements $CreateUserSuccessCopyWith<$Res> {
  _$CreateUserSuccessCopyWithImpl(this._self, this._then);

  final CreateUserSuccess _self;
  final $Res Function(CreateUserSuccess) _then;

/// Create a copy of CreateUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(CreateUserSuccess(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of CreateUserState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get user {
  
  return $UserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class CreateUserFailure implements CreateUserState {
  const CreateUserFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CreateUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateUserFailureCopyWith<CreateUserFailure> get copyWith => _$CreateUserFailureCopyWithImpl<CreateUserFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateUserFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CreateUserState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CreateUserFailureCopyWith<$Res> implements $CreateUserStateCopyWith<$Res> {
  factory $CreateUserFailureCopyWith(CreateUserFailure value, $Res Function(CreateUserFailure) _then) = _$CreateUserFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CreateUserFailureCopyWithImpl<$Res>
    implements $CreateUserFailureCopyWith<$Res> {
  _$CreateUserFailureCopyWithImpl(this._self, this._then);

  final CreateUserFailure _self;
  final $Res Function(CreateUserFailure) _then;

/// Create a copy of CreateUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CreateUserFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CreateUserState
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
