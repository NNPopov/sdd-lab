import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/create_tier_request_dto.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/dto/tier_dto.dart';
import 'package:flutter_application_1/features/tiers/_shared/data/tiers_api_client.dart';
import 'package:flutter_application_1/features/tiers/create_tier/data/create_tier_adapter.dart';
import 'package:flutter_application_1/features/tiers/create_tier/domain/entities/new_tier_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTiersApiClient extends Mock implements TiersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

DioException _dioError(int statusCode, [Object? data]) => DioException(
  requestOptions: RequestOptions(path: '/tier'),
  response: Response(
    requestOptions: RequestOptions(path: '/tier'),
    statusCode: statusCode,
    data: data,
  ),
  type: DioExceptionType.badResponse,
);

void main() {
  group('CreateTierAdapter.call', () {
    late _MockTiersApiClient apiClient;
    late _MockAppLogger logger;
    late CreateTierAdapter adapter;

    const data = NewTierData(name: 'free');

    setUpAll(() {
      registerFallbackValue(
        const CreateTierRequestDto(name: ''),
      );
    });

    setUp(() {
      apiClient = _MockTiersApiClient();
      logger = _MockAppLogger();
      adapter = CreateTierAdapter(apiClient, logger);
    });

    test('returns Right(Tier) on success', () async {
      when(() => apiClient.createTier(any())).thenAnswer(
        (_) async => const TierDto(id: 1, name: 'free'),
      );

      final result = await adapter(data);

      result.fold(
        (l) => fail('Expected Right, got Left($l)'),
        (r) {
          expect(r.id, 1);
          expect(r.name, 'free');
        },
      );
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      when(
        () => apiClient.createTier(any()),
      ).thenThrow(_dioError(401, {'detail': 'Unauthorized'}));

      final result = await adapter(data);

      result.fold(
        (l) => expect(l, isA<UnauthorizedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      when(
        () => apiClient.createTier(any()),
      ).thenThrow(_dioError(403, {'detail': 'Forbidden'}));

      final result = await adapter(data);

      result.fold(
        (l) => expect(l, isA<ForbiddenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ConflictFailure) on 409', () async {
      when(
        () => apiClient.createTier(any()),
      ).thenThrow(_dioError(409, {'detail': 'Tier already exists'}));

      final result = await adapter(data);

      result.fold(
        (l) {
          expect(l, isA<ConflictFailure>());
          expect((l as ConflictFailure).message, 'Tier already exists');
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(MessageValidationFailure) on 422', () async {
      when(() => apiClient.createTier(any())).thenThrow(
        _dioError(422, {'detail': 'Name already taken'}),
      );

      final result = await adapter(data);

      result.fold(
        (l) {
          expect(l, isA<MessageValidationFailure>());
          expect(
            (l as MessageValidationFailure).message,
            'Name already taken',
          );
        },
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ServerFailure) on 500', () async {
      when(
        () => apiClient.createTier(any()),
      ).thenThrow(_dioError(500, {'detail': 'Internal server error'}));

      final result = await adapter(data);

      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(UnknownFailure) and logs on unexpected exception',
      () async {
        when(() => apiClient.createTier(any())).thenThrow(TypeError());
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
