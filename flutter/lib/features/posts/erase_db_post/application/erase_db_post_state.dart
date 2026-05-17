import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'erase_db_post_state.freezed.dart';

@freezed
sealed class EraseDbPostState with _$EraseDbPostState {
  const factory EraseDbPostState.initial() = EraseDbPostInitial;
  const factory EraseDbPostState.confirming() = EraseDbPostConfirming;
  const factory EraseDbPostState.deleting() = EraseDbPostDeleting;
  const factory EraseDbPostState.success() = EraseDbPostSuccess;
  const factory EraseDbPostState.failure(Failure failure) = EraseDbPostFailure;
}
