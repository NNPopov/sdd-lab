import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

@freezed
sealed class UserDto with _$UserDto {
  const factory UserDto({
    required int id,
    required String name,
    required String username,
    required String email,
    @JsonKey(name: 'is_moderator') @Default(false) bool isModerator,
    @JsonKey(name: 'profile_image_url') String? profileImageUrl,
    @JsonKey(name: 'tier_id') int? tierId,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);
}

extension UserDtoMapper on UserDto {
  User toDomain() => User(
    id: id,
    name: name,
    username: username,
    email: email,
    isModerator: isModerator,
    profileImageUrl: profileImageUrl,
    tierId: tierId,
  );
}
