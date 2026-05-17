import 'package:flutter_application_1/features/posts/_shared/data/dto/moderation_log_entry_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'moderation_log_response_dto.freezed.dart';
part 'moderation_log_response_dto.g.dart';

@freezed
sealed class ModerationLogResponseDto with _$ModerationLogResponseDto {
  const factory ModerationLogResponseDto({
    required List<ModerationLogEntryDto> items,
  }) = _ModerationLogResponseDto;

  factory ModerationLogResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ModerationLogResponseDtoFromJson(json);
}
