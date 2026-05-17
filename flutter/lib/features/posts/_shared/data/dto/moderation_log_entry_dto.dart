import 'package:freezed_annotation/freezed_annotation.dart';

part 'moderation_log_entry_dto.freezed.dart';
part 'moderation_log_entry_dto.g.dart';

@freezed
sealed class ModerationLogEntryDto with _$ModerationLogEntryDto {
  const factory ModerationLogEntryDto({
    required int id,
    @JsonKey(name: 'event_type') required String eventType,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'actor_user_id') required int actorUserId,
    @JsonKey(name: 'actor_username') required String actorUsername,
    String? action,
    String? message,
  }) = _ModerationLogEntryDto;

  factory ModerationLogEntryDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationLogEntryDtoFromJson(json);
}
