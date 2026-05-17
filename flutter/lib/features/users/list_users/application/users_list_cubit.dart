import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_application_1/features/users/list_users/domain/usecases/get_users_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

const int _pageSize = 20;

@injectable
class UsersListCubit extends Cubit<UsersListState> {
  UsersListCubit(this._getUsers) : super(const UsersListState.initial());

  final GetUsersUseCase _getUsers;

  Future<void> load() async {
    emit(const UsersListState.loading());
    final result = await _getUsers(perPage: _pageSize);
    result.fold(
      (failure) => emit(UsersListState.error(failure)),
      (paginated) => emit(
        UsersListState.loaded(
          users: paginated.users,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    final result = await _getUsers(perPage: _pageSize);
    result.fold(
      (failure) => emit(UsersListState.error(failure)),
      (paginated) => emit(
        UsersListState.loaded(
          users: paginated.users,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! UsersListLoaded) return;
    if (!current.hasMore) return;
    if (current.loadMoreStatus == LoadMoreStatus.loading) return;

    emit(
      current.copyWith(
        loadMoreStatus: LoadMoreStatus.loading,
        loadMoreError: null,
      ),
    );

    final result = await _getUsers(page: current.page + 1, perPage: _pageSize);
    result.fold(
      (failure) => emit(
        current.copyWith(
          loadMoreStatus: LoadMoreStatus.error,
          loadMoreError: failure,
        ),
      ),
      (paginated) => emit(
        UsersListState.loaded(
          users: [...current.users, ...paginated.users],
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> retryLoadMore() => loadMore();

  Future<void> fetchUsers({int page = 1}) => load();
}
