// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateUserRequestDto _$UpdateUserRequestDtoFromJson(
  Map<String, dynamic> json,
) => _UpdateUserRequestDto(
  name: json['name'] as String?,
  username: json['username'] as String?,
  email: json['email'] as String?,
  profileImageUrl: json['profile_image_url'] as String?,
);

Map<String, dynamic> _$UpdateUserRequestDtoToJson(
  _UpdateUserRequestDto instance,
) => <String, dynamic>{
  'name': ?instance.name,
  'username': ?instance.username,
  'email': ?instance.email,
  'profile_image_url': ?instance.profileImageUrl,
};
