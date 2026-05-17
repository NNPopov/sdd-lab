import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/dto/moderate_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/dto/moderate_post_result_dto.dart';
import 'package:flutter_application_1/features/posts/moderate_post/data/moderate_post_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late ModeratePostAdapter adapter;

  setUpAll(() {
    registerFallbackValue(
      const ModeratePostRequestDto(action: 'approved'),
    );
  });

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);
    adapter = ModeratePostAdapter(api, logger);
  });

  DioException dioError(int statusCode) => DioException(
    requestOptions: RequestOptions(),
    response: Response(
      requestOptions: RequestOptions(),
      statusCode: statusCode,
    ),
  );

  test('200 approved → Right(PostStatus.approved)', () async {
    when(() => api.moderatePost(any(), any())).thenAnswer(
      (_) async => const ModeratePostResultDto(
        postUuid: 'uuid-1',
        status: 'approved',
      ),
    );
    final result = await adapter(
      postUuid: 'uuid-1',
      action: 'approved',
    );
    expect(
      result,
      equals(const Right<Failure, PostStatus>(PostStatus.approved)),
    );
  });

  test('200 changes_requested → Right(PostStatus.changesRequested)', () async {
    when(() => api.moderatePost(any(), any())).thenAnswer(
      (_) async => const ModeratePostResultDto(
        postUuid: 'uuid-1',
        status: 'changes_requested',
      ),
    );
    final result = await adapter(
      postUuid: 'uuid-1',
      action: 'changes_requested',
      message: 'fix it',
    );
    expect(
      result,
      equals(
        const Right<Failure, PostStatus>(PostStatus.changesRequested),
      ),
    );
  });

  test('403 → Left(ForbiddenFailure)', () async {
    when(() => api.moderatePost(any(), any())).thenThrow(dioError(403));
    final result = await adapter(
      postUuid: 'uuid-1',
      action: 'approved',
    );
    expect(result.isLeft(), isTrue);
    expect(result.fold(id, id), isA<ForbiddenFailure>());
  });

  test('404 → Left(NotFoundFailure)', () async {
    when(() => api.moderatePost(any(), any())).thenThrow(dioError(404));
    final result = await adapter(
      postUuid: 'uuid-1',
      action: 'approved',
    );
    expect(result.isLeft(), isTrue);
    expect(result.fold(id, id), isA<NotFoundFailure>());
  });

  test('409 → Left(ConflictFailure)', () async {
    when(() => api.moderatePost(any(), any())).thenThrow(dioError(409));
    final result = await adapter(
      postUuid: 'uuid-1',
      action: 'approved',
    );
    expect(result.isLeft(), isTrue);
    expect(result.fold(id, id), isA<ConflictFailure>());
  });

  test(
    'unexpected exception → Left(UnknownFailure), logger.error called',
    () async {
      when(() => api.moderatePost(any(), any())).thenThrow(Exception('oops'));
      final result = await adapter(
        postUuid: 'uuid-1',
        action: 'approved',
      );
      expect(result.isLeft(), isTrue);
      expect(result.fold(id, id), isA<UnknownFailure>());
      verify(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      ).called(1);
    },
  );
}
