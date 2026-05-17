import 'package:freezed_annotation/freezed_annotation.dart';

part 'tier_option.freezed.dart';

// Bounded context: Tier в контексте update_user_tier — только id и name для dropdown.
// Не использует Tier из features/tiers/ — это другой контекст.
@freezed
sealed class TierOption with _$TierOption {
  const factory TierOption({
    required int id,
    required String name,
  }) = _TierOption;
}
