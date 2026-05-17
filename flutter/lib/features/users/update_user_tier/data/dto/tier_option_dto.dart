import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tier_option_dto.freezed.dart';
part 'tier_option_dto.g.dart';

@freezed
sealed class TierOptionDto with _$TierOptionDto {
  const factory TierOptionDto({
    required int id,
    @Default('') String name,
  }) = _TierOptionDto;

  factory TierOptionDto.fromJson(Map<String, dynamic> json) =>
      _$TierOptionDtoFromJson(json);
}

extension TierOptionDtoMapper on TierOptionDto {
  TierOption toDomain() => TierOption(id: id, name: name);
}
