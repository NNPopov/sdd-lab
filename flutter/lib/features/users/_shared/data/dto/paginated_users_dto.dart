import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_users_dto.freezed.dart';
part 'paginated_users_dto.g.dart';

@freezed
sealed class PaginatedUsersDto with _$PaginatedUsersDto {
  const factory PaginatedUsersDto({
    required List<UserDto> items,
    @JsonKey(name: 'total_count') required int totalCount,
    required int page,
    @JsonKey(name: 'items_per_page') required int itemsPerPage,
  }) = _PaginatedUsersDto;

  factory PaginatedUsersDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedUsersDtoFromJson(json);
}
