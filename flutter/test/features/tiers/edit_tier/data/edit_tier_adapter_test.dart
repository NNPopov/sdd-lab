import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/data/dto/edit_tier_request_dto.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/data/edit_tier_adapter.dart';
import 'package:flutter_application_1/features/tiers/edit_tier/domain/entities/edit_tier_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTiersApiClient extends Mock implements TiersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

DioException _dioError(int statusCode, [Object? data]) => DioException(
  requestOptions: RequestOptions(path: '/tier/1'),
  response: Response(
    requestOptions: RequestOptions(path: '/tier/1'),
    statusCode: statusCode,
    data: data,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  group('EditTierAdapter.call', () {
    late _MockTiersApiClient apiClient;
    late _MockAppLogger logger;
    late EditTierAdapter adapter;

    const data = EditTierData(tierId: 1, name: 'basic');

    setUpAll(() {
      registerFallbackValue(const EditTierRequestDto(name: ''));
    });

    setUp(() {
      apiClient = _MockTiersApiClient();
      logger = _MockAppLogger();
      adapter = EditTierAdapter(apiClient, logger);
    });

    test('returns Right(unit) on 200', () async {
      when(() => apiClient.patchTier(any(), any())).thenAnswer((_) async {});

      final result = await adapter(data);

      result.fold(
        (l) => fail('Expected Right, got Left($l)'),
        (r) => expect(r, unit),
      );
      verify(
        () => apiClient.patchTier(1, const EditTierRequestDto(name: 'basic')),
      ).called(1);
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      when(() => apiClient.patchTier(any(), any())).thenThrow(_dioError(404));

      final result = await adapter(data);

      result.fold(
        (l) => expect(l, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      when(
        () => apiClient.patchTier(any(), any()),
      ).thenThrow(_dioError(403, {'detail': 'Forbidden'}));

      final result = await adapter(data);

      result.fold(
        (l) => expect(l, isA<ForbiddenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(UnknownFailure) and logs on unexpected exception',
      () async {
        when(() => apiClient.patchTier(any(), any())).thenThrow(TypeError());
        when(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final result = await adapter(data);

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
