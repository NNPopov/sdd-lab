import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'edit_tier_state.freezed.dart';

@freezed
sealed class EditTierState with _$EditTierState {
  const factory EditTierState.initial() = EditTierInitial;
  const factory EditTierState.submitting() = EditTierSubmitting;
  const factory EditTierState.success({required String newName}) =
      EditTierSuccess;
  const factory EditTierState.failure(Failure failure) = EditTierFailure;
}
