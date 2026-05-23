import 'package:freezed_annotation/freezed_annotation.dart';

part 'edit_tier_request_dto.freezed.dart';
part 'edit_tier_request_dto.g.dart';

@freezed
sealed class EditTierRequestDto with _$EditTierRequestDto {
  const factory EditTierRequestDto({@JsonKey(name: 'new_name') required String name}) =
      _EditTierRequestDto;

  factory EditTierRequestDto.fromJson(Map<String, dynamic> json) =>
      _$EditTierRequestDtoFromJson(json);
}
