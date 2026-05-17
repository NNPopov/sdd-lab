// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moderate_post_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModeratePostState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratePostState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModeratePostState()';
}


}

/// @nodoc
class $ModeratePostStateCopyWith<$Res>  {
$ModeratePostStateCopyWith(ModeratePostState _, $Res Function(ModeratePostState) __);
}


/// Adds pattern-matching-related methods to [ModeratePostState].
extension ModeratePostStatePatterns on ModeratePostState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ModeratePostInitial value)?  initial,TResult Function( ModeratePostLoading value)?  loading,TResult Function( ModeratePostSuccess value)?  success,TResult Function( ModeratePostError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ModeratePostInitial() when initial != null:
return initial(_that);case ModeratePostLoading() when loading != null:
return loading(_that);case ModeratePostSuccess() when success != null:
return success(_that);case ModeratePostError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ModeratePostInitial value)  initial,required TResult Function( ModeratePostLoading value)  loading,required TResult Function( ModeratePostSuccess value)  success,required TResult Function( ModeratePostError value)  error,}){
final _that = this;
switch (_that) {
case ModeratePostInitial():
return initial(_that);case ModeratePostLoading():
return loading(_that);case ModeratePostSuccess():
return success(_that);case ModeratePostError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ModeratePostInitial value)?  initial,TResult? Function( ModeratePostLoading value)?  loading,TResult? Function( ModeratePostSuccess value)?  success,TResult? Function( ModeratePostError value)?  error,}){
final _that = this;
switch (_that) {
case ModeratePostInitial() when initial != null:
return initial(_that);case ModeratePostLoading() when loading != null:
return loading(_that);case ModeratePostSuccess() when success != null:
return success(_that);case ModeratePostError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( PostStatus newStatus)?  success,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ModeratePostInitial() when initial != null:
return initial();case ModeratePostLoading() when loading != null:
return loading();case ModeratePostSuccess() when success != null:
return success(_that.newStatus);case ModeratePostError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( PostStatus newStatus)  success,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case ModeratePostInitial():
return initial();case ModeratePostLoading():
return loading();case ModeratePostSuccess():
return success(_that.newStatus);case ModeratePostError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( PostStatus newStatus)?  success,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case ModeratePostInitial() when initial != null:
return initial();case ModeratePostLoading() when loading != null:
return loading();case ModeratePostSuccess() when success != null:
return success(_that.newStatus);case ModeratePostError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ModeratePostInitial implements ModeratePostState {
  const ModeratePostInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratePostInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModeratePostState.initial()';
}


}




/// @nodoc


class ModeratePostLoading implements ModeratePostState {
  const ModeratePostLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratePostLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModeratePostState.loading()';
}


}




/// @nodoc


class ModeratePostSuccess implements ModeratePostState {
  const ModeratePostSuccess(this.newStatus);
  

 final  PostStatus newStatus;

/// Create a copy of ModeratePostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModeratePostSuccessCopyWith<ModeratePostSuccess> get copyWith => _$ModeratePostSuccessCopyWithImpl<ModeratePostSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratePostSuccess&&(identical(other.newStatus, newStatus) || other.newStatus == newStatus));
}


@override
int get hashCode => Object.hash(runtimeType,newStatus);

@override
String toString() {
  return 'ModeratePostState.success(newStatus: $newStatus)';
}


}

/// @nodoc
abstract mixin class $ModeratePostSuccessCopyWith<$Res> implements $ModeratePostStateCopyWith<$Res> {
  factory $ModeratePostSuccessCopyWith(ModeratePostSuccess value, $Res Function(ModeratePostSuccess) _then) = _$ModeratePostSuccessCopyWithImpl;
@useResult
$Res call({
 PostStatus newStatus
});




}
/// @nodoc
class _$ModeratePostSuccessCopyWithImpl<$Res>
    implements $ModeratePostSuccessCopyWith<$Res> {
  _$ModeratePostSuccessCopyWithImpl(this._self, this._then);

  final ModeratePostSuccess _self;
  final $Res Function(ModeratePostSuccess) _then;

/// Create a copy of ModeratePostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? newStatus = null,}) {
  return _then(ModeratePostSuccess(
null == newStatus ? _self.newStatus : newStatus // ignore: cast_nullable_to_non_nullable
as PostStatus,
  ));
}


}

/// @nodoc


class ModeratePostError implements ModeratePostState {
  const ModeratePostError(this.failure);
  

 final  Failure failure;

/// Create a copy of ModeratePostState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModeratePostErrorCopyWith<ModeratePostError> get copyWith => _$ModeratePostErrorCopyWithImpl<ModeratePostError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModeratePostError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ModeratePostState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ModeratePostErrorCopyWith<$Res> implements $ModeratePostStateCopyWith<$Res> {
  factory $ModeratePostErrorCopyWith(ModeratePostError value, $Res Function(ModeratePostError) _then) = _$ModeratePostErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ModeratePostErrorCopyWithImpl<$Res>
    implements $ModeratePostErrorCopyWith<$Res> {
  _$ModeratePostErrorCopyWithImpl(this._self, this._then);

  final ModeratePostError _self;
  final $Res Function(ModeratePostError) _then;

/// Create a copy of ModeratePostState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ModeratePostError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ModeratePostState
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
