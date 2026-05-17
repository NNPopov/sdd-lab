import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_user_tier_state.freezed.dart';

@freezed
sealed class GetUserTierState with _$GetUserTierState {
  const factory GetUserTierState.initial() = GetUserTierInitial;
  const factory GetUserTierState.loading() = GetUserTierLoading;
  const factory GetUserTierState.loaded(UserTier tier) = GetUserTierLoaded;
  const factory GetUserTierState.error(Failure failure) = GetUserTierError;
}
