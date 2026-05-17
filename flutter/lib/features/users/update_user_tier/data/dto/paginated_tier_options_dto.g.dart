// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_tier_options_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaginatedTierOptionsDto _$PaginatedTierOptionsDtoFromJson(
  Map<String, dynamic> json,
) => _PaginatedTierOptionsDto(
  data:
      (json['data'] as List<dynamic>?)
          ?.map((e) => TierOptionDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
  hasMore: json['has_more'] as bool? ?? false,
);

Map<String, dynamic> _$PaginatedTierOptionsDtoToJson(
  _PaginatedTierOptionsDto instance,
) => <String, dynamic>{
  'data': instance.data,
  'total_count': instance.totalCount,
  'has_more': instance.hasMore,
};
