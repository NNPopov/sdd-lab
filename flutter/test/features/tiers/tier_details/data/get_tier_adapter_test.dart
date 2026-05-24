import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/tier_details/data/dto/tier_detail_dto.dart';
import 'package:flutter_application_1/features/tiers/tier_details/data/get_tier_adapter.dart';
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
  group('GetTierAdapter.call', () {
    late _MockTiersApiClient apiClient;
    late _MockAppLogger logger;
    late GetTierAdapter adapter;

    setUp(() {
      apiClient = _MockTiersApiClient();
      logger = _MockAppLogger();
      adapter = GetTierAdapter(apiClient, logger);
    });

    test('returns Right(TierDetail) on success', () async {
      when(() => apiClient.getTier(any())).thenAnswer(
        (_) async => TierDetailDto(
          id: 1,
          name: 'Free',
          createdAt: DateTime(2026, 4, 25),
        ),
      );

      final result = await adapter(1);

      result.fold(
        (l) => fail('Expected Right, got Left($l)'),
        (r) {
          expect(r.id, 1);
          expect(r.name, 'Free');
        },
      );
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      when(() => apiClient.getTier(any())).thenThrow(_dioError(401));

      final result = await adapter(1);

      result.fold(
        (l) => expect(l, isA<UnauthorizedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      when(() => apiClient.getTier(any())).thenThrow(_dioError(403));

      final result = await adapter(1);

      result.fold(
        (l) => expect(l, isA<ForbiddenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      when(() => apiClient.getTier(any())).thenThrow(_dioError(404));

      final result = await adapter(1);

      result.fold(
        (l) => expect(l, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ServerFailure) on 500', () async {
      when(() => apiClient.getTier(any())).thenThrow(_dioError(500));

      final result = await adapter(1);

      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(UnknownFailure) and logs on unexpected exception',
      () async {
        when(() => apiClient.getTier(any())).thenThrow(TypeError());
        when(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final result = await adapter(1);

        result.fold(
          (l) => expect(l, isA<UnknownFailure>()),
          (_) => fail('Expected Left'),
        );
        verify(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );
  });
}
