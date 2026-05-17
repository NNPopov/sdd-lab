// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tier_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TierDetailDto _$TierDetailDtoFromJson(Map<String, dynamic> json) =>
    _TierDetailDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$TierDetailDtoToJson(_TierDetailDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_at': instance.createdAt?.toIso8601String(),
    };
