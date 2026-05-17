// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_tiers_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaginatedTiersDto _$PaginatedTiersDtoFromJson(Map<String, dynamic> json) =>
    _PaginatedTiersDto(
      data: (json['data'] as List<dynamic>)
          .map((e) => TierDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      hasMore: json['has_more'] as bool,
      page: (json['page'] as num).toInt(),
      itemsPerPage: (json['items_per_page'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedTiersDtoToJson(_PaginatedTiersDto instance) =>
    <String, dynamic>{
      'data': instance.data,
      'total_count': instance.totalCount,
      'has_more': instance.hasMore,
      'page': instance.page,
      'items_per_page': instance.itemsPerPage,
    };
