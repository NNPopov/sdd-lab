// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_users_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaginatedUsersDto _$PaginatedUsersDtoFromJson(Map<String, dynamic> json) =>
    _PaginatedUsersDto(
      items: (json['items'] as List<dynamic>)
          .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      itemsPerPage: (json['items_per_page'] as num).toInt(),
    );

Map<String, dynamic> _$PaginatedUsersDtoToJson(_PaginatedUsersDto instance) =>
    <String, dynamic>{
      'items': instance.items,
      'total_count': instance.totalCount,
      'page': instance.page,
      'items_per_page': instance.itemsPerPage,
    };
