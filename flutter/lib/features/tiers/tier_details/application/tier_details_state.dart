import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/tiers/tier_details/domain/entities/tier_detail.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tier_details_state.freezed.dart';

@freezed
sealed class TierDetailsState with _$TierDetailsState {
  const factory TierDetailsState.initial() = TierDetailsInitial;
  const factory TierDetailsState.loading() = TierDetailsLoading;
  const factory TierDetailsState.loaded({required TierDetail tier}) =
      TierDetailsLoaded;
  const factory TierDetailsState.error({required Failure failure}) =
      TierDetailsError;
}
