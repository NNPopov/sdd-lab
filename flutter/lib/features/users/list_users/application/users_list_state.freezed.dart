// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'users_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UsersListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsersListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UsersListState()';
}


}

/// @nodoc
class $UsersListStateCopyWith<$Res>  {
$UsersListStateCopyWith(UsersListState _, $Res Function(UsersListState) __);
}


/// Adds pattern-matching-related methods to [UsersListState].
extension UsersListStatePatterns on UsersListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UsersListInitial value)?  initial,TResult Function( UsersListLoading value)?  loading,TResult Function( UsersListLoaded value)?  loaded,TResult Function( UsersListError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UsersListInitial() when initial != null:
return initial(_that);case UsersListLoading() when loading != null:
return loading(_that);case UsersListLoaded() when loaded != null:
return loaded(_that);case UsersListError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UsersListInitial value)  initial,required TResult Function( UsersListLoading value)  loading,required TResult Function( UsersListLoaded value)  loaded,required TResult Function( UsersListError value)  error,}){
final _that = this;
switch (_that) {
case UsersListInitial():
return initial(_that);case UsersListLoading():
return loading(_that);case UsersListLoaded():
return loaded(_that);case UsersListError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UsersListInitial value)?  initial,TResult? Function( UsersListLoading value)?  loading,TResult? Function( UsersListLoaded value)?  loaded,TResult? Function( UsersListError value)?  error,}){
final _that = this;
switch (_that) {
case UsersListInitial() when initial != null:
return initial(_that);case UsersListLoading() when loading != null:
return loading(_that);case UsersListLoaded() when loaded != null:
return loaded(_that);case UsersListError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<User> users,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UsersListInitial() when initial != null:
return initial();case UsersListLoading() when loading != null:
return loading();case UsersListLoaded() when loaded != null:
return loaded(_that.users,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case UsersListError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<User> users,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case UsersListInitial():
return initial();case UsersListLoading():
return loading();case UsersListLoaded():
return loaded(_that.users,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case UsersListError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<User> users,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case UsersListInitial() when initial != null:
return initial();case UsersListLoading() when loading != null:
return loading();case UsersListLoaded() when loaded != null:
return loaded(_that.users,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case UsersListError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class UsersListInitial implements UsersListState {
  const UsersListInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsersListInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UsersListState.initial()';
}


}




/// @nodoc


class UsersListLoading implements UsersListState {
  const UsersListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsersListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UsersListState.loading()';
}


}




/// @nodoc


class UsersListLoaded implements UsersListState {
  const UsersListLoaded({required final  List<User> users, required this.page, required this.hasMore, this.loadMoreStatus = LoadMoreStatus.idle, this.loadMoreError}): _users = users;
  

 final  List<User> _users;
 List<User> get users {
  if (_users is EqualUnmodifiableListView) return _users;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_users);
}

 final  int page;
 final  bool hasMore;
@JsonKey() final  LoadMoreStatus loadMoreStatus;
 final  Failure? loadMoreError;

/// Create a copy of UsersListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsersListLoadedCopyWith<UsersListLoaded> get copyWith => _$UsersListLoadedCopyWithImpl<UsersListLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsersListLoaded&&const DeepCollectionEquality().equals(other._users, _users)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadMoreStatus, loadMoreStatus) || other.loadMoreStatus == loadMoreStatus)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_users),page,hasMore,loadMoreStatus,loadMoreError);

@override
String toString() {
  return 'UsersListState.loaded(users: $users, page: $page, hasMore: $hasMore, loadMoreStatus: $loadMoreStatus, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class $UsersListLoadedCopyWith<$Res> implements $UsersListStateCopyWith<$Res> {
  factory $UsersListLoadedCopyWith(UsersListLoaded value, $Res Function(UsersListLoaded) _then) = _$UsersListLoadedCopyWithImpl;
@useResult
$Res call({
 List<User> users, int page, bool hasMore, LoadMoreStatus loadMoreStatus, Failure? loadMoreError
});


$FailureCopyWith<$Res>? get loadMoreError;

}
/// @nodoc
class _$UsersListLoadedCopyWithImpl<$Res>
    implements $UsersListLoadedCopyWith<$Res> {
  _$UsersListLoadedCopyWithImpl(this._self, this._then);

  final UsersListLoaded _self;
  final $Res Function(UsersListLoaded) _then;

/// Create a copy of UsersListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? users = null,Object? page = null,Object? hasMore = null,Object? loadMoreStatus = null,Object? loadMoreError = freezed,}) {
  return _then(UsersListLoaded(
users: null == users ? _self._users : users // ignore: cast_nullable_to_non_nullable
as List<User>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreStatus: null == loadMoreStatus ? _self.loadMoreStatus : loadMoreStatus // ignore: cast_nullable_to_non_nullable
as LoadMoreStatus,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of UsersListState
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


class UsersListError implements UsersListState {
  const UsersListError(this.failure);
  

 final  Failure failure;

/// Create a copy of UsersListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsersListErrorCopyWith<UsersListError> get copyWith => _$UsersListErrorCopyWithImpl<UsersListError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UsersListError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'UsersListState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $UsersListErrorCopyWith<$Res> implements $UsersListStateCopyWith<$Res> {
  factory $UsersListErrorCopyWith(UsersListError value, $Res Function(UsersListError) _then) = _$UsersListErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$UsersListErrorCopyWithImpl<$Res>
    implements $UsersListErrorCopyWith<$Res> {
  _$UsersListErrorCopyWithImpl(this._self, this._then);

  final UsersListError _self;
  final $Res Function(UsersListError) _then;

/// Create a copy of UsersListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(UsersListError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of UsersListState
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
