// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_posts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingPostsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPostsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PendingPostsState()';
}


}

/// @nodoc
class $PendingPostsStateCopyWith<$Res>  {
$PendingPostsStateCopyWith(PendingPostsState _, $Res Function(PendingPostsState) __);
}


/// Adds pattern-matching-related methods to [PendingPostsState].
extension PendingPostsStatePatterns on PendingPostsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PendingPostsInitial value)?  initial,TResult Function( PendingPostsLoading value)?  loading,TResult Function( PendingPostsLoaded value)?  loaded,TResult Function( PendingPostsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PendingPostsInitial() when initial != null:
return initial(_that);case PendingPostsLoading() when loading != null:
return loading(_that);case PendingPostsLoaded() when loaded != null:
return loaded(_that);case PendingPostsError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PendingPostsInitial value)  initial,required TResult Function( PendingPostsLoading value)  loading,required TResult Function( PendingPostsLoaded value)  loaded,required TResult Function( PendingPostsError value)  error,}){
final _that = this;
switch (_that) {
case PendingPostsInitial():
return initial(_that);case PendingPostsLoading():
return loading(_that);case PendingPostsLoaded():
return loaded(_that);case PendingPostsError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PendingPostsInitial value)?  initial,TResult? Function( PendingPostsLoading value)?  loading,TResult? Function( PendingPostsLoaded value)?  loaded,TResult? Function( PendingPostsError value)?  error,}){
final _that = this;
switch (_that) {
case PendingPostsInitial() when initial != null:
return initial(_that);case PendingPostsLoading() when loading != null:
return loading(_that);case PendingPostsLoaded() when loaded != null:
return loaded(_that);case PendingPostsError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<PendingPostItem> items,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PendingPostsInitial() when initial != null:
return initial();case PendingPostsLoading() when loading != null:
return loading();case PendingPostsLoaded() when loaded != null:
return loaded(_that.items,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case PendingPostsError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<PendingPostItem> items,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case PendingPostsInitial():
return initial();case PendingPostsLoading():
return loading();case PendingPostsLoaded():
return loaded(_that.items,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case PendingPostsError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<PendingPostItem> items,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case PendingPostsInitial() when initial != null:
return initial();case PendingPostsLoading() when loading != null:
return loading();case PendingPostsLoaded() when loaded != null:
return loaded(_that.items,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case PendingPostsError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PendingPostsInitial implements PendingPostsState {
  const PendingPostsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPostsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PendingPostsState.initial()';
}


}




/// @nodoc


class PendingPostsLoading implements PendingPostsState {
  const PendingPostsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPostsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PendingPostsState.loading()';
}


}




/// @nodoc


class PendingPostsLoaded implements PendingPostsState {
  const PendingPostsLoaded({required final  List<PendingPostItem> items, required this.page, required this.hasMore, this.loadMoreStatus = LoadMoreStatus.idle, this.loadMoreError}): _items = items;
  

 final  List<PendingPostItem> _items;
 List<PendingPostItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  int page;
 final  bool hasMore;
@JsonKey() final  LoadMoreStatus loadMoreStatus;
 final  Failure? loadMoreError;

/// Create a copy of PendingPostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingPostsLoadedCopyWith<PendingPostsLoaded> get copyWith => _$PendingPostsLoadedCopyWithImpl<PendingPostsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPostsLoaded&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadMoreStatus, loadMoreStatus) || other.loadMoreStatus == loadMoreStatus)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),page,hasMore,loadMoreStatus,loadMoreError);

@override
String toString() {
  return 'PendingPostsState.loaded(items: $items, page: $page, hasMore: $hasMore, loadMoreStatus: $loadMoreStatus, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class $PendingPostsLoadedCopyWith<$Res> implements $PendingPostsStateCopyWith<$Res> {
  factory $PendingPostsLoadedCopyWith(PendingPostsLoaded value, $Res Function(PendingPostsLoaded) _then) = _$PendingPostsLoadedCopyWithImpl;
@useResult
$Res call({
 List<PendingPostItem> items, int page, bool hasMore, LoadMoreStatus loadMoreStatus, Failure? loadMoreError
});


$FailureCopyWith<$Res>? get loadMoreError;

}
/// @nodoc
class _$PendingPostsLoadedCopyWithImpl<$Res>
    implements $PendingPostsLoadedCopyWith<$Res> {
  _$PendingPostsLoadedCopyWithImpl(this._self, this._then);

  final PendingPostsLoaded _self;
  final $Res Function(PendingPostsLoaded) _then;

/// Create a copy of PendingPostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? page = null,Object? hasMore = null,Object? loadMoreStatus = null,Object? loadMoreError = freezed,}) {
  return _then(PendingPostsLoaded(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PendingPostItem>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreStatus: null == loadMoreStatus ? _self.loadMoreStatus : loadMoreStatus // ignore: cast_nullable_to_non_nullable
as LoadMoreStatus,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of PendingPostsState
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


class PendingPostsError implements PendingPostsState {
  const PendingPostsError(this.failure);
  

 final  Failure failure;

/// Create a copy of PendingPostsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingPostsErrorCopyWith<PendingPostsError> get copyWith => _$PendingPostsErrorCopyWithImpl<PendingPostsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPostsError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PendingPostsState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PendingPostsErrorCopyWith<$Res> implements $PendingPostsStateCopyWith<$Res> {
  factory $PendingPostsErrorCopyWith(PendingPostsError value, $Res Function(PendingPostsError) _then) = _$PendingPostsErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PendingPostsErrorCopyWithImpl<$Res>
    implements $PendingPostsErrorCopyWith<$Res> {
  _$PendingPostsErrorCopyWithImpl(this._self, this._then);

  final PendingPostsError _self;
  final $Res Function(PendingPostsError) _then;

/// Create a copy of PendingPostsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PendingPostsError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PendingPostsState
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
