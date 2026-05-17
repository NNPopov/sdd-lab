import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_posts_state.freezed.dart';

enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class UserPostsState with _$UserPostsState {
  const factory UserPostsState.initial() = UserPostsInitial;
  const factory UserPostsState.loading() = UserPostsLoading;
  const factory UserPostsState.loaded({
    required List<Post> posts,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = UserPostsLoaded;
  const factory UserPostsState.error(Failure failure) = UserPostsError;
}
