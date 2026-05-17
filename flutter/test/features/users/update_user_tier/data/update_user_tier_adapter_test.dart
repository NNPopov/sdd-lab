import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/update_user_tier_request_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/update_user_tier_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  group('UpdateUserTierAdapter', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger logger;
    late UpdateUserTierAdapter adapter;

    setUp(() {
      apiClient = _MockUsersApiClient();
      logger = _MockAppLogger();
      adapter = UpdateUserTierAdapter(apiClient, logger);
      registerFallbackValue(const UpdateUserTierRequestDto(tierId: 0));
    });

    test('returns Right(unit) on success', () async {
      when(
        () => apiClient.patchUserTier(any(), any()),
      ).thenAnswer((_) async {});

      final result = await adapter(username: 'alice', tierId: 2);

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      _throwDio(apiClient, 401);

      final result = await adapter(username: 'alice', tierId: 2);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      _throwDio(apiClient, 403);

      final result = await adapter(username: 'alice', tierId: 2);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ForbiddenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      _throwDio(apiClient, 404);

      final result = await adapter(username: 'alice', tierId: 2);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ServerFailure) on 500', () async {
      _throwDio(apiClient, 500);

      final result = await adapter(username: 'alice', tierId: 2);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(UnknownFailure) and calls logger.error with stackTrace '
        'on unexpected exception', () async {
      when(() => apiClient.patchUserTier(any(), any())).thenThrow(
        const FormatException('unexpected'),
      );
      when(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);

      final result = await adapter(username: 'alice', tierId: 2);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnknownFailure>()),
        (_) => fail('Expected Left'),
      );
      verify(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).called(1);
    });
  });
}

void _throwDio(_MockUsersApiClient apiClient, int statusCode) {
  const path = '/user/alice/tier';
  when(() => apiClient.patchUserTier(any(), any())).thenThrow(
    DioException(
      requestOptions: RequestOptions(path: path),
      response: Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
      ),
      type: DioExceptionType.badResponse,
    ),
  );
}
