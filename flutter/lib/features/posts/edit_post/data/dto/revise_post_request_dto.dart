import 'package:freezed_annotation/freezed_annotation.dart';

part 'revise_post_request_dto.freezed.dart';
part 'revise_post_request_dto.g.dart';

@freezed
sealed class RevisePostRequestDto with _$RevisePostRequestDto {
  const factory RevisePostRequestDto({
    String? title,
    String? text,
    @JsonKey(name: 'message') required String message,
  }) = _RevisePostRequestDto;

  factory RevisePostRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RevisePostRequestDtoFromJson(json);
}
