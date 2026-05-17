import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/post_details/data/get_post_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late GetPostAdapter adapter;

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    adapter = GetPostAdapter(api, logger);
    registerFallbackValue(StackTrace.empty);

    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);
    when(() => logger.warning(any())).thenReturn(null);
  });

  PostDto dto({required String status, String postUuid = 'test-uuid'}) =>
      PostDto(
        id: 42,
        title: 'Hello',
        text: 'World',
        createdAt: DateTime(2026),
        createdByUserId: 7,
        postUuid: postUuid,
        status: status,
      );

  void mockApi(PostDto d) {
    when(() => api.getPost(any(), any())).thenAnswer((_) async => d);
  }

  void mockApiThrows(Object error) {
    when(() => api.getPost(any(), any())).thenThrow(error);
  }

  group('status mapping', () {
    test("status 'approved' maps to PostStatus.approved", () async {
      mockApi(dto(status: 'approved'));

      final result = await adapter('alice', 42);

      final post = (result as Right<Failure, Post>).value;
      expect(post.status, PostStatus.approved);
      verifyNever(() => logger.warning(any()));
    });

    test("status 'pending_review' maps to PostStatus.pendingReview", () async {
      mockApi(dto(status: 'pending_review'));

      final result = await adapter('alice', 42);

      final post = (result as Right<Failure, Post>).value;
      expect(post.status, PostStatus.pendingReview);
      verifyNever(() => logger.warning(any()));
    });

    test(
      "status 'changes_requested' maps to PostStatus.changesRequested",
      () async {
        mockApi(dto(status: 'changes_requested'));

        final result = await adapter('alice', 42);

        final post = (result as Right<Failure, Post>).value;
        expect(post.status, PostStatus.changesRequested);
        verifyNever(() => logger.warning(any()));
      },
    );

    test(
      'unknown status falls back to PostStatus.pendingReview and logs warning',
      () async {
        mockApi(dto(status: 'archived'));

        final result = await adapter('alice', 42);

        final post = (result as Right<Failure, Post>).value;
        expect(post.status, PostStatus.pendingReview);
        verify(() => logger.warning(any())).called(1);
      },
    );

    test('post_uuid round-trips correctly', () async {
      mockApi(dto(status: 'approved', postUuid: 'uuid-abc'));

      final result = await adapter('alice', 42);

      final post = (result as Right<Failure, Post>).value;
      expect(post.postUuid, 'uuid-abc');
    });
  });

  group('HTTP error mapping', () {
    test('DioException 404 maps to Left(NotFoundFailure)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await adapter('alice', 42);

      expect(result, const Left<Failure, Post>(Failure.notFound()));
    });

    test('DioException 500 maps to Left(ServerFailure)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(
            requestOptions: RequestOptions(),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await adapter('alice', 42);

      expect(
        result,
        const Left<Failure, Post>(Failure.server(statusCode: 500)),
      );
    });

    test(
      'unexpected Exception maps to Left(UnknownFailure) and logs error',
      () async {
        final exception = Exception('unexpected');
        mockApiThrows(exception);

        final result = await adapter('alice', 42);

        expect(result, const Left<Failure, Post>(Failure.unknown()));
        verify(
          () => logger.error(
            any(),
            error: exception,
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );
  });
}
