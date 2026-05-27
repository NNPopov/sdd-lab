import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/get_user_tier/data/dto/user_tier_dto.dart';
import 'package:flutter_application_1/features/users/get_user_tier/data/get_user_tier_adapter.dart';
import 'package:flutter_application_1/features/users/get_user_tier/domain/entities/user_tier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

final _createdAt = DateTime.utc(2026, 4, 25, 15, 55, 28);

const _dtoWithDate = UserTierDto(
  tierId: 1,
  tierName: 'Free',
);

void main() {
  group('GetUserTierAdapter', () {
    late _MockUsersApiClient apiClient;
    late _MockAppLogger mockLogger;
    late GetUserTierAdapter adapter;

    setUp(() {
      apiClient = _MockUsersApiClient();
      mockLogger = _MockAppLogger();
      adapter = GetUserTierAdapter(apiClient, mockLogger);
    });

    test('returns Right(UserTier) with date on success', () async {
      final dto = UserTierDto(
        tierId: 1,
        tierName: 'Free',
        tierCreatedAt: _createdAt,
      );
      when(() => apiClient.getUserTier(7)).thenAnswer((_) async => dto);

      final result = await adapter(7);

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (tier) {
          expect(tier.tierName, 'Free');
          expect(tier.tierCreatedAt, _createdAt);
        },
      );
    });

    test(
      'returns Right(UserTier) without date when tier_created_at is null',
      () async {
        when(
          () => apiClient.getUserTier(7),
        ).thenAnswer((_) async => _dtoWithDate);

        final result = await adapter(7);

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (tier) {
            expect(tier, isA<UserTier>());
            expect(tier.tierName, 'Free');
            expect(tier.tierCreatedAt, isNull);
          },
        );
      },
    );

    test('returns Left(UnauthorizedFailure) on 401', () async {
      _throwDio(apiClient, 401);

      final result = await adapter(7);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      _throwDio(apiClient, 403);

      final result = await adapter(7);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<ForbiddenFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      _throwDio(apiClient, 404);

      final result = await adapter(7);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left(NetworkFailure) on 5xx', () async {
      _throwDio(apiClient, 500);

      final result = await adapter(7);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test(
      'returns Left(UnknownFailure) and logs on unexpected exception',
      () async {
        when(() => apiClient.getUserTier(any())).thenThrow(
          const FormatException('bad json'),
        );
        when(
          () => mockLogger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final result = await adapter(7);

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

void _throwDio(_MockUsersApiClient apiClient, int statusCode) {
  const path = '/user/7/tier';
  when(() => apiClient.getUserTier(any())).thenThrow(
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
