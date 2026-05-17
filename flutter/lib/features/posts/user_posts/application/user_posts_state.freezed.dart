// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_posts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserPostsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPostsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPostsState()';
}


}

/// @nodoc
class $UserPostsStateCopyWith<$Res>  {
$UserPostsStateCopyWith(UserPostsState _, $Res Function(UserPostsState) __);
}


/// Adds pattern-matching-related methods to [UserPostsState].
extension UserPostsStatePatterns on UserPostsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UserPostsInitial value)?  initial,TResult Function( UserPostsLoading value)?  loading,TResult Function( UserPostsLoaded value)?  loaded,TResult Function( UserPostsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UserPostsInitial() when initial != null:
return initial(_that);case UserPostsLoading() when loading != null:
return loading(_that);case UserPostsLoaded() when loaded != null:
return loaded(_that);case UserPostsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UserPostsInitial value)  initial,required TResult Function( UserPostsLoading value)  loading,required TResult Function( UserPostsLoaded value)  loaded,required TResult Function( UserPostsError value)  error,}){
final _that = this;
switch (_that) {
case UserPostsInitial():
return initial(_that);case UserPostsLoading():
return loading(_that);case UserPostsLoaded():
return loaded(_that);case UserPostsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UserPostsInitial value)?  initial,TResult? Function( UserPostsLoading value)?  loading,TResult? Function( UserPostsLoaded value)?  loaded,TResult? Function( UserPostsError value)?  error,}){
final _that = this;
switch (_that) {
case UserPostsInitial() when initial != null:
return initial(_that);case UserPostsLoading() when loading != null:
return loading(_that);case UserPostsLoaded() when loaded != null:
return loaded(_that);case UserPostsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Post> posts,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UserPostsInitial() when initial != null:
return initial();case UserPostsLoading() when loading != null:
return loading();case UserPostsLoaded() when loaded != null:
return loaded(_that.posts,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case UserPostsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Post> posts,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case UserPostsInitial():
return initial();case UserPostsLoading():
return loading();case UserPostsLoaded():
return loaded(_that.posts,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case UserPostsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Post> posts,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case UserPostsInitial() when initial != null:
return initial();case UserPostsLoading() when loading != null:
return loading();case UserPostsLoaded() when loaded != null:
return loaded(_that.posts,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case UserPostsError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class UserPostsInitial implements UserPostsState {
  const UserPostsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPostsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPostsState.initial()';
}


}




/// @nodoc


class UserPostsLoading implements UserPostsState {
  const UserPostsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPostsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UserPostsState.loading()';
}


}




/// @nodoc


class UserPostsLoaded implements UserPostsState {
  const UserPostsLoaded({required final  List<Post> posts, required this.page, required this.hasMore, this.loadMoreStatus = LoadMoreStatus.idle, this.loadMoreError}): _posts = posts;
  

 final  List<Post> _posts;
 List<Post> get posts {
  if (_posts is EqualUnmodifiableListView) return _posts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_posts);
}

 final  int page;
 final  bool hasMore;
@JsonKey() final  LoadMoreStatus loadMoreStatus;
 final  Failure? loadMoreError;

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPostsLoadedCopyWith<UserPostsLoaded> get copyWith => _$UserPostsLoadedCopyWithImpl<UserPostsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPostsLoaded&&const DeepCollectionEquality().equals(other._posts, _posts)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadMoreStatus, loadMoreStatus) || other.loadMoreStatus == loadMoreStatus)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_posts),page,hasMore,loadMoreStatus,loadMoreError);

@override
String toString() {
  return 'UserPostsState.loaded(posts: $posts, page: $page, hasMore: $hasMore, loadMoreStatus: $loadMoreStatus, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class $UserPostsLoadedCopyWith<$Res> implements $UserPostsStateCopyWith<$Res> {
  factory $UserPostsLoadedCopyWith(UserPostsLoaded value, $Res Function(UserPostsLoaded) _then) = _$UserPostsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Post> posts, int page, bool hasMore, LoadMoreStatus loadMoreStatus, Failure? loadMoreError
});


$FailureCopyWith<$Res>? get loadMoreError;

}
/// @nodoc
class _$UserPostsLoadedCopyWithImpl<$Res>
    implements $UserPostsLoadedCopyWith<$Res> {
  _$UserPostsLoadedCopyWithImpl(this._self, this._then);

  final UserPostsLoaded _self;
  final $Res Function(UserPostsLoaded) _then;

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? posts = null,Object? page = null,Object? hasMore = null,Object? loadMoreStatus = null,Object? loadMoreError = freezed,}) {
  return _then(UserPostsLoaded(
posts: null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<Post>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreStatus: null == loadMoreStatus ? _self.loadMoreStatus : loadMoreStatus // ignore: cast_nullable_to_non_nullable
as LoadMoreStatus,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get loadMoreError {
    if (_self.loadMoreError == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.loadMoreError!, (value) {
    return _then(_self.copyWith(loadMoreError: value));
  });
}
}

/// @nodoc


class UserPostsError implements UserPostsState {
  const UserPostsError(this.failure);
  

 final  Failure failure;

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPostsErrorCopyWith<UserPostsError> get copyWith => _$UserPostsErrorCopyWithImpl<UserPostsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPostsError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'UserPostsState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $UserPostsErrorCopyWith<$Res> implements $UserPostsStateCopyWith<$Res> {
  factory $UserPostsErrorCopyWith(UserPostsError value, $Res Function(UserPostsError) _then) = _$UserPostsErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$UserPostsErrorCopyWithImpl<$Res>
    implements $UserPostsErrorCopyWith<$Res> {
  _$UserPostsErrorCopyWithImpl(this._self, this._then);

  final UserPostsError _self;
  final $Res Function(UserPostsError) _then;

/// Create a copy of UserPostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(UserPostsError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of UserPostsState
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
