import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/paginated_users_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/list_users/data/list_users_adapter.dart';
import 'package:flutter_application_1/features/users/list_users/domain/entities/paginated_users.dart';
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

void main() {
  group('ListUsersAdapter.call', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late ListUsersAdapter adapter;

    setUp(() {
      apiClient = _MockUsersApiClient();
      mockLogger = _MockAppLogger();
      adapter = ListUsersAdapter(apiClient, mockLogger);
    });

    test(
      'returns Right(PaginatedUsers) with hasMore=true on success',
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

        final result = await adapter(page: 1, perPage: 20);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (page) {
            expect(page, isA<PaginatedUsers>());
            expect(page.hasMore, isTrue);
            expect(page.users.length, 1);
          },
        );
      },
    );

    test(
      'returns Right(PaginatedUsers) with hasMore=false on last page',
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

        final result = await adapter(page: 1, perPage: 20);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (page) {
            expect(page, isA<PaginatedUsers>());
            expect(page.hasMore, isFalse);
          },
        );
      },
    );

    test('returns UnknownFailure on unexpected exception', () async {
      when(
        () => apiClient.getUsers(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(TypeError());

      final result = await adapter(page: 1, perPage: 10);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
