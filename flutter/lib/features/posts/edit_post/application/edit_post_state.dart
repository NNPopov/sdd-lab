import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'edit_post_state.freezed.dart';

@freezed
sealed class EditPostState with _$EditPostState {
  const factory EditPostState.initial() = EditPostInitial;
  const factory EditPostState.loading() = EditPostLoading;
  const factory EditPostState.success() = EditPostSuccess;
  const factory EditPostState.error(Failure failure) = EditPostError;
}
