import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/create_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/create_user/data/create_user_adapter.dart';
import 'package:flutter_application_1/features/users/create_user/domain/entities/new_user_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  group('CreateUserAdapter.call', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late CreateUserAdapter adapter;

    setUpAll(() {
      registerFallbackValue(
        const CreateUserRequestDto(
          name: '',
          username: '',
          email: '',
          password: '',
        ),
      );
    });

    setUp(() {
      apiClient = _MockUsersApiClient();
      mockLogger = _MockAppLogger();
      adapter = CreateUserAdapter(apiClient, mockLogger);
    });

    test('returns Left(ConflictFailure) on 409 response', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user'),
        response: Response(
          requestOptions: RequestOptions(path: '/user'),
          statusCode: 409,
          data: {'detail': 'Username already exists'},
        ),
        type: DioExceptionType.badResponse,
      );
      when(() => apiClient.createUser(any())).thenThrow(dioException);

      final result = await adapter(
        const NewUserData(
          name: 'Test',
          username: 'test',
          email: 'test@example.com',
          password: 'Password1!',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ConflictFailure>());
          expect(
            (f as ConflictFailure).message,
            'Username already exists',
          );
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns UnknownFailure on unexpected exception', () async {
      when(() => apiClient.createUser(any())).thenThrow(TypeError());

      final result = await adapter(
        const NewUserData(
          name: 'Test',
          username: 'test',
          email: 'test@example.com',
          password: 'Password1!',
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
