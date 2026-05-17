// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_log_entry_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModerationLogEntryDto _$ModerationLogEntryDtoFromJson(
  Map<String, dynamic> json,
) => _ModerationLogEntryDto(
  id: (json['id'] as num).toInt(),
  eventType: json['event_type'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  actorUserId: (json['actor_user_id'] as num).toInt(),
  actorUsername: json['actor_username'] as String,
  action: json['action'] as String?,
  message: json['message'] as String?,
);

Map<String, dynamic> _$ModerationLogEntryDtoToJson(
  _ModerationLogEntryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'event_type': instance.eventType,
  'created_at': instance.createdAt.toIso8601String(),
  'actor_user_id': instance.actorUserId,
  'actor_username': instance.actorUsername,
  'action': instance.action,
  'message': instance.message,
};
