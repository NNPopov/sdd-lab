// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post_details_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PostDetailsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDetailsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PostDetailsState()';
}


}

/// @nodoc
class $PostDetailsStateCopyWith<$Res>  {
$PostDetailsStateCopyWith(PostDetailsState _, $Res Function(PostDetailsState) __);
}


/// Adds pattern-matching-related methods to [PostDetailsState].
extension PostDetailsStatePatterns on PostDetailsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PostDetailsInitial value)?  initial,TResult Function( PostDetailsLoading value)?  loading,TResult Function( PostDetailsLoaded value)?  loaded,TResult Function( PostDetailsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PostDetailsInitial() when initial != null:
return initial(_that);case PostDetailsLoading() when loading != null:
return loading(_that);case PostDetailsLoaded() when loaded != null:
return loaded(_that);case PostDetailsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PostDetailsInitial value)  initial,required TResult Function( PostDetailsLoading value)  loading,required TResult Function( PostDetailsLoaded value)  loaded,required TResult Function( PostDetailsError value)  error,}){
final _that = this;
switch (_that) {
case PostDetailsInitial():
return initial(_that);case PostDetailsLoading():
return loading(_that);case PostDetailsLoaded():
return loaded(_that);case PostDetailsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PostDetailsInitial value)?  initial,TResult? Function( PostDetailsLoading value)?  loading,TResult? Function( PostDetailsLoaded value)?  loaded,TResult? Function( PostDetailsError value)?  error,}){
final _that = this;
switch (_that) {
case PostDetailsInitial() when initial != null:
return initial(_that);case PostDetailsLoading() when loading != null:
return loading(_that);case PostDetailsLoaded() when loaded != null:
return loaded(_that);case PostDetailsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Post post)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PostDetailsInitial() when initial != null:
return initial();case PostDetailsLoading() when loading != null:
return loading();case PostDetailsLoaded() when loaded != null:
return loaded(_that.post);case PostDetailsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Post post)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case PostDetailsInitial():
return initial();case PostDetailsLoading():
return loading();case PostDetailsLoaded():
return loaded(_that.post);case PostDetailsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Post post)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case PostDetailsInitial() when initial != null:
return initial();case PostDetailsLoading() when loading != null:
return loading();case PostDetailsLoaded() when loaded != null:
return loaded(_that.post);case PostDetailsError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PostDetailsInitial implements PostDetailsState {
  const PostDetailsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDetailsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PostDetailsState.initial()';
}


}




/// @nodoc


class PostDetailsLoading implements PostDetailsState {
  const PostDetailsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDetailsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PostDetailsState.loading()';
}


}




/// @nodoc


class PostDetailsLoaded implements PostDetailsState {
  const PostDetailsLoaded({required this.post});
  

 final  Post post;

/// Create a copy of PostDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostDetailsLoadedCopyWith<PostDetailsLoaded> get copyWith => _$PostDetailsLoadedCopyWithImpl<PostDetailsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDetailsLoaded&&(identical(other.post, post) || other.post == post));
}


@override
int get hashCode => Object.hash(runtimeType,post);

@override
String toString() {
  return 'PostDetailsState.loaded(post: $post)';
}


}

/// @nodoc
abstract mixin class $PostDetailsLoadedCopyWith<$Res> implements $PostDetailsStateCopyWith<$Res> {
  factory $PostDetailsLoadedCopyWith(PostDetailsLoaded value, $Res Function(PostDetailsLoaded) _then) = _$PostDetailsLoadedCopyWithImpl;
@useResult
$Res call({
 Post post
});




}
/// @nodoc
class _$PostDetailsLoadedCopyWithImpl<$Res>
    implements $PostDetailsLoadedCopyWith<$Res> {
  _$PostDetailsLoadedCopyWithImpl(this._self, this._then);

  final PostDetailsLoaded _self;
  final $Res Function(PostDetailsLoaded) _then;

/// Create a copy of PostDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? post = null,}) {
  return _then(PostDetailsLoaded(
post: null == post ? _self.post : post // ignore: cast_nullable_to_non_nullable
as Post,
  ));
}


}

/// @nodoc


class PostDetailsError implements PostDetailsState {
  const PostDetailsError({required this.failure});
  

 final  Failure failure;

/// Create a copy of PostDetailsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PostDetailsErrorCopyWith<PostDetailsError> get copyWith => _$PostDetailsErrorCopyWithImpl<PostDetailsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PostDetailsError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PostDetailsState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PostDetailsErrorCopyWith<$Res> implements $PostDetailsStateCopyWith<$Res> {
  factory $PostDetailsErrorCopyWith(PostDetailsError value, $Res Function(PostDetailsError) _then) = _$PostDetailsErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PostDetailsErrorCopyWithImpl<$Res>
    implements $PostDetailsErrorCopyWith<$Res> {
  _$PostDetailsErrorCopyWithImpl(this._self, this._then);

  final PostDetailsError _self;
  final $Res Function(PostDetailsError) _then;

/// Create a copy of PostDetailsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PostDetailsError(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PostDetailsState
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
