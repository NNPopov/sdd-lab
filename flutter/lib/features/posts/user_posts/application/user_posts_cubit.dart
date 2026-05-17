import 'dart:async';

import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_state.dart';
import 'package:flutter_application_1/features/posts/user_posts/domain/usecases/user_posts_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

const int _pageSize = 10;

@injectable
class UserPostsCubit extends Cubit<UserPostsState> {
  UserPostsCubit(this._useCase, this._eventBus)
    : super(const UserPostsState.initial()) {
    _sub = _eventBus.stream.listen(_onPostEvent);
  }

  final UserPostsUseCase _useCase;
  final PostEventBus _eventBus;
  late final StreamSubscription<PostEvent> _sub;

  void _onPostEvent(PostEvent event) {
    if (event is PostDeleted) {
      final current = state;
      if (current is UserPostsLoaded) {
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

  Future<void> load(String username) async {
    emit(const UserPostsState.loading());
    final result = await _useCase(
      username: username,
      page: 1,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(UserPostsState.error(failure)),
      (paginated) => emit(
        UserPostsState.loaded(
          posts: paginated.items,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> refresh(String username) async {
    emit(const UserPostsState.loading());
    final result = await _useCase(
      username: username,
      page: 1,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(UserPostsState.error(failure)),
      (paginated) => emit(
        UserPostsState.loaded(
          posts: paginated.items,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMore(String username) async {
    final current = state;
    if (current is! UserPostsLoaded) return;
    if (!current.hasMore) return;
    if (current.loadMoreStatus == LoadMoreStatus.loading) return;

    emit(
      current.copyWith(
        loadMoreStatus: LoadMoreStatus.loading,
        loadMoreError: null,
      ),
    );

    final result = await _useCase(
      username: username,
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
        UserPostsState.loaded(
          posts: [...current.posts, ...paginated.items],
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }
}
