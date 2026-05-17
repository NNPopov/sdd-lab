import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'assign_moderator_state.freezed.dart';

@freezed
sealed class AssignModeratorState with _$AssignModeratorState {
  const factory AssignModeratorState.initial() = AssignModeratorInitial;
  const factory AssignModeratorState.loading() = AssignModeratorLoading;
  const factory AssignModeratorState.success({
    required bool isModerator,
  }) = AssignModeratorSuccess;
  const factory AssignModeratorState.error(Failure failure) =
      AssignModeratorError;
}
