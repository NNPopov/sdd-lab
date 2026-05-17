import 'package:flutter_application_1/core/rbac/permission_cubit.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/application/list_tiers_state.dart';
import 'package:flutter_application_1/features/tiers/list_tiers/domain/usecases/list_tiers_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

const int _pageSize = 10;

@injectable
class ListTiersCubit extends Cubit<ListTiersState> {
  ListTiersCubit(this._useCase, this._permissionCubit)
    : super(const ListTiersState.initial());

  final ListTiersUseCase _useCase;
  final PermissionCubit _permissionCubit;

  Future<void> load() async {
    emit(const ListTiersState.loading());
    final result = await _useCase(
      permissions: _permissionCubit.state,
      page: 1,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(ListTiersState.error(failure)),
      (paginated) => emit(
        ListTiersState.loaded(
          tiers: paginated.tiers,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    final result = await _useCase(
      permissions: _permissionCubit.state,
      page: 1,
      perPage: _pageSize,
    );
    result.fold(
      (failure) => emit(ListTiersState.error(failure)),
      (paginated) => emit(
        ListTiersState.loaded(
          tiers: paginated.tiers,
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ListTiersLoaded) return;
    if (!current.hasMore) return;
    if (current.loadMoreStatus == LoadMoreStatus.loading) return;

    emit(
      current.copyWith(
        loadMoreStatus: LoadMoreStatus.loading,
        loadMoreError: null,
      ),
    );

    final result = await _useCase(
      permissions: _permissionCubit.state,
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
        ListTiersState.loaded(
          tiers: [...current.tiers, ...paginated.tiers],
          page: paginated.page,
          hasMore: paginated.hasMore,
        ),
      ),
    );
  }

  Future<void> retryLoadMore() => loadMore();
}
