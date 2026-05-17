// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_tier_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserTierDto _$UserTierDtoFromJson(Map<String, dynamic> json) => _UserTierDto(
  tierId: (json['tier_id'] as num).toInt(),
  tierName: json['tier_name'] as String,
  tierCreatedAt: json['tier_created_at'] == null
      ? null
      : DateTime.parse(json['tier_created_at'] as String),
);

Map<String, dynamic> _$UserTierDtoToJson(_UserTierDto instance) =>
    <String, dynamic>{
      'tier_id': instance.tierId,
      'tier_name': instance.tierName,
      'tier_created_at': instance.tierCreatedAt?.toIso8601String(),
    };
