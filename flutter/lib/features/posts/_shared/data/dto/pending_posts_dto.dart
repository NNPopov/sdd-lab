import 'package:flutter_application_1/features/posts/_shared/data/dto/pending_post_item_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_posts_dto.freezed.dart';
part 'pending_posts_dto.g.dart';

@freezed
sealed class PendingPostsDto with _$PendingPostsDto {
  const factory PendingPostsDto({
    required List<PendingPostItemDto> items,
    @JsonKey(name: 'total_count') required int totalCount,
    required int page,
    @JsonKey(name: 'items_per_page') required int itemsPerPage,
  }) = _PendingPostsDto;

  factory PendingPostsDto.fromJson(Map<String, dynamic> json) =>
      _$PendingPostsDtoFromJson(json);
}
