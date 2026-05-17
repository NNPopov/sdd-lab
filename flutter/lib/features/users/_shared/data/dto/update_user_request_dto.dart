import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_user_request_dto.freezed.dart';
part 'update_user_request_dto.g.dart';

@freezed
sealed class UpdateUserRequestDto with _$UpdateUserRequestDto {
  const factory UpdateUserRequestDto({
    @JsonKey(includeIfNull: false) String? name,
    @JsonKey(includeIfNull: false) String? username,
    @JsonKey(includeIfNull: false) String? email,
    @JsonKey(name: 'profile_image_url', includeIfNull: false)
    String? profileImageUrl,
  }) = _UpdateUserRequestDto;

  factory UpdateUserRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserRequestDtoFromJson(json);
}
