// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tier_option_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TierOptionDto _$TierOptionDtoFromJson(Map<String, dynamic> json) =>
    _TierOptionDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );

Map<String, dynamic> _$TierOptionDtoToJson(_TierOptionDto instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
