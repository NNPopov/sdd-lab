import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/update_user_tier/domain/entities/tier_option.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_user_tier_state.freezed.dart';

@freezed
sealed class UpdateUserTierState with _$UpdateUserTierState {
  const factory UpdateUserTierState.initial() = UpdateUserTierInitial;
  const factory UpdateUserTierState.loadingTiers() = UpdateUserTierLoadingTiers;
  const factory UpdateUserTierState.tiersLoaded({
    required List<TierOption> tiers,
    int? selectedTierId,
  }) = UpdateUserTierTiersLoaded;
  const factory UpdateUserTierState.submitting({
    required List<TierOption> tiers,
    required int selectedTierId,
  }) = UpdateUserTierSubmitting;
  const factory UpdateUserTierState.success() = UpdateUserTierSuccess;
  const factory UpdateUserTierState.error(Failure failure) =
      UpdateUserTierError;
}
