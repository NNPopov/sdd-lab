import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/users/_shared/data/users_api_client.dart';
import 'package:flutter_application_1/features/users/moderator_contract/data/moderator_management_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUsersApiClient extends Mock implements UsersApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

DioException _dioError(int statusCode) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: statusCode,
    data: <String, dynamic>{},
  ),
);

void main() {
  late _MockUsersApiClient api;
  late _MockAppLogger logger;
  late ModeratorManagementAdapter adapter;

  setUp(() {
    api = _MockUsersApiClient();
    logger = _MockAppLogger();
    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);
    adapter = ModeratorManagementAdapter(api, logger);
  });

  group('assignModerator', () {
    test('200 → Right(null)', () async {
      when(() => api.assignModerator(7)).thenAnswer((_) async {});

      final result = await adapter.assignModerator(7);

      expect(result.isRight(), isTrue);
    });

    test('403 → Left(ForbiddenFailure)', () async {
      when(() => api.assignModerator(7)).thenThrow(_dioError(403));

      final result = await adapter.assignModerator(7);

      expect(
        result.swap().getOrElse(() => const Failure.unknown()),
        isA<ForbiddenFailure>(),
      );
    });

    test('404 → Left(NotFoundFailure)', () async {
      when(() => api.assignModerator(7)).thenThrow(_dioError(404));

      final result = await adapter.assignModerator(7);

      expect(
        result.swap().getOrElse(() => const Failure.unknown()),
        isA<NotFoundFailure>(),
      );
    });

    test('409 → Left(ConflictFailure)', () async {
      when(() => api.assignModerator(7)).thenThrow(_dioError(409));

      final result = await adapter.assignModerator(7);

      expect(
        result.swap().getOrElse(() => const Failure.unknown()),
        isA<ConflictFailure>(),
      );
    });

    test(
      'unexpected exception → Left(UnknownFailure) and logger.error called',
      () async {
        when(() => api.assignModerator(7)).thenThrow(Exception('boom'));

        final result = await adapter.assignModerator(7);

        expect(
          result.swap().getOrElse(() => const Failure.conflict(message: '')),
          isA<UnknownFailure>(),
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

  group('revokeModerator', () {
    test('200 → Right(null)', () async {
      when(() => api.revokeModerator(7)).thenAnswer((_) async {});

      final result = await adapter.revokeModerator(7);

      expect(result.isRight(), isTrue);
    });

    test('403 → Left(ForbiddenFailure)', () async {
      when(() => api.revokeModerator(7)).thenThrow(_dioError(403));

      final result = await adapter.revokeModerator(7);

      expect(
        result.swap().getOrElse(() => const Failure.unknown()),
        isA<ForbiddenFailure>(),
      );
    });

    test('409 → Left(ConflictFailure)', () async {
      when(() => api.revokeModerator(7)).thenThrow(_dioError(409));

      final result = await adapter.revokeModerator(7);

      expect(
        result.swap().getOrElse(() => const Failure.unknown()),
        isA<ConflictFailure>(),
      );
    });

    test(
      'unexpected exception → Left(UnknownFailure) and logger.error called',
      () async {
        when(() => api.revokeModerator(7)).thenThrow(Exception('boom'));

        final result = await adapter.revokeModerator(7);

        expect(
          result.swap().getOrElse(() => const Failure.conflict(message: '')),
          isA<UnknownFailure>(),
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
