import 'package:flutter_application_1/features/users/update_user_tier/data/dto/tier_option_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_tier_options_dto.freezed.dart';
part 'paginated_tier_options_dto.g.dart';

@freezed
sealed class PaginatedTierOptionsDto with _$PaginatedTierOptionsDto {
  const factory PaginatedTierOptionsDto({
    @JsonKey(name: 'items') @Default([]) List<TierOptionDto> items,
    @JsonKey(name: 'total_count') @Default(0) int totalCount,
    @JsonKey(name: 'has_more') @Default(false) bool hasMore,
  }) = _PaginatedTierOptionsDto;

  factory PaginatedTierOptionsDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTierOptionsDtoFromJson(json);
}
