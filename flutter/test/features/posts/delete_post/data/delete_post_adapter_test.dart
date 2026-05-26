import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/delete_post/data/delete_post_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

DioException _makeDioError(int statusCode) => DioException(
  requestOptions: RequestOptions(),
  response: Response(
    requestOptions: RequestOptions(),
    statusCode: statusCode,
    data: <String, dynamic>{},
  ),
);

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late DeletePostAdapter adapter;

  const userId = 7;
  const postId = 42;

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    adapter = DeletePostAdapter(api, logger);
  });

  group('DeletePostAdapter', () {
    test('returns Right(unit) on success', () async {
      when(() => api.deletePost(userId, postId)).thenAnswer((_) async {});

      final result = await adapter(userId, postId);

      expect(result, const Right<Failure, Unit>(unit));
    });

    test('returns Left(UnauthorizedFailure) on 401', () async {
      when(
        () => api.deletePost(userId, postId),
      ).thenThrow(_makeDioError(401));

      final result = await adapter(userId, postId);

      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns Left(ForbiddenFailure) on 403', () async {
      when(
        () => api.deletePost(userId, postId),
      ).thenThrow(_makeDioError(403));

      final result = await adapter(userId, postId);

      result.fold(
        (f) => expect(f, isA<ForbiddenFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns Left(NotFoundFailure) on 404', () async {
      when(
        () => api.deletePost(userId, postId),
      ).thenThrow(_makeDioError(404));

      final result = await adapter(userId, postId);

      result.fold(
        (f) => expect(f, isA<NotFoundFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test('returns Left(NetworkFailure) on 500', () async {
      when(
        () => api.deletePost(userId, postId),
      ).thenThrow(_makeDioError(500));

      final result = await adapter(userId, postId);

      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('expected Left'),
      );
    });

    test(
      'returns Left(UnknownFailure) and calls logger.error on unexpected '
      'exception',
      () async {
        when(
          () => api.deletePost(userId, postId),
        ).thenThrow(Exception('unexpected'));
        when(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final result = await adapter(userId, postId);

        result.fold(
          (f) => expect(f, isA<UnknownFailure>()),
          (_) => fail('expected Left'),
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
