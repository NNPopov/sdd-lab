// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_user_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditUserState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditUserState()';
}


}

/// @nodoc
class $EditUserStateCopyWith<$Res>  {
$EditUserStateCopyWith(EditUserState _, $Res Function(EditUserState) __);
}


/// Adds pattern-matching-related methods to [EditUserState].
extension EditUserStatePatterns on EditUserState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditUserInitial value)?  initial,TResult Function( EditUserLoadingInitialData value)?  loadingInitialData,TResult Function( EditUserLoaded value)?  loaded,TResult Function( EditUserSubmitting value)?  submitting,TResult Function( EditUserSuccess value)?  success,TResult Function( EditUserLoadError value)?  loadError,TResult Function( EditUserSubmitError value)?  submitError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditUserInitial() when initial != null:
return initial(_that);case EditUserLoadingInitialData() when loadingInitialData != null:
return loadingInitialData(_that);case EditUserLoaded() when loaded != null:
return loaded(_that);case EditUserSubmitting() when submitting != null:
return submitting(_that);case EditUserSuccess() when success != null:
return success(_that);case EditUserLoadError() when loadError != null:
return loadError(_that);case EditUserSubmitError() when submitError != null:
return submitError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditUserInitial value)  initial,required TResult Function( EditUserLoadingInitialData value)  loadingInitialData,required TResult Function( EditUserLoaded value)  loaded,required TResult Function( EditUserSubmitting value)  submitting,required TResult Function( EditUserSuccess value)  success,required TResult Function( EditUserLoadError value)  loadError,required TResult Function( EditUserSubmitError value)  submitError,}){
final _that = this;
switch (_that) {
case EditUserInitial():
return initial(_that);case EditUserLoadingInitialData():
return loadingInitialData(_that);case EditUserLoaded():
return loaded(_that);case EditUserSubmitting():
return submitting(_that);case EditUserSuccess():
return success(_that);case EditUserLoadError():
return loadError(_that);case EditUserSubmitError():
return submitError(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditUserInitial value)?  initial,TResult? Function( EditUserLoadingInitialData value)?  loadingInitialData,TResult? Function( EditUserLoaded value)?  loaded,TResult? Function( EditUserSubmitting value)?  submitting,TResult? Function( EditUserSuccess value)?  success,TResult? Function( EditUserLoadError value)?  loadError,TResult? Function( EditUserSubmitError value)?  submitError,}){
final _that = this;
switch (_that) {
case EditUserInitial() when initial != null:
return initial(_that);case EditUserLoadingInitialData() when loadingInitialData != null:
return loadingInitialData(_that);case EditUserLoaded() when loaded != null:
return loaded(_that);case EditUserSubmitting() when submitting != null:
return submitting(_that);case EditUserSuccess() when success != null:
return success(_that);case EditUserLoadError() when loadError != null:
return loadError(_that);case EditUserSubmitError() when submitError != null:
return submitError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loadingInitialData,TResult Function( User original)?  loaded,TResult Function( User original)?  submitting,TResult Function( User user)?  success,TResult Function( Failure failure)?  loadError,TResult Function( User original,  Failure failure)?  submitError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditUserInitial() when initial != null:
return initial();case EditUserLoadingInitialData() when loadingInitialData != null:
return loadingInitialData();case EditUserLoaded() when loaded != null:
return loaded(_that.original);case EditUserSubmitting() when submitting != null:
return submitting(_that.original);case EditUserSuccess() when success != null:
return success(_that.user);case EditUserLoadError() when loadError != null:
return loadError(_that.failure);case EditUserSubmitError() when submitError != null:
return submitError(_that.original,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loadingInitialData,required TResult Function( User original)  loaded,required TResult Function( User original)  submitting,required TResult Function( User user)  success,required TResult Function( Failure failure)  loadError,required TResult Function( User original,  Failure failure)  submitError,}) {final _that = this;
switch (_that) {
case EditUserInitial():
return initial();case EditUserLoadingInitialData():
return loadingInitialData();case EditUserLoaded():
return loaded(_that.original);case EditUserSubmitting():
return submitting(_that.original);case EditUserSuccess():
return success(_that.user);case EditUserLoadError():
return loadError(_that.failure);case EditUserSubmitError():
return submitError(_that.original,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loadingInitialData,TResult? Function( User original)?  loaded,TResult? Function( User original)?  submitting,TResult? Function( User user)?  success,TResult? Function( Failure failure)?  loadError,TResult? Function( User original,  Failure failure)?  submitError,}) {final _that = this;
switch (_that) {
case EditUserInitial() when initial != null:
return initial();case EditUserLoadingInitialData() when loadingInitialData != null:
return loadingInitialData();case EditUserLoaded() when loaded != null:
return loaded(_that.original);case EditUserSubmitting() when submitting != null:
return submitting(_that.original);case EditUserSuccess() when success != null:
return success(_that.user);case EditUserLoadError() when loadError != null:
return loadError(_that.failure);case EditUserSubmitError() when submitError != null:
return submitError(_that.original,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class EditUserInitial implements EditUserState {
  const EditUserInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditUserState.initial()';
}


}




/// @nodoc


class EditUserLoadingInitialData implements EditUserState {
  const EditUserLoadingInitialData();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserLoadingInitialData);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditUserState.loadingInitialData()';
}


}




/// @nodoc


class EditUserLoaded implements EditUserState {
  const EditUserLoaded(this.original);
  

 final  User original;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditUserLoadedCopyWith<EditUserLoaded> get copyWith => _$EditUserLoadedCopyWithImpl<EditUserLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserLoaded&&(identical(other.original, original) || other.original == original));
}


@override
int get hashCode => Object.hash(runtimeType,original);

@override
String toString() {
  return 'EditUserState.loaded(original: $original)';
}


}

/// @nodoc
abstract mixin class $EditUserLoadedCopyWith<$Res> implements $EditUserStateCopyWith<$Res> {
  factory $EditUserLoadedCopyWith(EditUserLoaded value, $Res Function(EditUserLoaded) _then) = _$EditUserLoadedCopyWithImpl;
@useResult
$Res call({
 User original
});


$UserCopyWith<$Res> get original;

}
/// @nodoc
class _$EditUserLoadedCopyWithImpl<$Res>
    implements $EditUserLoadedCopyWith<$Res> {
  _$EditUserLoadedCopyWithImpl(this._self, this._then);

  final EditUserLoaded _self;
  final $Res Function(EditUserLoaded) _then;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? original = null,}) {
  return _then(EditUserLoaded(
null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get original {
  
  return $UserCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}
}

/// @nodoc


class EditUserSubmitting implements EditUserState {
  const EditUserSubmitting(this.original);
  

 final  User original;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditUserSubmittingCopyWith<EditUserSubmitting> get copyWith => _$EditUserSubmittingCopyWithImpl<EditUserSubmitting>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserSubmitting&&(identical(other.original, original) || other.original == original));
}


@override
int get hashCode => Object.hash(runtimeType,original);

@override
String toString() {
  return 'EditUserState.submitting(original: $original)';
}


}

/// @nodoc
abstract mixin class $EditUserSubmittingCopyWith<$Res> implements $EditUserStateCopyWith<$Res> {
  factory $EditUserSubmittingCopyWith(EditUserSubmitting value, $Res Function(EditUserSubmitting) _then) = _$EditUserSubmittingCopyWithImpl;
@useResult
$Res call({
 User original
});


$UserCopyWith<$Res> get original;

}
/// @nodoc
class _$EditUserSubmittingCopyWithImpl<$Res>
    implements $EditUserSubmittingCopyWith<$Res> {
  _$EditUserSubmittingCopyWithImpl(this._self, this._then);

  final EditUserSubmitting _self;
  final $Res Function(EditUserSubmitting) _then;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? original = null,}) {
  return _then(EditUserSubmitting(
null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get original {
  
  return $UserCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}
}

/// @nodoc


class EditUserSuccess implements EditUserState {
  const EditUserSuccess(this.user);
  

 final  User user;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditUserSuccessCopyWith<EditUserSuccess> get copyWith => _$EditUserSuccessCopyWithImpl<EditUserSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserSuccess&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'EditUserState.success(user: $user)';
}


}

/// @nodoc
abstract mixin class $EditUserSuccessCopyWith<$Res> implements $EditUserStateCopyWith<$Res> {
  factory $EditUserSuccessCopyWith(EditUserSuccess value, $Res Function(EditUserSuccess) _then) = _$EditUserSuccessCopyWithImpl;
@useResult
$Res call({
 User user
});


$UserCopyWith<$Res> get user;

}
/// @nodoc
class _$EditUserSuccessCopyWithImpl<$Res>
    implements $EditUserSuccessCopyWith<$Res> {
  _$EditUserSuccessCopyWithImpl(this._self, this._then);

  final EditUserSuccess _self;
  final $Res Function(EditUserSuccess) _then;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(EditUserSuccess(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as User,
  ));
}

/// Create a copy of EditUserState
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


class EditUserLoadError implements EditUserState {
  const EditUserLoadError(this.failure);
  

 final  Failure failure;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditUserLoadErrorCopyWith<EditUserLoadError> get copyWith => _$EditUserLoadErrorCopyWithImpl<EditUserLoadError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserLoadError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EditUserState.loadError(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EditUserLoadErrorCopyWith<$Res> implements $EditUserStateCopyWith<$Res> {
  factory $EditUserLoadErrorCopyWith(EditUserLoadError value, $Res Function(EditUserLoadError) _then) = _$EditUserLoadErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EditUserLoadErrorCopyWithImpl<$Res>
    implements $EditUserLoadErrorCopyWith<$Res> {
  _$EditUserLoadErrorCopyWithImpl(this._self, this._then);

  final EditUserLoadError _self;
  final $Res Function(EditUserLoadError) _then;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EditUserLoadError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class EditUserSubmitError implements EditUserState {
  const EditUserSubmitError(this.original, this.failure);
  

 final  User original;
 final  Failure failure;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditUserSubmitErrorCopyWith<EditUserSubmitError> get copyWith => _$EditUserSubmitErrorCopyWithImpl<EditUserSubmitError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditUserSubmitError&&(identical(other.original, original) || other.original == original)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,original,failure);

@override
String toString() {
  return 'EditUserState.submitError(original: $original, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EditUserSubmitErrorCopyWith<$Res> implements $EditUserStateCopyWith<$Res> {
  factory $EditUserSubmitErrorCopyWith(EditUserSubmitError value, $Res Function(EditUserSubmitError) _then) = _$EditUserSubmitErrorCopyWithImpl;
@useResult
$Res call({
 User original, Failure failure
});


$UserCopyWith<$Res> get original;$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EditUserSubmitErrorCopyWithImpl<$Res>
    implements $EditUserSubmitErrorCopyWith<$Res> {
  _$EditUserSubmitErrorCopyWithImpl(this._self, this._then);

  final EditUserSubmitError _self;
  final $Res Function(EditUserSubmitError) _then;

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? original = null,Object? failure = null,}) {
  return _then(EditUserSubmitError(
null == original ? _self.original : original // ignore: cast_nullable_to_non_nullable
as User,null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EditUserState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UserCopyWith<$Res> get original {
  
  return $UserCopyWith<$Res>(_self.original, (value) {
    return _then(_self.copyWith(original: value));
  });
}/// Create a copy of EditUserState
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
