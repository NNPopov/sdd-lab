import 'package:freezed_annotation/freezed_annotation.dart';

part 'moderate_post_result_dto.freezed.dart';
part 'moderate_post_result_dto.g.dart';

@freezed
sealed class ModeratePostResultDto with _$ModeratePostResultDto {
  const factory ModeratePostResultDto({
    @JsonKey(name: 'post_uuid') required String postUuid,
    required String status,
  }) = _ModeratePostResultDto;

  factory ModeratePostResultDto.fromJson(Map<String, dynamic> json) =>
      _$ModeratePostResultDtoFromJson(json);
}
