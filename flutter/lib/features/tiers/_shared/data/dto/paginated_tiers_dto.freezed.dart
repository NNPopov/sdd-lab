// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paginated_tiers_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaginatedTiersDto {

 List<TierDto> get items;@JsonKey(name: 'total_count') int get totalCount; int get page;@JsonKey(name: 'items_per_page') int get itemsPerPage;
/// Create a copy of PaginatedTiersDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginatedTiersDtoCopyWith<PaginatedTiersDto> get copyWith => _$PaginatedTiersDtoCopyWithImpl<PaginatedTiersDto>(this as PaginatedTiersDto, _$identity);

  /// Serializes this PaginatedTiersDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedTiersDto&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.page, page) || other.page == page)&&(identical(other.itemsPerPage, itemsPerPage) || other.itemsPerPage == itemsPerPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,page,itemsPerPage);

@override
String toString() {
  return 'PaginatedTiersDto(items: $items, totalCount: $totalCount, page: $page, itemsPerPage: $itemsPerPage)';
}


}

/// @nodoc
abstract mixin class $PaginatedTiersDtoCopyWith<$Res>  {
  factory $PaginatedTiersDtoCopyWith(PaginatedTiersDto value, $Res Function(PaginatedTiersDto) _then) = _$PaginatedTiersDtoCopyWithImpl;
@useResult
$Res call({
 List<TierDto> items,@JsonKey(name: 'total_count') int totalCount, int page,@JsonKey(name: 'items_per_page') int itemsPerPage
});




}
/// @nodoc
class _$PaginatedTiersDtoCopyWithImpl<$Res>
    implements $PaginatedTiersDtoCopyWith<$Res> {
  _$PaginatedTiersDtoCopyWithImpl(this._self, this._then);

  final PaginatedTiersDto _self;
  final $Res Function(PaginatedTiersDto) _then;

/// Create a copy of PaginatedTiersDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? page = null,Object? itemsPerPage = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<TierDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,itemsPerPage: null == itemsPerPage ? _self.itemsPerPage : itemsPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginatedTiersDto].
extension PaginatedTiersDtoPatterns on PaginatedTiersDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginatedTiersDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginatedTiersDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginatedTiersDto value)  $default,){
final _that = this;
switch (_that) {
case _PaginatedTiersDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginatedTiersDto value)?  $default,){
final _that = this;
switch (_that) {
case _PaginatedTiersDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<TierDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginatedTiersDto() when $default != null:
return $default(_that.items,_that.totalCount,_that.page,_that.itemsPerPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<TierDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)  $default,) {final _that = this;
switch (_that) {
case _PaginatedTiersDto():
return $default(_that.items,_that.totalCount,_that.page,_that.itemsPerPage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<TierDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)?  $default,) {final _that = this;
switch (_that) {
case _PaginatedTiersDto() when $default != null:
return $default(_that.items,_that.totalCount,_that.page,_that.itemsPerPage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginatedTiersDto implements PaginatedTiersDto {
  const _PaginatedTiersDto({required final  List<TierDto> items, @JsonKey(name: 'total_count') required this.totalCount, required this.page, @JsonKey(name: 'items_per_page') required this.itemsPerPage}): _items = items;
  factory _PaginatedTiersDto.fromJson(Map<String, dynamic> json) => _$PaginatedTiersDtoFromJson(json);

 final  List<TierDto> _items;
@override List<TierDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_count') final  int totalCount;
@override final  int page;
@override@JsonKey(name: 'items_per_page') final  int itemsPerPage;

/// Create a copy of PaginatedTiersDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginatedTiersDtoCopyWith<_PaginatedTiersDto> get copyWith => __$PaginatedTiersDtoCopyWithImpl<_PaginatedTiersDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginatedTiersDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginatedTiersDto&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.page, page) || other.page == page)&&(identical(other.itemsPerPage, itemsPerPage) || other.itemsPerPage == itemsPerPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,page,itemsPerPage);

@override
String toString() {
  return 'PaginatedTiersDto(items: $items, totalCount: $totalCount, page: $page, itemsPerPage: $itemsPerPage)';
}


}

/// @nodoc
abstract mixin class _$PaginatedTiersDtoCopyWith<$Res> implements $PaginatedTiersDtoCopyWith<$Res> {
  factory _$PaginatedTiersDtoCopyWith(_PaginatedTiersDto value, $Res Function(_PaginatedTiersDto) _then) = __$PaginatedTiersDtoCopyWithImpl;
@override @useResult
$Res call({
 List<TierDto> items,@JsonKey(name: 'total_count') int totalCount, int page,@JsonKey(name: 'items_per_page') int itemsPerPage
});




}
/// @nodoc
class __$PaginatedTiersDtoCopyWithImpl<$Res>
    implements _$PaginatedTiersDtoCopyWith<$Res> {
  __$PaginatedTiersDtoCopyWithImpl(this._self, this._then);

  final _PaginatedTiersDto _self;
  final $Res Function(_PaginatedTiersDto) _then;

/// Create a copy of PaginatedTiersDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? page = null,Object? itemsPerPage = null,}) {
  return _then(_PaginatedTiersDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<TierDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,itemsPerPage: null == itemsPerPage ? _self.itemsPerPage : itemsPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
