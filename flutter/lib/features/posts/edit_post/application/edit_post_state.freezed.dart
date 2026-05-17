// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_post_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EditPostState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditPostState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditPostState()';
}


}

/// @nodoc
class $EditPostStateCopyWith<$Res>  {
$EditPostStateCopyWith(EditPostState _, $Res Function(EditPostState) __);
}


/// Adds pattern-matching-related methods to [EditPostState].
extension EditPostStatePatterns on EditPostState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EditPostInitial value)?  initial,TResult Function( EditPostLoading value)?  loading,TResult Function( EditPostSuccess value)?  success,TResult Function( EditPostError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EditPostInitial() when initial != null:
return initial(_that);case EditPostLoading() when loading != null:
return loading(_that);case EditPostSuccess() when success != null:
return success(_that);case EditPostError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EditPostInitial value)  initial,required TResult Function( EditPostLoading value)  loading,required TResult Function( EditPostSuccess value)  success,required TResult Function( EditPostError value)  error,}){
final _that = this;
switch (_that) {
case EditPostInitial():
return initial(_that);case EditPostLoading():
return loading(_that);case EditPostSuccess():
return success(_that);case EditPostError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EditPostInitial value)?  initial,TResult? Function( EditPostLoading value)?  loading,TResult? Function( EditPostSuccess value)?  success,TResult? Function( EditPostError value)?  error,}){
final _that = this;
switch (_that) {
case EditPostInitial() when initial != null:
return initial(_that);case EditPostLoading() when loading != null:
return loading(_that);case EditPostSuccess() when success != null:
return success(_that);case EditPostError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function()?  success,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EditPostInitial() when initial != null:
return initial();case EditPostLoading() when loading != null:
return loading();case EditPostSuccess() when success != null:
return success();case EditPostError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function()  success,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case EditPostInitial():
return initial();case EditPostLoading():
return loading();case EditPostSuccess():
return success();case EditPostError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function()?  success,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case EditPostInitial() when initial != null:
return initial();case EditPostLoading() when loading != null:
return loading();case EditPostSuccess() when success != null:
return success();case EditPostError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class EditPostInitial implements EditPostState {
  const EditPostInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditPostInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditPostState.initial()';
}


}




/// @nodoc


class EditPostLoading implements EditPostState {
  const EditPostLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditPostLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditPostState.loading()';
}


}




/// @nodoc


class EditPostSuccess implements EditPostState {
  const EditPostSuccess();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditPostSuccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EditPostState.success()';
}


}




/// @nodoc


class EditPostError implements EditPostState {
  const EditPostError(this.failure);
  

 final  Failure failure;

/// Create a copy of EditPostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditPostErrorCopyWith<EditPostError> get copyWith => _$EditPostErrorCopyWithImpl<EditPostError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditPostError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EditPostState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EditPostErrorCopyWith<$Res> implements $EditPostStateCopyWith<$Res> {
  factory $EditPostErrorCopyWith(EditPostError value, $Res Function(EditPostError) _then) = _$EditPostErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EditPostErrorCopyWithImpl<$Res>
    implements $EditPostErrorCopyWith<$Res> {
  _$EditPostErrorCopyWithImpl(this._self, this._then);

  final EditPostError _self;
  final $Res Function(EditPostError) _then;

/// Create a copy of EditPostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EditPostError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EditPostState
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
