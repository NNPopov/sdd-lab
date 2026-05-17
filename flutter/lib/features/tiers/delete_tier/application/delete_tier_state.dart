import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_tier_state.freezed.dart';

@freezed
sealed class DeleteTierState with _$DeleteTierState {
  const factory DeleteTierState.initial() = DeleteTierInitial;
  const factory DeleteTierState.confirming() = DeleteTierConfirming;
  const factory DeleteTierState.deleting() = DeleteTierDeleting;
  const factory DeleteTierState.success() = DeleteTierSuccess;
  const factory DeleteTierState.notFound() = DeleteTierNotFound;
  const factory DeleteTierState.failure(Failure failure) = DeleteTierFailure;
}
