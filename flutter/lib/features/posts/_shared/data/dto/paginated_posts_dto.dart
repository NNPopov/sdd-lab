import 'package:flutter_application_1/features/posts/_shared/data/dto/post_item_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_posts_dto.freezed.dart';
part 'paginated_posts_dto.g.dart';

@freezed
sealed class PaginatedPostsDto with _$PaginatedPostsDto {
  const factory PaginatedPostsDto({
    required List<PostItemDto> items,
    @JsonKey(name: 'total_count') required int totalCount,
    required int page,
    @JsonKey(name: 'items_per_page') required int itemsPerPage,
  }) = _PaginatedPostsDto;

  factory PaginatedPostsDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedPostsDtoFromJson(json);
}
