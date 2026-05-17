import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'edit_user_state.freezed.dart';

@freezed
sealed class EditUserState with _$EditUserState {
  const factory EditUserState.initial() = EditUserInitial;
  const factory EditUserState.loadingInitialData() = EditUserLoadingInitialData;
  const factory EditUserState.loaded(User original) = EditUserLoaded;
  const factory EditUserState.submitting(User original) = EditUserSubmitting;
  const factory EditUserState.success(User user) = EditUserSuccess;
  const factory EditUserState.loadError(Failure failure) = EditUserLoadError;
  const factory EditUserState.submitError(
    User original,
    Failure failure,
  ) = EditUserSubmitError;
}
