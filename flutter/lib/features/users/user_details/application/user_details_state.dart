import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_details_state.freezed.dart';

@freezed
sealed class UserDetailsState with _$UserDetailsState {
  const factory UserDetailsState.initial() = UserDetailsInitial;
  const factory UserDetailsState.loading() = UserDetailsLoading;
  const factory UserDetailsState.loaded(User user) = UserDetailsLoaded;
  const factory UserDetailsState.error(Failure failure) = UserDetailsError;
}
