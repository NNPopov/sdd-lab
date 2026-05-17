// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostDto _$PostDtoFromJson(Map<String, dynamic> json) => _PostDto(
  id: (json['id'] as num).toInt(),
  postUuid: json['post_uuid'] as String,
  status: json['status'] as String,
  title: json['title'] as String? ?? '',
  text: json['text'] as String? ?? '',
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  mediaUrl: json['media_url'] as String?,
  createdByUserId: (json['created_by_user_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$PostDtoToJson(_PostDto instance) => <String, dynamic>{
  'id': instance.id,
  'post_uuid': instance.postUuid,
  'status': instance.status,
  'title': instance.title,
  'text': instance.text,
  'created_at': instance.createdAt?.toIso8601String(),
  'media_url': instance.mediaUrl,
  'created_by_user_id': instance.createdByUserId,
};
