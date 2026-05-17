import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'list_posts_state.freezed.dart';

enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class ListPostsState with _$ListPostsState {
  const factory ListPostsState.initial() = ListPostsInitial;
  const factory ListPostsState.loading() = ListPostsLoading;
  const factory ListPostsState.loaded({
    required List<Post> posts,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = ListPostsLoaded;
  const factory ListPostsState.error(Failure failure) = ListPostsError;
}
