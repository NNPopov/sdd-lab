import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_item_dto.freezed.dart';
part 'post_item_dto.g.dart';

@freezed
sealed class PostItemDto with _$PostItemDto {
  const factory PostItemDto({
    required int id,
    required String username,
    @JsonKey(name: 'post_uuid') required String postUuid,
    required String status,
    @Default('') String title,
    @Default('') String text,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'created_by_user_id') required int createdByUserId,
  }) = _PostItemDto;

  factory PostItemDto.fromJson(Map<String, dynamic> json) =>
      _$PostItemDtoFromJson(json);
}
