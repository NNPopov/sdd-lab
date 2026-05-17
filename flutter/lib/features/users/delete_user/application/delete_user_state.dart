import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_user_state.freezed.dart';

@freezed
sealed class DeleteUserState with _$DeleteUserState {
  const factory DeleteUserState.initial() = DeleteUserInitial;
  const factory DeleteUserState.confirming() = DeleteUserConfirming;
  const factory DeleteUserState.deleting() = DeleteUserDeleting;
  const factory DeleteUserState.success() = DeleteUserSuccess;
  const factory DeleteUserState.failure(Failure failure) = DeleteUserFailure;
}
