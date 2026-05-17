// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_log_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ModerationLogResponseDto _$ModerationLogResponseDtoFromJson(
  Map<String, dynamic> json,
) => _ModerationLogResponseDto(
  items: (json['items'] as List<dynamic>)
      .map((e) => ModerationLogEntryDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ModerationLogResponseDtoToJson(
  _ModerationLogResponseDto instance,
) => <String, dynamic>{'items': instance.items};
