import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_post_state.freezed.dart';

@freezed
sealed class DeletePostState with _$DeletePostState {
  const factory DeletePostState.initial() = DeletePostInitial;
  const factory DeletePostState.confirming() = DeletePostConfirming;
  const factory DeletePostState.deleting() = DeletePostDeleting;
  const factory DeletePostState.success() = DeletePostSuccess;
  const factory DeletePostState.failure(Failure failure) = DeletePostFailure;
}
