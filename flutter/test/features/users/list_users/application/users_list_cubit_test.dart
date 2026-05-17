import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_application_1/features/users/list_users/domain/entities/paginated_users.dart';
import 'package:flutter_application_1/features/users/list_users/domain/usecases/get_users_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetUsersUseCase extends Mock implements GetUsersUseCase {}

const _users1 = [
  User(
    id: 1,
    name: 'Alice',
    username: 'alice',
    email: 'a@a.com',
    isModerator: false,
  ),
  User(
    id: 2,
    name: 'Bob',
    username: 'bob',
    email: 'b@b.com',
    isModerator: false,
  ),
];

const _users2 = [
  User(
    id: 3,
    name: 'Carol',
    username: 'carol',
    email: 'c@c.com',
    isModerator: false,
  ),
];

PaginatedUsers _page(
  List<User> users, {
  int page = 1,
  int totalCount = 100,
}) => PaginatedUsers(
  users: users,
  totalCount: totalCount,
  page: page,
  itemsPerPage: 20,
);

void main() {
  group('UsersListCubit', () {
    late _MockGetUsersUseCase useCase;
    late UsersListCubit cubit;

    setUp(() {
      useCase = _MockGetUsersUseCase();
      cubit = UsersListCubit(useCase);
    });

    tearDown(() => cubit.close());

    group('load', () {
      blocTest<UsersListCubit, UsersListState>(
        'emits [loading, loaded] on success',
        build: () {
          when(
            () => useCase(perPage: 20),
          ).thenAnswer((_) async => Right(_page(_users1)));
          return cubit;
        },
        act: (c) => c.load(),
        expect: () => [
          const UsersListState.loading(),
          const UsersListState.loaded(
            users: _users1,
            page: 1,
            hasMore: true,
          ),
        ],
      );

      blocTest<UsersListCubit, UsersListState>(
        'emits [loading, error] on failure',
        build: () {
          when(() => useCase(perPage: 20)).thenAnswer(
            (_) async => const Left(Failure.network(message: 'timeout')),
          );
          return cubit;
        },
        act: (c) => c.load(),
        expect: () => [
          const UsersListState.loading(),
          const UsersListState.error(
            Failure.network(message: 'timeout'),
          ),
        ],
      );
    });

    group('loadMore', () {
      blocTest<UsersListCubit, UsersListState>(
        'appends users and advances page on success',
        build: () {
          when(() => useCase(page: 2, perPage: 20)).thenAnswer(
            (_) async => Right(_page(_users2, page: 2, totalCount: 40)),
          );
          return cubit;
        },
        seed: () => const UsersListState.loaded(
          users: _users1,
          page: 1,
          hasMore: true,
        ),
        act: (c) => c.loadMore(),
        expect: () => [
          const UsersListState.loaded(
            users: _users1,
            page: 1,
            hasMore: true,
            loadMoreStatus: LoadMoreStatus.loading,
          ),
          const UsersListState.loaded(
            users: [..._users1, ..._users2],
            page: 2,
            hasMore: false,
          ),
        ],
      );

      blocTest<UsersListCubit, UsersListState>(
        'does nothing when hasMore is false',
        build: () => cubit,
        seed: () => const UsersListState.loaded(
          users: _users1,
          page: 1,
          hasMore: false,
        ),
        act: (c) => c.loadMore(),
        expect: () => <UsersListState>[],
      );

      blocTest<UsersListCubit, UsersListState>(
        'does nothing when already loading more',
        build: () => cubit,
        seed: () => const UsersListState.loaded(
          users: _users1,
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
        act: (c) => c.loadMore(),
        expect: () => <UsersListState>[],
      );

      blocTest<UsersListCubit, UsersListState>(
        'emits error status on failure',
        build: () {
          when(() => useCase(page: 2, perPage: 20)).thenAnswer(
            (_) async => const Left(Failure.network(message: 'fail')),
          );
          return cubit;
        },
        seed: () => const UsersListState.loaded(
          users: _users1,
          page: 1,
          hasMore: true,
        ),
        act: (c) => c.loadMore(),
        expect: () => [
          const UsersListState.loaded(
            users: _users1,
            page: 1,
            hasMore: true,
            loadMoreStatus: LoadMoreStatus.loading,
          ),
          const UsersListState.loaded(
            users: _users1,
            page: 1,
            hasMore: true,
            loadMoreStatus: LoadMoreStatus.error,
            loadMoreError: Failure.network(message: 'fail'),
          ),
        ],
      );

      blocTest<UsersListCubit, UsersListState>(
        'retryLoadMore retries after error',
        build: () {
          when(() => useCase(page: 2, perPage: 20)).thenAnswer(
            (_) async => Right(_page(_users2, page: 2, totalCount: 40)),
          );
          return cubit;
        },
        seed: () => const UsersListState.loaded(
          users: _users1,
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.error,
          loadMoreError: Failure.network(message: 'fail'),
        ),
        act: (c) => c.retryLoadMore(),
        expect: () => [
          const UsersListState.loaded(
            users: _users1,
            page: 1,
            hasMore: true,
            loadMoreStatus: LoadMoreStatus.loading,
          ),
          const UsersListState.loaded(
            users: [..._users1, ..._users2],
            page: 2,
            hasMore: false,
          ),
        ],
      );
    });

    group('refresh', () {
      blocTest<UsersListCubit, UsersListState>(
        'reloads page 1 without emitting loading state',
        build: () {
          when(() => useCase(perPage: 20)).thenAnswer(
            (_) async => Right(_page(_users1, totalCount: 20)),
          );
          return cubit;
        },
        seed: () => const UsersListState.loaded(
          users: _users2,
          page: 3,
          hasMore: true,
        ),
        act: (c) => c.refresh(),
        expect: () => [
          const UsersListState.loaded(
            users: _users1,
            page: 1,
            hasMore: false,
          ),
        ],
      );
    });
  });
}
