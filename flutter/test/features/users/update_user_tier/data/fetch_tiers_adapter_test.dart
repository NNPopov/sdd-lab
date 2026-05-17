import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/paginated_tier_options_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/dto/tier_option_dto.dart';
import 'package:flutter_application_1/features/users/update_user_tier/data/fetch_tiers_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

const _dto1 = TierOptionDto(id: 1, name: 'Free');
const _dto2 = TierOptionDto(id: 2, name: 'Pro');

void main() {
  group('FetchTiersAdapter', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger logger;
    late FetchTiersAdapter adapter;

    setUp(() {
      apiClient = _MockUsersApiClient();
      logger = _MockAppLogger();
      adapter = FetchTiersAdapter(apiClient, logger);
    });

    test('returns Right([TierOption, ...]) on success', () async {
      when(() => apiClient.getTiersForSelection()).thenAnswer(
        (_) async => const PaginatedTierOptionsDto(data: [_dto1, _dto2]),
      );

      final result = await adapter();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (tiers) {
          expect(tiers.length, 2);
          expect(tiers[0].id, 1);
          expect(tiers[0].name, 'Free');
          expect(tiers[1].id, 2);
          expect(tiers[1].name, 'Pro');
        },
      );
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      _throwDio(apiClient, 401);

      final result = await adapter();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ServerFailure) on 500', () async {
      _throwDio(apiClient, 500);

      final result = await adapter();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(UnknownFailure) and calls logger.error with stackTrace '
        'on unexpected exception', () async {
      when(() => apiClient.getTiersForSelection()).thenThrow(
        const FormatException('bad json'),
      );
      when(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).thenReturn(null);

      final result = await adapter();

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
  const path = '/tiers';
  when(() => apiClient.getTiersForSelection()).thenThrow(
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
