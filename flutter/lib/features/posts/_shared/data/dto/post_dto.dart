import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_dto.freezed.dart';
part 'post_dto.g.dart';

@freezed
sealed class PostDto with _$PostDto {
  const factory PostDto({
    required int id,
    @JsonKey(name: 'post_uuid') required String postUuid,
    required String status,
    @Default('') String title,
    @Default('') String text,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'created_by_user_id') required int createdByUserId,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);
}
