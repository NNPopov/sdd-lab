import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/list_users/domain/entities/paginated_users.dart';
import 'package:flutter_application_1/features/users/list_users/domain/ports/list_users_port.dart';
import 'package:flutter_application_1/features/users/list_users/domain/usecases/get_users_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListUsersPort extends Mock implements ListUsersPort {}

void main() {
  group('GetUsersUseCase', () {
    late _MockListUsersPort port;
    late GetUsersUseCase useCase;

    setUp(() {
      port = _MockListUsersPort();
      useCase = GetUsersUseCase(port);
    });

    test('returns PaginatedUsers on success', () async {
      const users = [
        User(
          id: 1,
          name: 'Alice',
          username: 'alice',
          email: 'a@a.com',
          isModerator: false,
        ),
      ];
      const paginated = PaginatedUsers(
        users: users,
        totalCount: 1,
        page: 1,
        itemsPerPage: 10,
      );
      when(
        () => port(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => const Right(paginated));

      final result = await useCase();

      result.fold(
        (l) => fail('Expected Right, got Left($l)'),
        (r) {
          expect(r.users.length, 1);
          expect(r.users.first.id, 1);
          expect(r.hasMore, isFalse);
        },
      );
    });

    test('returns Failure on network error', () async {
      const failure = Failure.network(message: 'timeout');
      when(
        () => port(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase();

      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (r) => fail('Expected Left, got Right($r)'),
      );
    });
  });
}
