import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/user_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/user_details/data/get_user_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

const _dto = UserDto(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

const _user = User(
  id: 1,
  name: 'Alice',
  username: 'alice',
  email: 'alice@example.com',
  isModerator: false,
);

void main() {
  group('GetUserAdapter', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late GetUserAdapter adapter;

    setUp(() {
      apiClient = _MockUsersApiClient();
      mockLogger = _MockAppLogger();
      adapter = GetUserAdapter(apiClient, mockLogger);
    });

    test('returns Right(user) on success', () async {
      when(() => apiClient.getUser('alice')).thenAnswer((_) async => _dto);

      final result = await adapter('alice');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (u) {
          expect(u.id, _user.id);
          expect(u.name, _user.name);
          expect(u.username, _user.username);
          expect(u.email, _user.email);
        },
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/nope'),
        response: Response(
          requestOptions: RequestOptions(path: '/user/nope'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      when(() => apiClient.getUser('nope')).thenThrow(dioException);

      final result = await adapter('nope');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NetworkFailure) on network error', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/alice'),
        type: DioExceptionType.connectionTimeout,
        message: 'Connection timeout',
      );
      when(() => apiClient.getUser('alice')).thenThrow(dioException);

      final result = await adapter('alice');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns UnknownFailure on unexpected exception', () async {
      when(() => apiClient.getUser(any())).thenThrow(TypeError());

      final result = await adapter('alice');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
