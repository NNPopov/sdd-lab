import 'package:freezed_annotation/freezed_annotation.dart';

part 'moderate_post_request_dto.freezed.dart';
part 'moderate_post_request_dto.g.dart';

@freezed
sealed class ModeratePostRequestDto with _$ModeratePostRequestDto {
  const factory ModeratePostRequestDto({
    required String action,
    String? message,
  }) = _ModeratePostRequestDto;

  factory ModeratePostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ModeratePostRequestDtoFromJson(json);
}
