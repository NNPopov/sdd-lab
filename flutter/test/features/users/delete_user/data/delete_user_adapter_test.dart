import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/delete_user/data/delete_user_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

DioException _dioError(int statusCode, [Object? detail]) => DioException(
  requestOptions: RequestOptions(path: '/user/testuser'),
  response: Response(
    requestOptions: RequestOptions(path: '/user/testuser'),
    statusCode: statusCode,
    data: detail != null ? {'detail': detail} : null,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  group('DeleteUserAdapter.call', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late DeleteUserAdapter adapter;

    setUp(() {
      apiClient = _MockUsersApiClient();
      mockLogger = _MockAppLogger();
      adapter = DeleteUserAdapter(apiClient, mockLogger);
    });

    test('returns Right(unit) on 200 success', () async {
      when(() => apiClient.deleteUser(any())).thenAnswer((_) async {});

      final result = await adapter(1);

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      when(
        () => apiClient.deleteUser(any()),
      ).thenThrow(_dioError(403, 'Forbidden'));

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<ForbiddenFailure>());
          expect((f as ForbiddenFailure).message, 'Forbidden');
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      when(
        () => apiClient.deleteUser(any()),
      ).thenThrow(_dioError(401, 'Session expired'));

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) {
          expect(f, isA<UnauthorizedFailure>());
          expect((f as UnauthorizedFailure).message, 'Session expired');
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      when(
        () => apiClient.deleteUser(any()),
      ).thenThrow(_dioError(404, 'User not found'));

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(UnknownFailure) and logs on unexpected TypeError',
      () async {
        when(() => apiClient.deleteUser(any())).thenThrow(TypeError());
        when(
          () => mockLogger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final result = await adapter(1);

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<UnknownFailure>()),
          (_) => fail('Expected Left'),
        );
        verify(
          () => mockLogger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );
  });
}
