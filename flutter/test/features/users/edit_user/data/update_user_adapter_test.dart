import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/dto/update_user_request_dto.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/_shared/domain/entities/user.dart';
import 'package:flutter_application_1/features/users/edit_user/data/update_user_adapter.dart';
import 'package:flutter_application_1/features/users/edit_user/domain/entities/user_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  group('UpdateUserAdapter.call', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late UpdateUserAdapter adapter;

    const original = User(
      id: 1,
      name: 'Old Name',
      username: 'testuser',
      email: 'test@example.com',
      isModerator: false,
    );

    const update = UserUpdate(name: 'New Name');

    setUpAll(() {
      registerFallbackValue(
        const UpdateUserRequestDto(name: 'fallback'),
      );
    });

    setUp(() {
      apiClient = _MockUsersApiClient();
      mockLogger = _MockAppLogger();
      adapter = UpdateUserAdapter(apiClient, mockLogger);
    });

    test('returns Right(User) with applied update on 200 success', () async {
      when(() => apiClient.updateUser(any(), any())).thenAnswer((_) async {});

      final result = await adapter(original: original, update: update);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (u) {
          expect(u.name, 'New Name');
          expect(u.username, original.username);
          expect(u.email, original.email);
          expect(u.id, original.id);
        },
      );
      // PATCH path identity is the integer id, not the handle.
      verify(() => apiClient.updateUser(original.id, any())).called(1);
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/testuser'),
        response: Response(
          requestOptions: RequestOptions(path: '/user/testuser'),
          statusCode: 401,
          data: {'detail': 'Unauthorized'},
        ),
        type: DioExceptionType.badResponse,
      );
      when(() => apiClient.updateUser(any(), any())).thenThrow(dioException);

      final result = await adapter(original: original, update: update);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<UnauthorizedFailure>());
          expect((f as UnauthorizedFailure).message, 'Unauthorized');
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/testuser'),
        response: Response(
          requestOptions: RequestOptions(path: '/user/testuser'),
          statusCode: 403,
          data: {'detail': 'Forbidden'},
        ),
        type: DioExceptionType.badResponse,
      );
      when(() => apiClient.updateUser(any(), any())).thenThrow(dioException);

      final result = await adapter(original: original, update: update);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ForbiddenFailure>());
          expect((f as ForbiddenFailure).message, 'Forbidden');
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ValidationFailure) with parsed fields on 422', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/testuser'),
        response: Response(
          requestOptions: RequestOptions(path: '/user/testuser'),
          statusCode: 422,
          data: {
            'detail': [
              {
                'loc': ['body', 'email'],
                'msg': 'Invalid email',
                'type': 'value_error',
              },
            ],
          },
        ),
        type: DioExceptionType.badResponse,
      );
      when(() => apiClient.updateUser(any(), any())).thenThrow(dioException);

      final result = await adapter(original: original, update: update);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<FieldValidationFailure>());
          expect(
            (f as FieldValidationFailure).fields,
            {'email': 'Invalid email'},
          );
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ConflictFailure) on 409', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/testuser'),
        response: Response(
          requestOptions: RequestOptions(path: '/user/testuser'),
          statusCode: 409,
          data: {'detail': 'Username already taken'},
        ),
        type: DioExceptionType.badResponse,
      );
      when(() => apiClient.updateUser(any(), any())).thenThrow(dioException);

      final result = await adapter(original: original, update: update);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ConflictFailure>());
          expect((f as ConflictFailure).message, 'Username already taken');
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/user/testuser'),
        response: Response(
          requestOptions: RequestOptions(path: '/user/testuser'),
          statusCode: 404,
          data: {'detail': 'Not found'},
        ),
        type: DioExceptionType.badResponse,
      );
      when(() => apiClient.updateUser(any(), any())).thenThrow(dioException);

      final result = await adapter(original: original, update: update);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns UnknownFailure on unexpected exception', () async {
      when(() => apiClient.updateUser(any(), any())).thenThrow(TypeError());

      final result = await adapter(original: original, update: update);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
