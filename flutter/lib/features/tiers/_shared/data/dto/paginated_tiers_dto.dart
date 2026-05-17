import 'package:flutter_application_1/features/tiers/_shared/data/dto/tier_dto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_tiers_dto.freezed.dart';
part 'paginated_tiers_dto.g.dart';

@freezed
sealed class PaginatedTiersDto with _$PaginatedTiersDto {
  const factory PaginatedTiersDto({
    required List<TierDto> data,
    @JsonKey(name: 'total_count') required int totalCount,
    @JsonKey(name: 'has_more') required bool hasMore,
    required int page,
    @JsonKey(name: 'items_per_page') required int itemsPerPage,
  }) = _PaginatedTiersDto;

  factory PaginatedTiersDto.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTiersDtoFromJson(json);
}
