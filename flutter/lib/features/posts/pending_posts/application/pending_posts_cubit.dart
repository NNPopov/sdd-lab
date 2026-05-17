import 'dart:async';

import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_state.dart';
import 'package:flutter_application_1/features/posts/pending_posts/domain/usecases/get_pending_posts_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

const int _pageSize = 10;

@injectable
class PendingPostsCubit extends Cubit<PendingPostsState> {
  PendingPostsCubit(this._useCase, this._eventBus)
    : super(const PendingPostsState.initial()) {
    _sub = _eventBus.stream.listen(_onPostEvent);
  }

  final GetPendingPostsUseCase _useCase;
  final PostEventBus _eventBus;
  late final StreamSubscription<PostEvent> _sub;

  void _onPostEvent(PostEvent event) {
    if (event is PostModeratedEvent) {
      final current = state;
      if (current is PendingPostsLoaded) {
        emit(
          current.copyWith(
            items: current.items
                .where((p) => p.postUuid != event.postUuid)
                .toList(),
          ),
        );
      }
    }
    if (event is PostRevisedEvent) {
      refresh();
    }
  }

  @override
  Future<void> close() {
    unawaited(_sub.cancel());
    return super.close();
  }

  Future<void> load() async {
    emit(const PendingPostsState.loading());
    final result = await _useCase(page: 1, perPage: _pageSize);
    result.fold(
      (failure) => emit(PendingPostsState.error(failure)),
      (paginated) => emit(
        PendingPostsState.loaded(
          items: paginated.items,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    emit(const PendingPostsState.loading());
    final result = await _useCase(page: 1, perPage: _pageSize);
    result.fold(
      (failure) => emit(PendingPostsState.error(failure)),
      (paginated) => emit(
        PendingPostsState.loaded(
          items: paginated.items,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! PendingPostsLoaded) return;
    if (!current.hasMore) return;
    if (current.loadMoreStatus == LoadMoreStatus.loading) return;

    emit(
      current.copyWith(
        loadMoreStatus: LoadMoreStatus.loading,
        loadMoreError: null,
      ),
    );

    final result = await _useCase(
      page: current.page + 1,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(
        current.copyWith(
          loadMoreStatus: LoadMoreStatus.error,
          loadMoreError: failure,
        ),
      ),
      (paginated) => emit(
        PendingPostsState.loaded(
          items: [...current.items, ...paginated.items],
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }
}
