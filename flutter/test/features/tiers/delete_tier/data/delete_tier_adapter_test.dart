import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/delete_tier/data/delete_tier_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTiersApiClient extends Mock implements TiersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

DioException _dioError(int statusCode) => DioException(
  requestOptions: RequestOptions(path: '/tier/1'),
  response: Response(
    requestOptions: RequestOptions(path: '/tier/1'),
    statusCode: statusCode,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  group('DeleteTierAdapter.call', () {
    late _MockTiersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late DeleteTierAdapter adapter;

    setUp(() {
      apiClient = _MockTiersApiClient();
      mockLogger = _MockAppLogger();
      adapter = DeleteTierAdapter(apiClient, mockLogger);
    });

    test('returns Right(unit) on success', () async {
      when(() => apiClient.deleteTier(any())).thenAnswer((_) async {});

      final result = await adapter(1);

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      when(() => apiClient.deleteTier(any())).thenThrow(_dioError(401));

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      when(() => apiClient.deleteTier(any())).thenThrow(_dioError(403));

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ForbiddenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      when(() => apiClient.deleteTier(any())).thenThrow(_dioError(404));

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ServerFailure) on 500', () async {
      when(() => apiClient.deleteTier(any())).thenThrow(_dioError(500));

      final result = await adapter(1);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(UnknownFailure) and logs on unexpected exception',
      () async {
        when(() => apiClient.deleteTier(any())).thenThrow(TypeError());
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
