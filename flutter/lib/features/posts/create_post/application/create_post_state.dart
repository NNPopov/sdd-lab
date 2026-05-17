import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_post_state.freezed.dart';

@freezed
sealed class CreatePostState with _$CreatePostState {
  const factory CreatePostState.initial() = CreatePostInitial;
  const factory CreatePostState.loading() = CreatePostLoading;
  const factory CreatePostState.success() = CreatePostSuccess;
  const factory CreatePostState.error(Failure failure) = CreatePostError;
}
