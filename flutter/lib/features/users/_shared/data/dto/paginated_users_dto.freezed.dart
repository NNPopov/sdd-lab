// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paginated_users_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaginatedUsersDto {

 List<UserDto> get items;@JsonKey(name: 'total_count') int get totalCount; int get page;@JsonKey(name: 'items_per_page') int get itemsPerPage;
/// Create a copy of PaginatedUsersDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaginatedUsersDtoCopyWith<PaginatedUsersDto> get copyWith => _$PaginatedUsersDtoCopyWithImpl<PaginatedUsersDto>(this as PaginatedUsersDto, _$identity);

  /// Serializes this PaginatedUsersDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaginatedUsersDto&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.page, page) || other.page == page)&&(identical(other.itemsPerPage, itemsPerPage) || other.itemsPerPage == itemsPerPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,page,itemsPerPage);

@override
String toString() {
  return 'PaginatedUsersDto(items: $items, totalCount: $totalCount, page: $page, itemsPerPage: $itemsPerPage)';
}


}

/// @nodoc
abstract mixin class $PaginatedUsersDtoCopyWith<$Res>  {
  factory $PaginatedUsersDtoCopyWith(PaginatedUsersDto value, $Res Function(PaginatedUsersDto) _then) = _$PaginatedUsersDtoCopyWithImpl;
@useResult
$Res call({
 List<UserDto> items,@JsonKey(name: 'total_count') int totalCount, int page,@JsonKey(name: 'items_per_page') int itemsPerPage
});




}
/// @nodoc
class _$PaginatedUsersDtoCopyWithImpl<$Res>
    implements $PaginatedUsersDtoCopyWith<$Res> {
  _$PaginatedUsersDtoCopyWithImpl(this._self, this._then);

  final PaginatedUsersDto _self;
  final $Res Function(PaginatedUsersDto) _then;

/// Create a copy of PaginatedUsersDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? page = null,Object? itemsPerPage = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<UserDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,itemsPerPage: null == itemsPerPage ? _self.itemsPerPage : itemsPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaginatedUsersDto].
extension PaginatedUsersDtoPatterns on PaginatedUsersDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaginatedUsersDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaginatedUsersDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaginatedUsersDto value)  $default,){
final _that = this;
switch (_that) {
case _PaginatedUsersDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaginatedUsersDto value)?  $default,){
final _that = this;
switch (_that) {
case _PaginatedUsersDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<UserDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaginatedUsersDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<UserDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)  $default,) {final _that = this;
switch (_that) {
case _PaginatedUsersDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<UserDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)?  $default,) {final _that = this;
switch (_that) {
case _PaginatedUsersDto() when $default != null:
return $default(_that.items,_that.totalCount,_that.page,_that.itemsPerPage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaginatedUsersDto implements PaginatedUsersDto {
  const _PaginatedUsersDto({required final  List<UserDto> items, @JsonKey(name: 'total_count') required this.totalCount, required this.page, @JsonKey(name: 'items_per_page') required this.itemsPerPage}): _items = items;
  factory _PaginatedUsersDto.fromJson(Map<String, dynamic> json) => _$PaginatedUsersDtoFromJson(json);

 final  List<UserDto> _items;
@override List<UserDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_count') final  int totalCount;
@override final  int page;
@override@JsonKey(name: 'items_per_page') final  int itemsPerPage;

/// Create a copy of PaginatedUsersDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaginatedUsersDtoCopyWith<_PaginatedUsersDto> get copyWith => __$PaginatedUsersDtoCopyWithImpl<_PaginatedUsersDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaginatedUsersDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaginatedUsersDto&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.page, page) || other.page == page)&&(identical(other.itemsPerPage, itemsPerPage) || other.itemsPerPage == itemsPerPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,page,itemsPerPage);

@override
String toString() {
  return 'PaginatedUsersDto(items: $items, totalCount: $totalCount, page: $page, itemsPerPage: $itemsPerPage)';
}


}

/// @nodoc
abstract mixin class _$PaginatedUsersDtoCopyWith<$Res> implements $PaginatedUsersDtoCopyWith<$Res> {
  factory _$PaginatedUsersDtoCopyWith(_PaginatedUsersDto value, $Res Function(_PaginatedUsersDto) _then) = __$PaginatedUsersDtoCopyWithImpl;
@override @useResult
$Res call({
 List<UserDto> items,@JsonKey(name: 'total_count') int totalCount, int page,@JsonKey(name: 'items_per_page') int itemsPerPage
});




}
/// @nodoc
class __$PaginatedUsersDtoCopyWithImpl<$Res>
    implements _$PaginatedUsersDtoCopyWith<$Res> {
  __$PaginatedUsersDtoCopyWithImpl(this._self, this._then);

  final _PaginatedUsersDto _self;
  final $Res Function(_PaginatedUsersDto) _then;

/// Create a copy of PaginatedUsersDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? page = null,Object? itemsPerPage = null,}) {
  return _then(_PaginatedUsersDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<UserDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,itemsPerPage: null == itemsPerPage ? _self.itemsPerPage : itemsPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
