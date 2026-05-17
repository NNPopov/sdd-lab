import 'dart:async';

import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_state.dart';
import 'package:flutter_application_1/features/posts/list_posts/domain/usecases/list_posts_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

const int _pageSize = 10;

@injectable
class ListPostsCubit extends Cubit<ListPostsState> {
  ListPostsCubit(this._useCase, this._eventBus)
    : super(const ListPostsState.initial()) {
    _sub = _eventBus.stream.listen(_onPostEvent);
  }

  final ListPostsUseCase _useCase;
  final PostEventBus _eventBus;
  late final StreamSubscription<PostEvent> _sub;

  void _onPostEvent(PostEvent event) {
    if (event is PostDeleted) {
      final current = state;
      if (current is ListPostsLoaded) {
        emit(
          current.copyWith(
            posts: current.posts.where((p) => p.id != event.id).toList(),
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    unawaited(_sub.cancel());
    return super.close();
  }

  Future<void> load() async {
    emit(const ListPostsState.loading());
    final result = await _useCase(page: 1, perPage: _pageSize);
    result.fold(
      (failure) => emit(ListPostsState.error(failure)),
      (paginated) => emit(
        ListPostsState.loaded(
          posts: paginated.items,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    emit(const ListPostsState.loading());
    final result = await _useCase(page: 1, perPage: _pageSize);
    result.fold(
      (failure) => emit(ListPostsState.error(failure)),
      (paginated) => emit(
        ListPostsState.loaded(
          posts: paginated.items,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ListPostsLoaded) return;
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
        ListPostsState.loaded(
          posts: [...current.posts, ...paginated.items],
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }
}
