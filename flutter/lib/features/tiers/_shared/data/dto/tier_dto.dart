import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tier_dto.freezed.dart';
part 'tier_dto.g.dart';

@freezed
sealed class TierDto with _$TierDto {
  const factory TierDto({
    required int id,
    @Default('') String name,
  }) = _TierDto;

  factory TierDto.fromJson(Map<String, dynamic> json) =>
      _$TierDtoFromJson(json);
}

extension TierDtoX on TierDto {
  Tier toDomain() => Tier(id: id, name: name);
}
