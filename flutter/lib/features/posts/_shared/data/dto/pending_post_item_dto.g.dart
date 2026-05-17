// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_post_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PendingPostItemDto _$PendingPostItemDtoFromJson(Map<String, dynamic> json) =>
    _PendingPostItemDto(
      postUuid: json['post_uuid'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      authorUsername: json['author_username'] as String,
      moderationLog:
          (json['moderation_log'] as List<dynamic>?)
              ?.map(
                (e) =>
                    ModerationLogEntryDto.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      mediaUrl: json['media_url'] as String?,
    );

Map<String, dynamic> _$PendingPostItemDtoToJson(_PendingPostItemDto instance) =>
    <String, dynamic>{
      'post_uuid': instance.postUuid,
      'title': instance.title,
      'text': instance.text,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'author_username': instance.authorUsername,
      'moderation_log': instance.moderationLog,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'media_url': instance.mediaUrl,
    };
