// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paginated_tier_options_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaginatedTierOptionsDto {

 List<TierOptionDto> get data;@JsonKey(name: 'total_count') int get totalCount;@JsonKey(name: 'has_more') bool get hasMore;
/// Create a copy of PaginatedTierOptionsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginatedTierOptionsDtoCopyWith<PaginatedTierOptionsDto> get copyWith => _$PaginatedTierOptionsDtoCopyWithImpl<PaginatedTierOptionsDto>(this as PaginatedTierOptionsDto, _$identity);

  /// Serializes this PaginatedTierOptionsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedTierOptionsDto&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data),totalCount,hasMore);

@override
String toString() {
  return 'PaginatedTierOptionsDto(data: $data, totalCount: $totalCount, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $PaginatedTierOptionsDtoCopyWith<$Res>  {
  factory $PaginatedTierOptionsDtoCopyWith(PaginatedTierOptionsDto value, $Res Function(PaginatedTierOptionsDto) _then) = _$PaginatedTierOptionsDtoCopyWithImpl;
@useResult
$Res call({
 List<TierOptionDto> data,@JsonKey(name: 'total_count') int totalCount,@JsonKey(name: 'has_more') bool hasMore
});




}
/// @nodoc
class _$PaginatedTierOptionsDtoCopyWithImpl<$Res>
    implements $PaginatedTierOptionsDtoCopyWith<$Res> {
  _$PaginatedTierOptionsDtoCopyWithImpl(this._self, this._then);

  final PaginatedTierOptionsDto _self;
  final $Res Function(PaginatedTierOptionsDto) _then;

/// Create a copy of PaginatedTierOptionsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? data = null,Object? totalCount = null,Object? hasMore = null,}) {
  return _then(_self.copyWith(
data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<TierOptionDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginatedTierOptionsDto].
extension PaginatedTierOptionsDtoPatterns on PaginatedTierOptionsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginatedTierOptionsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginatedTierOptionsDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginatedTierOptionsDto value)  $default,){
final _that = this;
switch (_that) {
case _PaginatedTierOptionsDto():
return $default(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginatedTierOptionsDto value)?  $default,){
final _that = this;
switch (_that) {
case _PaginatedTierOptionsDto() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TierOptionDto> data, @JsonKey(name: 'total_count')  int totalCount, @JsonKey(name: 'has_more')  bool hasMore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginatedTierOptionsDto() when $default != null:
return $default(_that.data,_that.totalCount,_that.hasMore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TierOptionDto> data, @JsonKey(name: 'total_count')  int totalCount, @JsonKey(name: 'has_more')  bool hasMore)  $default,) {final _that = this;
switch (_that) {
case _PaginatedTierOptionsDto():
return $default(_that.data,_that.totalCount,_that.hasMore);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TierOptionDto> data, @JsonKey(name: 'total_count')  int totalCount, @JsonKey(name: 'has_more')  bool hasMore)?  $default,) {final _that = this;
switch (_that) {
case _PaginatedTierOptionsDto() when $default != null:
return $default(_that.data,_that.totalCount,_that.hasMore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginatedTierOptionsDto implements PaginatedTierOptionsDto {
  const _PaginatedTierOptionsDto({final  List<TierOptionDto> data = const [], @JsonKey(name: 'total_count') this.totalCount = 0, @JsonKey(name: 'has_more') this.hasMore = false}): _data = data;
  factory _PaginatedTierOptionsDto.fromJson(Map<String, dynamic> json) => _$PaginatedTierOptionsDtoFromJson(json);

 final  List<TierOptionDto> _data;
@override@JsonKey() List<TierOptionDto> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}

@override@JsonKey(name: 'total_count') final  int totalCount;
@override@JsonKey(name: 'has_more') final  bool hasMore;

/// Create a copy of PaginatedTierOptionsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginatedTierOptionsDtoCopyWith<_PaginatedTierOptionsDto> get copyWith => __$PaginatedTierOptionsDtoCopyWithImpl<_PaginatedTierOptionsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginatedTierOptionsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginatedTierOptionsDto&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_data),totalCount,hasMore);

@override
String toString() {
  return 'PaginatedTierOptionsDto(data: $data, totalCount: $totalCount, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class _$PaginatedTierOptionsDtoCopyWith<$Res> implements $PaginatedTierOptionsDtoCopyWith<$Res> {
  factory _$PaginatedTierOptionsDtoCopyWith(_PaginatedTierOptionsDto value, $Res Function(_PaginatedTierOptionsDto) _then) = __$PaginatedTierOptionsDtoCopyWithImpl;
@override @useResult
$Res call({
 List<TierOptionDto> data,@JsonKey(name: 'total_count') int totalCount,@JsonKey(name: 'has_more') bool hasMore
});




}
/// @nodoc
class __$PaginatedTierOptionsDtoCopyWithImpl<$Res>
    implements _$PaginatedTierOptionsDtoCopyWith<$Res> {
  __$PaginatedTierOptionsDtoCopyWithImpl(this._self, this._then);

  final _PaginatedTierOptionsDto _self;
  final $Res Function(_PaginatedTierOptionsDto) _then;

/// Create a copy of PaginatedTierOptionsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? data = null,Object? totalCount = null,Object? hasMore = null,}) {
  return _then(_PaginatedTierOptionsDto(
data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<TierOptionDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
