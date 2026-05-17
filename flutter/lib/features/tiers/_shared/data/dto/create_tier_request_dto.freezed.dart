// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_tier_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CreateTierRequestDto {

 String get name;
/// Create a copy of CreateTierRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreateTierRequestDtoCopyWith<CreateTierRequestDto> get copyWith => _$CreateTierRequestDtoCopyWithImpl<CreateTierRequestDto>(this as CreateTierRequestDto, _$identity);

  /// Serializes this CreateTierRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreateTierRequestDto&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'CreateTierRequestDto(name: $name)';
}


}

/// @nodoc
abstract mixin class $CreateTierRequestDtoCopyWith<$Res>  {
  factory $CreateTierRequestDtoCopyWith(CreateTierRequestDto value, $Res Function(CreateTierRequestDto) _then) = _$CreateTierRequestDtoCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$CreateTierRequestDtoCopyWithImpl<$Res>
    implements $CreateTierRequestDtoCopyWith<$Res> {
  _$CreateTierRequestDtoCopyWithImpl(this._self, this._then);

  final CreateTierRequestDto _self;
  final $Res Function(CreateTierRequestDto) _then;

/// Create a copy of CreateTierRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CreateTierRequestDto].
extension CreateTierRequestDtoPatterns on CreateTierRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CreateTierRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CreateTierRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CreateTierRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _CreateTierRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CreateTierRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _CreateTierRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CreateTierRequestDto() when $default != null:
return $default(_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name)  $default,) {final _that = this;
switch (_that) {
case _CreateTierRequestDto():
return $default(_that.name);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name)?  $default,) {final _that = this;
switch (_that) {
case _CreateTierRequestDto() when $default != null:
return $default(_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CreateTierRequestDto implements CreateTierRequestDto {
  const _CreateTierRequestDto({required this.name});
  factory _CreateTierRequestDto.fromJson(Map<String, dynamic> json) => _$CreateTierRequestDtoFromJson(json);

@override final  String name;

/// Create a copy of CreateTierRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CreateTierRequestDtoCopyWith<_CreateTierRequestDto> get copyWith => __$CreateTierRequestDtoCopyWithImpl<_CreateTierRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CreateTierRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateTierRequestDto&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'CreateTierRequestDto(name: $name)';
}


}

/// @nodoc
abstract mixin class _$CreateTierRequestDtoCopyWith<$Res> implements $CreateTierRequestDtoCopyWith<$Res> {
  factory _$CreateTierRequestDtoCopyWith(_CreateTierRequestDto value, $Res Function(_CreateTierRequestDto) _then) = __$CreateTierRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String name
});




}
/// @nodoc
class __$CreateTierRequestDtoCopyWithImpl<$Res>
    implements _$CreateTierRequestDtoCopyWith<$Res> {
  __$CreateTierRequestDtoCopyWithImpl(this._self, this._then);

  final _CreateTierRequestDto _self;
  final $Res Function(_CreateTierRequestDto) _then;

/// Create a copy of CreateTierRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(_CreateTierRequestDto(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
