import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'erase_db_user_state.freezed.dart';

@freezed
sealed class EraseDbUserState with _$EraseDbUserState {
  const factory EraseDbUserState.initial() = EraseDbUserInitial;
  const factory EraseDbUserState.confirming() = EraseDbUserConfirming;
  const factory EraseDbUserState.deleting() = EraseDbUserDeleting;
  const factory EraseDbUserState.success() = EraseDbUserSuccess;
  const factory EraseDbUserState.failure(Failure failure) = EraseDbUserFailure;
}
