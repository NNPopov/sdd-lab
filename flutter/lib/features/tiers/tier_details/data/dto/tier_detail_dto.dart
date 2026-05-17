import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tier_detail_dto.freezed.dart';
part 'tier_detail_dto.g.dart';

@freezed
sealed class TierDetailDto with _$TierDetailDto {
  const factory TierDetailDto({
    required int id,
    @Default('') String name,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _TierDetailDto;

  factory TierDetailDto.fromJson(Map<String, dynamic> json) =>
      _$TierDetailDtoFromJson(json);
}

extension TierDetailDtoX on TierDetailDto {
  TierDetail toDomain() => TierDetail(
    id: id,
    name: name,
    createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}
