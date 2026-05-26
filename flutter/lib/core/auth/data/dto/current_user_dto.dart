import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_user_dto.freezed.dart';
part 'current_user_dto.g.dart';

@freezed
sealed class CurrentUserDto with _$CurrentUserDto {
  const factory CurrentUserDto({
    required int id,
    required String name,
    required String username,
    required String email,
    @JsonKey(name: 'is_superuser') @Default(false) bool isSuperuser,
    @JsonKey(name: 'is_moderator') @Default(false) bool isModerator,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @JsonKey(name: 'tier_id') int? tierId,
  }) = _CurrentUserDto;

  factory CurrentUserDto.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserDtoFromJson(json);
}

extension CurrentUserDtoX on CurrentUserDto {
  CurrentUser toDomain() => CurrentUser(
    id: id,
    username: username,
    email: email,
    name: name,
    isSuperuser: isSuperuser,
    isModerator: isModerator,
    profileImageUrl: profileImageUrl,
  );
}
