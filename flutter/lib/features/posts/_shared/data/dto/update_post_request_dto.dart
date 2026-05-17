import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_post_request_dto.freezed.dart';
part 'update_post_request_dto.g.dart';

@freezed
sealed class UpdatePostRequestDto with _$UpdatePostRequestDto {
  const factory UpdatePostRequestDto({
    required String title,
    required String text,
    @JsonKey(name: 'media_url') String? mediaUrl,
  }) = _UpdatePostRequestDto;

  factory UpdatePostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatePostRequestDtoFromJson(json);
}
