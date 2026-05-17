// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_posts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListPostsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListPostsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ListPostsState()';
}


}

/// @nodoc
class $ListPostsStateCopyWith<$Res>  {
$ListPostsStateCopyWith(ListPostsState _, $Res Function(ListPostsState) __);
}


/// Adds pattern-matching-related methods to [ListPostsState].
extension ListPostsStatePatterns on ListPostsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ListPostsInitial value)?  initial,TResult Function( ListPostsLoading value)?  loading,TResult Function( ListPostsLoaded value)?  loaded,TResult Function( ListPostsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ListPostsInitial() when initial != null:
return initial(_that);case ListPostsLoading() when loading != null:
return loading(_that);case ListPostsLoaded() when loaded != null:
return loaded(_that);case ListPostsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ListPostsInitial value)  initial,required TResult Function( ListPostsLoading value)  loading,required TResult Function( ListPostsLoaded value)  loaded,required TResult Function( ListPostsError value)  error,}){
final _that = this;
switch (_that) {
case ListPostsInitial():
return initial(_that);case ListPostsLoading():
return loading(_that);case ListPostsLoaded():
return loaded(_that);case ListPostsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ListPostsInitial value)?  initial,TResult? Function( ListPostsLoading value)?  loading,TResult? Function( ListPostsLoaded value)?  loaded,TResult? Function( ListPostsError value)?  error,}){
final _that = this;
switch (_that) {
case ListPostsInitial() when initial != null:
return initial(_that);case ListPostsLoading() when loading != null:
return loading(_that);case ListPostsLoaded() when loaded != null:
return loaded(_that);case ListPostsError() when error != null:
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
case ListPostsInitial() when initial != null:
return initial();case ListPostsLoading() when loading != null:
return loading();case ListPostsLoaded() when loaded != null:
return loaded(_that.posts,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case ListPostsError() when error != null:
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
case ListPostsInitial():
return initial();case ListPostsLoading():
return loading();case ListPostsLoaded():
return loaded(_that.posts,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case ListPostsError():
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
case ListPostsInitial() when initial != null:
return initial();case ListPostsLoading() when loading != null:
return loading();case ListPostsLoaded() when loaded != null:
return loaded(_that.posts,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case ListPostsError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ListPostsInitial implements ListPostsState {
  const ListPostsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListPostsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ListPostsState.initial()';
}


}




/// @nodoc


class ListPostsLoading implements ListPostsState {
  const ListPostsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListPostsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ListPostsState.loading()';
}


}




/// @nodoc


class ListPostsLoaded implements ListPostsState {
  const ListPostsLoaded({required final  List<Post> posts, required this.page, required this.hasMore, this.loadMoreStatus = LoadMoreStatus.idle, this.loadMoreError}): _posts = posts;
  

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

/// Create a copy of ListPostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListPostsLoadedCopyWith<ListPostsLoaded> get copyWith => _$ListPostsLoadedCopyWithImpl<ListPostsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListPostsLoaded&&const DeepCollectionEquality().equals(other._posts, _posts)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadMoreStatus, loadMoreStatus) || other.loadMoreStatus == loadMoreStatus)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_posts),page,hasMore,loadMoreStatus,loadMoreError);

@override
String toString() {
  return 'ListPostsState.loaded(posts: $posts, page: $page, hasMore: $hasMore, loadMoreStatus: $loadMoreStatus, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class $ListPostsLoadedCopyWith<$Res> implements $ListPostsStateCopyWith<$Res> {
  factory $ListPostsLoadedCopyWith(ListPostsLoaded value, $Res Function(ListPostsLoaded) _then) = _$ListPostsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Post> posts, int page, bool hasMore, LoadMoreStatus loadMoreStatus, Failure? loadMoreError
});


$FailureCopyWith<$Res>? get loadMoreError;

}
/// @nodoc
class _$ListPostsLoadedCopyWithImpl<$Res>
    implements $ListPostsLoadedCopyWith<$Res> {
  _$ListPostsLoadedCopyWithImpl(this._self, this._then);

  final ListPostsLoaded _self;
  final $Res Function(ListPostsLoaded) _then;

/// Create a copy of ListPostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? posts = null,Object? page = null,Object? hasMore = null,Object? loadMoreStatus = null,Object? loadMoreError = freezed,}) {
  return _then(ListPostsLoaded(
posts: null == posts ? _self._posts : posts // ignore: cast_nullable_to_non_nullable
as List<Post>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreStatus: null == loadMoreStatus ? _self.loadMoreStatus : loadMoreStatus // ignore: cast_nullable_to_non_nullable
as LoadMoreStatus,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of ListPostsState
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


class ListPostsError implements ListPostsState {
  const ListPostsError(this.failure);
  

 final  Failure failure;

/// Create a copy of ListPostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListPostsErrorCopyWith<ListPostsError> get copyWith => _$ListPostsErrorCopyWithImpl<ListPostsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListPostsError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ListPostsState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ListPostsErrorCopyWith<$Res> implements $ListPostsStateCopyWith<$Res> {
  factory $ListPostsErrorCopyWith(ListPostsError value, $Res Function(ListPostsError) _then) = _$ListPostsErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ListPostsErrorCopyWithImpl<$Res>
    implements $ListPostsErrorCopyWith<$Res> {
  _$ListPostsErrorCopyWithImpl(this._self, this._then);

  final ListPostsError _self;
  final $Res Function(ListPostsError) _then;

/// Create a copy of ListPostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ListPostsError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ListPostsState
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
