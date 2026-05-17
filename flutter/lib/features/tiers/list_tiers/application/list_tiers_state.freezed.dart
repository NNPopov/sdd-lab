// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_tiers_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListTiersState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListTiersState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ListTiersState()';
}


}

/// @nodoc
class $ListTiersStateCopyWith<$Res>  {
$ListTiersStateCopyWith(ListTiersState _, $Res Function(ListTiersState) __);
}


/// Adds pattern-matching-related methods to [ListTiersState].
extension ListTiersStatePatterns on ListTiersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ListTiersInitial value)?  initial,TResult Function( ListTiersLoading value)?  loading,TResult Function( ListTiersLoaded value)?  loaded,TResult Function( ListTiersError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ListTiersInitial() when initial != null:
return initial(_that);case ListTiersLoading() when loading != null:
return loading(_that);case ListTiersLoaded() when loaded != null:
return loaded(_that);case ListTiersError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ListTiersInitial value)  initial,required TResult Function( ListTiersLoading value)  loading,required TResult Function( ListTiersLoaded value)  loaded,required TResult Function( ListTiersError value)  error,}){
final _that = this;
switch (_that) {
case ListTiersInitial():
return initial(_that);case ListTiersLoading():
return loading(_that);case ListTiersLoaded():
return loaded(_that);case ListTiersError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ListTiersInitial value)?  initial,TResult? Function( ListTiersLoading value)?  loading,TResult? Function( ListTiersLoaded value)?  loaded,TResult? Function( ListTiersError value)?  error,}){
final _that = this;
switch (_that) {
case ListTiersInitial() when initial != null:
return initial(_that);case ListTiersLoading() when loading != null:
return loading(_that);case ListTiersLoaded() when loaded != null:
return loaded(_that);case ListTiersError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<Tier> tiers,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ListTiersInitial() when initial != null:
return initial();case ListTiersLoading() when loading != null:
return loading();case ListTiersLoaded() when loaded != null:
return loaded(_that.tiers,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case ListTiersError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<Tier> tiers,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case ListTiersInitial():
return initial();case ListTiersLoading():
return loading();case ListTiersLoaded():
return loaded(_that.tiers,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case ListTiersError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<Tier> tiers,  int page,  bool hasMore,  LoadMoreStatus loadMoreStatus,  Failure? loadMoreError)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case ListTiersInitial() when initial != null:
return initial();case ListTiersLoading() when loading != null:
return loading();case ListTiersLoaded() when loaded != null:
return loaded(_that.tiers,_that.page,_that.hasMore,_that.loadMoreStatus,_that.loadMoreError);case ListTiersError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ListTiersInitial implements ListTiersState {
  const ListTiersInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListTiersInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ListTiersState.initial()';
}


}




/// @nodoc


class ListTiersLoading implements ListTiersState {
  const ListTiersLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListTiersLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ListTiersState.loading()';
}


}




/// @nodoc


class ListTiersLoaded implements ListTiersState {
  const ListTiersLoaded({required final  List<Tier> tiers, required this.page, required this.hasMore, this.loadMoreStatus = LoadMoreStatus.idle, this.loadMoreError}): _tiers = tiers;
  

 final  List<Tier> _tiers;
 List<Tier> get tiers {
  if (_tiers is EqualUnmodifiableListView) return _tiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tiers);
}

 final  int page;
 final  bool hasMore;
@JsonKey() final  LoadMoreStatus loadMoreStatus;
 final  Failure? loadMoreError;

/// Create a copy of ListTiersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListTiersLoadedCopyWith<ListTiersLoaded> get copyWith => _$ListTiersLoadedCopyWithImpl<ListTiersLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListTiersLoaded&&const DeepCollectionEquality().equals(other._tiers, _tiers)&&(identical(other.page, page) || other.page == page)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.loadMoreStatus, loadMoreStatus) || other.loadMoreStatus == loadMoreStatus)&&(identical(other.loadMoreError, loadMoreError) || other.loadMoreError == loadMoreError));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tiers),page,hasMore,loadMoreStatus,loadMoreError);

@override
String toString() {
  return 'ListTiersState.loaded(tiers: $tiers, page: $page, hasMore: $hasMore, loadMoreStatus: $loadMoreStatus, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class $ListTiersLoadedCopyWith<$Res> implements $ListTiersStateCopyWith<$Res> {
  factory $ListTiersLoadedCopyWith(ListTiersLoaded value, $Res Function(ListTiersLoaded) _then) = _$ListTiersLoadedCopyWithImpl;
@useResult
$Res call({
 List<Tier> tiers, int page, bool hasMore, LoadMoreStatus loadMoreStatus, Failure? loadMoreError
});


$FailureCopyWith<$Res>? get loadMoreError;

}
/// @nodoc
class _$ListTiersLoadedCopyWithImpl<$Res>
    implements $ListTiersLoadedCopyWith<$Res> {
  _$ListTiersLoadedCopyWithImpl(this._self, this._then);

  final ListTiersLoaded _self;
  final $Res Function(ListTiersLoaded) _then;

/// Create a copy of ListTiersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tiers = null,Object? page = null,Object? hasMore = null,Object? loadMoreStatus = null,Object? loadMoreError = freezed,}) {
  return _then(ListTiersLoaded(
tiers: null == tiers ? _self._tiers : tiers // ignore: cast_nullable_to_non_nullable
as List<Tier>,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreStatus: null == loadMoreStatus ? _self.loadMoreStatus : loadMoreStatus // ignore: cast_nullable_to_non_nullable
as LoadMoreStatus,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of ListTiersState
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


class ListTiersError implements ListTiersState {
  const ListTiersError(this.failure);
  

 final  Failure failure;

/// Create a copy of ListTiersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListTiersErrorCopyWith<ListTiersError> get copyWith => _$ListTiersErrorCopyWithImpl<ListTiersError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListTiersError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ListTiersState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ListTiersErrorCopyWith<$Res> implements $ListTiersStateCopyWith<$Res> {
  factory $ListTiersErrorCopyWith(ListTiersError value, $Res Function(ListTiersError) _then) = _$ListTiersErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ListTiersErrorCopyWithImpl<$Res>
    implements $ListTiersErrorCopyWith<$Res> {
  _$ListTiersErrorCopyWithImpl(this._self, this._then);

  final ListTiersError _self;
  final $Res Function(ListTiersError) _then;

/// Create a copy of ListTiersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ListTiersError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ListTiersState
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
