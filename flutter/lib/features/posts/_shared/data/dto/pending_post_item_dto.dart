import 'package:flutter_application_1/features/posts/_shared/data/dto/moderation_log_entry_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_post_item_dto.freezed.dart';
part 'pending_post_item_dto.g.dart';

@freezed
sealed class PendingPostItemDto with _$PendingPostItemDto {
  const factory PendingPostItemDto({
    @JsonKey(name: 'post_uuid') required String postUuid,
    required String title,
    required String text,
    required String status,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'author_username') required String authorUsername,
    @Default([])
    @JsonKey(name: 'moderation_log')
    List<ModerationLogEntryDto> moderationLog,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'media_url') String? mediaUrl,
  }) = _PendingPostItemDto;

  factory PendingPostItemDto.fromJson(Map<String, dynamic> json) =>
      _$PendingPostItemDtoFromJson(json);
}
