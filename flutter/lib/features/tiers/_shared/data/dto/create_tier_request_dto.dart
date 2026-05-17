import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_tier_request_dto.freezed.dart';
part 'create_tier_request_dto.g.dart';

@freezed
sealed class CreateTierRequestDto with _$CreateTierRequestDto {
  const factory CreateTierRequestDto({
    required String name,
  }) = _CreateTierRequestDto;

  factory CreateTierRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTierRequestDtoFromJson(json);
}
