// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tier_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TierDto _$TierDtoFromJson(Map<String, dynamic> json) => _TierDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String? ?? '',
);

Map<String, dynamic> _$TierDtoToJson(_TierDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
};
