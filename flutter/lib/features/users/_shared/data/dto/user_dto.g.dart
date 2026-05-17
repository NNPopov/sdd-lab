// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserDto _$UserDtoFromJson(Map<String, dynamic> json) => _UserDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  isModerator: json['is_moderator'] as bool? ?? false,
  profileImageUrl: json['profile_image_url'] as String?,
  tierId: (json['tier_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserDtoToJson(_UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'username': instance.username,
  'email': instance.email,
  'is_moderator': instance.isModerator,
  'profile_image_url': instance.profileImageUrl,
  'tier_id': instance.tierId,
};
