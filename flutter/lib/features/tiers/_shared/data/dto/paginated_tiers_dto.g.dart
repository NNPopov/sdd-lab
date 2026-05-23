// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_tiers_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaginatedTiersDto _$PaginatedTiersDtoFromJson(Map<String, dynamic> json) =>
    _PaginatedTiersDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => TierDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      itemsPerPage: (json['items_per_page'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedTiersDtoToJson(_PaginatedTiersDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_count': instance.totalCount,
      'page': instance.page,
      'items_per_page': instance.itemsPerPage,
    };
