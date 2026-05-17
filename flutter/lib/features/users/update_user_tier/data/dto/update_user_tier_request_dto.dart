import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_user_tier_request_dto.freezed.dart';
part 'update_user_tier_request_dto.g.dart';

@freezed
sealed class UpdateUserTierRequestDto with _$UpdateUserTierRequestDto {
  const factory UpdateUserTierRequestDto({
    @JsonKey(name: 'tier_id') required int tierId,
  }) = _UpdateUserTierRequestDto;

  factory UpdateUserTierRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserTierRequestDtoFromJson(json);
}
