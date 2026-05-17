import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'moderate_post_state.freezed.dart';

@freezed
sealed class ModeratePostState with _$ModeratePostState {
  const factory ModeratePostState.initial() = ModeratePostInitial;
  const factory ModeratePostState.loading() = ModeratePostLoading;
  const factory ModeratePostState.success(PostStatus newStatus) =
      ModeratePostSuccess;
  const factory ModeratePostState.error(Failure failure) = ModeratePostError;
}
