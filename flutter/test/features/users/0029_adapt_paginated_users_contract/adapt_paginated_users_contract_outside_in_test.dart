import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/paginated_users_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_cubit.dart';
import 'package:flutter_application_1/features/users/list_users/application/users_list_state.dart';
import 'package:flutter_application_1/features/users/list_users/data/list_users_adapter.dart';
import 'package:flutter_application_1/features/users/list_users/domain/usecases/get_users_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

const _userDto = UserDto(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

const _alice = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

void main() {
  late _MockUsersApiClient apiClient;
  late _MockAppLogger logger;
  late UsersListCubit cubit;

  setUp(() {
    apiClient = _MockUsersApiClient();
    logger = _MockAppLogger();
    final adapter = ListUsersAdapter(apiClient, logger);
    final useCase = GetUsersUseCase(adapter);
    cubit = UsersListCubit(useCase);
  });

  tearDown(() => cubit.close());

  group('0029 · adapt_paginated_users_contract — outside-in', () {
    test(
      'scenario 1: first-page load — new contract parsed, hasMore = true',
      () async {
        when(
          () => apiClient.getUsers(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async => const PaginatedUsersDto(
            items: [_userDto],
            totalCount: 100,
            page: 1,
            itemsPerPage: 20,
          ),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const UsersListState.loading(),
            const UsersListState.loaded(
              users: [_alice],
              page: 1,
              hasMore: true,
            ),
          ]),
        );
        await cubit.load();
        await expectation;

        verifyNever(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        );
      },
    );

    test(
      'scenario 2: single-page load — hasMore = false when '
      'totalCount == page × itemsPerPage',
      () async {
        when(
          () => apiClient.getUsers(
            page: any(named: 'page'),
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer(
          (_) async => const PaginatedUsersDto(
            items: [_userDto],
            totalCount: 20,
            page: 1,
            itemsPerPage: 20,
          ),
        );

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            const UsersListState.loading(),
            const UsersListState.loaded(
              users: [_alice],
              page: 1,
              hasMore: false,
            ),
          ]),
        );
        await cubit.load();
        await expectation;

        verifyNever(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        );
      },
    );
  });
}
