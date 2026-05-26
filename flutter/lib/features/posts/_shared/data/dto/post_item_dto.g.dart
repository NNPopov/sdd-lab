// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostItemDto _$PostItemDtoFromJson(Map<String, dynamic> json) => _PostItemDto(
  id: (json['id'] as num).toInt(),
  username: json['username'] as String,
  postUuid: json['post_uuid'] as String,
  status: json['status'] as String,
  title: json['title'] as String? ?? '',
  text: json['text'] as String? ?? '',
  mediaUrl: json['media_url'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  createdByUserId: (json['created_by_user_id'] as num).toInt(),
);

Map<String, dynamic> _$PostItemDtoToJson(_PostItemDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'post_uuid': instance.postUuid,
      'status': instance.status,
      'title': instance.title,
      'text': instance.text,
      'media_url': instance.mediaUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'created_by_user_id': instance.createdByUserId,
    };
