// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_posts_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingPostsDto _$PendingPostsDtoFromJson(Map<String, dynamic> json) =>
    _PendingPostsDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => PendingPostItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      itemsPerPage: (json['items_per_page'] as num).toInt(),
    );

Map<String, dynamic> _$PendingPostsDtoToJson(_PendingPostsDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_count': instance.totalCount,
      'page': instance.page,
      'items_per_page': instance.itemsPerPage,
    };
