// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CurrentUserDto _$CurrentUserDtoFromJson(Map<String, dynamic> json) =>
    _CurrentUserDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      isSuperuser: json['is_superuser'] as bool? ?? false,
      isModerator: json['is_moderator'] as bool? ?? false,
      profileImageUrl: json['profile_image_url'] as String?,
      tierId: (json['tier_id'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CurrentUserDtoToJson(_CurrentUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'email': instance.email,
      'is_superuser': instance.isSuperuser,
      'is_moderator': instance.isModerator,
      'profile_image_url': instance.profileImageUrl,
      'tier_id': instance.tierId,
    };
