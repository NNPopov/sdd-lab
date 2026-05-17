// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'moderation_log_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ModerationLogState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationLogState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModerationLogState()';
}


}

/// @nodoc
class $ModerationLogStateCopyWith<$Res>  {
$ModerationLogStateCopyWith(ModerationLogState _, $Res Function(ModerationLogState) __);
}


/// Adds pattern-matching-related methods to [ModerationLogState].
extension ModerationLogStatePatterns on ModerationLogState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ModerationLogInitial value)?  initial,TResult Function( ModerationLogLoading value)?  loading,TResult Function( ModerationLogLoaded value)?  loaded,TResult Function( ModerationLogError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ModerationLogInitial() when initial != null:
return initial(_that);case ModerationLogLoading() when loading != null:
return loading(_that);case ModerationLogLoaded() when loaded != null:
return loaded(_that);case ModerationLogError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ModerationLogInitial value)  initial,required TResult Function( ModerationLogLoading value)  loading,required TResult Function( ModerationLogLoaded value)  loaded,required TResult Function( ModerationLogError value)  error,}){
final _that = this;
switch (_that) {
case ModerationLogInitial():
return initial(_that);case ModerationLogLoading():
return loading(_that);case ModerationLogLoaded():
return loaded(_that);case ModerationLogError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ModerationLogInitial value)?  initial,TResult? Function( ModerationLogLoading value)?  loading,TResult? Function( ModerationLogLoaded value)?  loaded,TResult? Function( ModerationLogError value)?  error,}){
final _that = this;
switch (_that) {
case ModerationLogInitial() when initial != null:
return initial(_that);case ModerationLogLoading() when loading != null:
return loading(_that);case ModerationLogLoaded() when loaded != null:
return loaded(_that);case ModerationLogError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<ModerationLogEntry> entries)?  loaded,TResult Function( Failure failure)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ModerationLogInitial() when initial != null:
return initial();case ModerationLogLoading() when loading != null:
return loading();case ModerationLogLoaded() when loaded != null:
return loaded(_that.entries);case ModerationLogError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<ModerationLogEntry> entries)  loaded,required TResult Function( Failure failure)  error,}) {final _that = this;
switch (_that) {
case ModerationLogInitial():
return initial();case ModerationLogLoading():
return loading();case ModerationLogLoaded():
return loaded(_that.entries);case ModerationLogError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<ModerationLogEntry> entries)?  loaded,TResult? Function( Failure failure)?  error,}) {final _that = this;
switch (_that) {
case ModerationLogInitial() when initial != null:
return initial();case ModerationLogLoading() when loading != null:
return loading();case ModerationLogLoaded() when loaded != null:
return loaded(_that.entries);case ModerationLogError() when error != null:
return error(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ModerationLogInitial implements ModerationLogState {
  const ModerationLogInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationLogInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModerationLogState.initial()';
}


}




/// @nodoc


class ModerationLogLoading implements ModerationLogState {
  const ModerationLogLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationLogLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ModerationLogState.loading()';
}


}




/// @nodoc


class ModerationLogLoaded implements ModerationLogState {
  const ModerationLogLoaded(final  List<ModerationLogEntry> entries): _entries = entries;
  

 final  List<ModerationLogEntry> _entries;
 List<ModerationLogEntry> get entries {
  if (_entries is EqualUnmodifiableListView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_entries);
}


/// Create a copy of ModerationLogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationLogLoadedCopyWith<ModerationLogLoaded> get copyWith => _$ModerationLogLoadedCopyWithImpl<ModerationLogLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationLogLoaded&&const DeepCollectionEquality().equals(other._entries, _entries));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries));

@override
String toString() {
  return 'ModerationLogState.loaded(entries: $entries)';
}


}

/// @nodoc
abstract mixin class $ModerationLogLoadedCopyWith<$Res> implements $ModerationLogStateCopyWith<$Res> {
  factory $ModerationLogLoadedCopyWith(ModerationLogLoaded value, $Res Function(ModerationLogLoaded) _then) = _$ModerationLogLoadedCopyWithImpl;
@useResult
$Res call({
 List<ModerationLogEntry> entries
});




}
/// @nodoc
class _$ModerationLogLoadedCopyWithImpl<$Res>
    implements $ModerationLogLoadedCopyWith<$Res> {
  _$ModerationLogLoadedCopyWithImpl(this._self, this._then);

  final ModerationLogLoaded _self;
  final $Res Function(ModerationLogLoaded) _then;

/// Create a copy of ModerationLogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(ModerationLogLoaded(
null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as List<ModerationLogEntry>,
  ));
}


}

/// @nodoc


class ModerationLogError implements ModerationLogState {
  const ModerationLogError(this.failure);
  

 final  Failure failure;

/// Create a copy of ModerationLogState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModerationLogErrorCopyWith<ModerationLogError> get copyWith => _$ModerationLogErrorCopyWithImpl<ModerationLogError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ModerationLogError&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ModerationLogState.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ModerationLogErrorCopyWith<$Res> implements $ModerationLogStateCopyWith<$Res> {
  factory $ModerationLogErrorCopyWith(ModerationLogError value, $Res Function(ModerationLogError) _then) = _$ModerationLogErrorCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ModerationLogErrorCopyWithImpl<$Res>
    implements $ModerationLogErrorCopyWith<$Res> {
  _$ModerationLogErrorCopyWithImpl(this._self, this._then);

  final ModerationLogError _self;
  final $Res Function(ModerationLogError) _then;

/// Create a copy of ModerationLogState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ModerationLogError(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ModerationLogState
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
