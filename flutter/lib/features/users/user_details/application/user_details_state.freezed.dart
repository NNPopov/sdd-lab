// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_details_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserDetailsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailsState()';
}


}

/// @nodoc
class $UserDetailsStateCopyWith<$Res>  {
$UserDetailsStateCopyWith(UserDetailsState _, $Res Function(UserDetailsState) __);
}


/// Adds pattern-matching-related methods to [UserDetailsState].
extension UserDetailsStatePatterns on UserDetailsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserDetailsInitial value)?  initial,TResult Function( UserDetailsLoading value)?  loading,TResult Function( UserDetailsLoaded value)?  loaded,TResult Function( UserDetailsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserDetailsInitial() when initial != null:
return initial(_that);case UserDetailsLoading() when loading != null:
return loading(_that);case UserDetailsLoaded() when loaded != null:
return loaded(_that);case UserDetailsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserDetailsInitial value)  initial,required TResult Function( UserDetailsLoading value)  loading,required TResult Function( UserDetailsLoaded value)  loaded,required TResult Function( UserDetailsError value)  error,}){
final _that = this;
switch (_that) {
case UserDetailsInitial():
return initial(_that);case UserDetailsLoading():
return loading(_that);case UserDetailsLoaded():
return loaded(_that);case UserDetailsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserDetailsInitial value)?  initial,TResult? Function( UserDetailsLoading value)?  loading,TResult? Function( UserDetailsLoaded value)?  loaded,TResult? Function( UserDetailsError value)?  error,}){
final _that = this;
switch (_that) {
case UserDetailsInitial() when initial != null:
return initial(_that);case UserDetailsLoading() when loading != null:
return loading(_that);case UserDetailsLoaded() when loaded != null:
return loaded(_that);case UserDetailsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( User user)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserDetailsInitial() when initial != null:
return initial();case UserDetailsLoading() when loading != null:
return loading();case UserDetailsLoaded() when loaded != null:
return loaded(_that.user);case UserDetailsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( User user)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case UserDetailsInitial():
return initial();case UserDetailsLoading():
return loading();case UserDetailsLoaded():
return loaded(_that.user);case UserDetailsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( User user)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case UserDetailsInitial() when initial != null:
return initial();case UserDetailsLoading() when loading != null:
return loading();case UserDetailsLoaded() when loaded != null:
return loaded(_that.user);case UserDetailsError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class UserDetailsInitial implements UserDetailsState {
  const UserDetailsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailsState.initial()';
}


}




/// @nodoc


class UserDetailsLoading implements UserDetailsState {
  const UserDetailsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserDetailsState.loading()';
}


}




/// @nodoc


class UserDetailsLoaded implements UserDetailsState {
  const UserDetailsLoaded(this.user);
  

 final  User user;

/// Create a copy of UserDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailsLoadedCopyWith<UserDetailsLoaded> get copyWith => _$UserDetailsLoadedCopyWithImpl<UserDetailsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailsLoaded&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'UserDetailsState.loaded(user: $user)';
}


}

/// @nodoc
abstract mixin class $UserDetailsLoadedCopyWith<$Res> implements $UserDetailsStateCopyWith<$Res> {
  factory $UserDetailsLoadedCopyWith(UserDetailsLoaded value, $Res Function(UserDetailsLoaded) _then) = _$UserDetailsLoadedCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$UserDetailsLoadedCopyWithImpl<$Res>
    implements $UserDetailsLoadedCopyWith<$Res> {
  _$UserDetailsLoadedCopyWithImpl(this._self, this._then);

  final UserDetailsLoaded _self;
  final $Res Function(UserDetailsLoaded) _then;

/// Create a copy of UserDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(UserDetailsLoaded(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of UserDetailsState
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


class UserDetailsError implements UserDetailsState {
  const UserDetailsError(this.failure);
  

 final  Failure failure;

/// Create a copy of UserDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserDetailsErrorCopyWith<UserDetailsError> get copyWith => _$UserDetailsErrorCopyWithImpl<UserDetailsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserDetailsError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'UserDetailsState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $UserDetailsErrorCopyWith<$Res> implements $UserDetailsStateCopyWith<$Res> {
  factory $UserDetailsErrorCopyWith(UserDetailsError value, $Res Function(UserDetailsError) _then) = _$UserDetailsErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$UserDetailsErrorCopyWithImpl<$Res>
    implements $UserDetailsErrorCopyWith<$Res> {
  _$UserDetailsErrorCopyWithImpl(this._self, this._then);

  final UserDetailsError _self;
  final $Res Function(UserDetailsError) _then;

/// Create a copy of UserDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(UserDetailsError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of UserDetailsState
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
