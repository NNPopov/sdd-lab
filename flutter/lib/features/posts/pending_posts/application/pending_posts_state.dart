import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_posts_state.freezed.dart';

enum LoadMoreStatus { idle, loading, error }

@freezed
sealed class PendingPostsState with _$PendingPostsState {
  const factory PendingPostsState.initial() = PendingPostsInitial;
  const factory PendingPostsState.loading() = PendingPostsLoading;
  const factory PendingPostsState.loaded({
    required List<PendingPostItem> items,
    required int page,
    required bool hasMore,
    @Default(LoadMoreStatus.idle) LoadMoreStatus loadMoreStatus,
    Failure? loadMoreError,
  }) = PendingPostsLoaded;
  const factory PendingPostsState.error(Failure failure) = PendingPostsError;
}
