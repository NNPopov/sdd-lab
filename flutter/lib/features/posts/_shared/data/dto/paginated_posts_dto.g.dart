// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_posts_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaginatedPostsDto _$PaginatedPostsDtoFromJson(Map<String, dynamic> json) =>
    _PaginatedPostsDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => PostItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      itemsPerPage: (json['items_per_page'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedPostsDtoToJson(_PaginatedPostsDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_count': instance.totalCount,
      'page': instance.page,
      'items_per_page': instance.itemsPerPage,
    };
