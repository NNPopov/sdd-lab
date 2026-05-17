// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_posts_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PendingPostsDto {

 List<PendingPostItemDto> get items;@JsonKey(name: 'total_count') int get totalCount; int get page;@JsonKey(name: 'items_per_page') int get itemsPerPage;
/// Create a copy of PendingPostsDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingPostsDtoCopyWith<PendingPostsDto> get copyWith => _$PendingPostsDtoCopyWithImpl<PendingPostsDto>(this as PendingPostsDto, _$identity);

  /// Serializes this PendingPostsDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingPostsDto&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.page, page) || other.page == page)&&(identical(other.itemsPerPage, itemsPerPage) || other.itemsPerPage == itemsPerPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(items),totalCount,page,itemsPerPage);

@override
String toString() {
  return 'PendingPostsDto(items: $items, totalCount: $totalCount, page: $page, itemsPerPage: $itemsPerPage)';
}


}

/// @nodoc
abstract mixin class $PendingPostsDtoCopyWith<$Res>  {
  factory $PendingPostsDtoCopyWith(PendingPostsDto value, $Res Function(PendingPostsDto) _then) = _$PendingPostsDtoCopyWithImpl;
@useResult
$Res call({
 List<PendingPostItemDto> items,@JsonKey(name: 'total_count') int totalCount, int page,@JsonKey(name: 'items_per_page') int itemsPerPage
});




}
/// @nodoc
class _$PendingPostsDtoCopyWithImpl<$Res>
    implements $PendingPostsDtoCopyWith<$Res> {
  _$PendingPostsDtoCopyWithImpl(this._self, this._then);

  final PendingPostsDto _self;
  final $Res Function(PendingPostsDto) _then;

/// Create a copy of PendingPostsDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? totalCount = null,Object? page = null,Object? itemsPerPage = null,}) {
  return _then(_self.copyWith(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<PendingPostItemDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,itemsPerPage: null == itemsPerPage ? _self.itemsPerPage : itemsPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingPostsDto].
extension PendingPostsDtoPatterns on PendingPostsDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingPostsDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingPostsDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingPostsDto value)  $default,){
final _that = this;
switch (_that) {
case _PendingPostsDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingPostsDto value)?  $default,){
final _that = this;
switch (_that) {
case _PendingPostsDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PendingPostItemDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingPostsDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PendingPostItemDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)  $default,) {final _that = this;
switch (_that) {
case _PendingPostsDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PendingPostItemDto> items, @JsonKey(name: 'total_count')  int totalCount,  int page, @JsonKey(name: 'items_per_page')  int itemsPerPage)?  $default,) {final _that = this;
switch (_that) {
case _PendingPostsDto() when $default != null:
return $default(_that.items,_that.totalCount,_that.page,_that.itemsPerPage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PendingPostsDto implements PendingPostsDto {
  const _PendingPostsDto({required final  List<PendingPostItemDto> items, @JsonKey(name: 'total_count') required this.totalCount, required this.page, @JsonKey(name: 'items_per_page') required this.itemsPerPage}): _items = items;
  factory _PendingPostsDto.fromJson(Map<String, dynamic> json) => _$PendingPostsDtoFromJson(json);

 final  List<PendingPostItemDto> _items;
@override List<PendingPostItemDto> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'total_count') final  int totalCount;
@override final  int page;
@override@JsonKey(name: 'items_per_page') final  int itemsPerPage;

/// Create a copy of PendingPostsDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingPostsDtoCopyWith<_PendingPostsDto> get copyWith => __$PendingPostsDtoCopyWithImpl<_PendingPostsDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PendingPostsDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingPostsDto&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.page, page) || other.page == page)&&(identical(other.itemsPerPage, itemsPerPage) || other.itemsPerPage == itemsPerPage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),totalCount,page,itemsPerPage);

@override
String toString() {
  return 'PendingPostsDto(items: $items, totalCount: $totalCount, page: $page, itemsPerPage: $itemsPerPage)';
}


}

/// @nodoc
abstract mixin class _$PendingPostsDtoCopyWith<$Res> implements $PendingPostsDtoCopyWith<$Res> {
  factory _$PendingPostsDtoCopyWith(_PendingPostsDto value, $Res Function(_PendingPostsDto) _then) = __$PendingPostsDtoCopyWithImpl;
@override @useResult
$Res call({
 List<PendingPostItemDto> items,@JsonKey(name: 'total_count') int totalCount, int page,@JsonKey(name: 'items_per_page') int itemsPerPage
});




}
/// @nodoc
class __$PendingPostsDtoCopyWithImpl<$Res>
    implements _$PendingPostsDtoCopyWith<$Res> {
  __$PendingPostsDtoCopyWithImpl(this._self, this._then);

  final _PendingPostsDto _self;
  final $Res Function(_PendingPostsDto) _then;

/// Create a copy of PendingPostsDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? totalCount = null,Object? page = null,Object? itemsPerPage = null,}) {
  return _then(_PendingPostsDto(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PendingPostItemDto>,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,itemsPerPage: null == itemsPerPage ? _self.itemsPerPage : itemsPerPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
