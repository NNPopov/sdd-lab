import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/_shared/domain/entities/tier.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_tier_state.freezed.dart';

@freezed
sealed class CreateTierState with _$CreateTierState {
  const factory CreateTierState.idle() = CreateTierIdle;
  const factory CreateTierState.submitting() = CreateTierSubmitting;
  const factory CreateTierState.success(Tier tier) = CreateTierSuccess;
  const factory CreateTierState.failure(Failure failure) = CreateTierFailure;
}
