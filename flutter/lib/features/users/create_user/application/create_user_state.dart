import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_user_state.freezed.dart';

@freezed
sealed class CreateUserState with _$CreateUserState {
  const factory CreateUserState.initial() = CreateUserInitial;
  const factory CreateUserState.submitting() = CreateUserSubmitting;
  const factory CreateUserState.success(User user) = CreateUserSuccess;
  const factory CreateUserState.failure(Failure failure) = CreateUserFailure;
}
