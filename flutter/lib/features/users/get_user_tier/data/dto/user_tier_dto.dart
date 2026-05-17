import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';

part 'user_tier_dto.freezed.dart';
part 'user_tier_dto.g.dart';

@freezed
sealed class UserTierDto with _$UserTierDto {
  const factory UserTierDto({
    @JsonKey(name: 'tier_id') required int tierId,
    @JsonKey(name: 'tier_name') required String tierName,
    @JsonKey(name: 'tier_created_at') DateTime? tierCreatedAt,
  }) = _UserTierDto;

  factory UserTierDto.fromJson(Map<String, dynamic> json) =>
      _$UserTierDtoFromJson(json);
}

extension UserTierDtoMapper on UserTierDto {
  UserTier toDomain() => UserTier(
    tierName: tierName,
    tierCreatedAt: tierCreatedAt,
  );
}
