import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/paginated_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_item_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/list_posts/data/list_posts_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late ListPostsAdapter adapter;

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    adapter = ListPostsAdapter(api, logger);
    registerFallbackValue(StackTrace.empty);
  });

  void mockApi(PaginatedPostsDto dto) {
    when(
      () => api.getPosts(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => dto);
  }

  void mockApiThrows(Object error) {
    when(
      () => api.getPosts(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(error);
  }

  final testDto = PaginatedPostsDto(
    items: [
      PostItemDto(
        id: 1,
        title: 'Title',
        text: 'Text',
        createdAt: DateTime(2026),
        username: 'alice',
        createdByUserId: 42,
        postUuid: 'test-uuid',
        status: 'pending_review',
      ),
    ],
    totalCount: 100,
    page: 1,
    itemsPerPage: 10,
  );

  group('call', () {
    test(
      '200 response maps to Right(PaginatedPosts) with correct fields',
      () async {
        mockApi(testDto);

        final result = await adapter(page: 1, perPage: 10);

        expect(result.isRight(), isTrue);
        final posts = (result as Right<Failure, PaginatedPosts>).value;
        expect(posts.items.length, 1);
        expect(posts.items.first.title, 'Title');
        expect(posts.items.first.username, 'alice');
        expect(posts.items.first.createdByUserId, 42);
        expect(posts.hasMore, isTrue);
        expect(posts.page, 1);
      },
    );

    test('hasMore=false when page * itemsPerPage == totalCount', () async {
      mockApi(
        const PaginatedPostsDto(
          items: [
            PostItemDto(
              id: 1,
              username: 'alice',
              postUuid: 'u',
              status: 'pending_review',
            ),
          ],
          totalCount: 10,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(result.isRight(), isTrue);
      final posts = (result as Right<Failure, PaginatedPosts>).value;
      expect(posts.hasMore, isFalse);
    });

    test('null createdAt falls back to DateTime(0)', () async {
      mockApi(
        const PaginatedPostsDto(
          items: [
            PostItemDto(
              id: 1,
              username: 'u',
              postUuid: 'u',
              status: 'pending_review',
            ),
          ],
          totalCount: 10,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(result.isRight(), isTrue);
      final posts = (result as Right<Failure, PaginatedPosts>).value;
      expect(posts.items.first.createdAt, DateTime(0));
    });

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

      final result = await adapter(page: 1, perPage: 10);

      expect(result, const Left<Failure, PaginatedPosts>(Failure.notFound()));
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

      final result = await adapter(page: 1, perPage: 10);

      expect(
        result,
        const Left<Failure, PaginatedPosts>(Failure.server(statusCode: 500)),
      );
    });

    test('DioException network error maps to Left(NetworkFailure)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(result.isLeft(), isTrue);
      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });

    test(
      'unexpected Exception maps to Left(UnknownFailure) and logs error',
      () async {
        final exception = Exception('unexpected');
        mockApiThrows(exception);

        when(
          () => logger.error(
            any(),
            error: any(named: 'error'),
            stackTrace: any(named: 'stackTrace'),
          ),
        ).thenReturn(null);

        final result = await adapter(page: 1, perPage: 10);

        expect(result, const Left<Failure, PaginatedPosts>(Failure.unknown()));
        verify(
          () => logger.error(
            any(),
            error: exception,
            stackTrace: any(named: 'stackTrace'),
          ),
        ).called(1);
      },
    );

    test(
      "status 'approved' on PostItemDto maps to PostStatus.approved on Post",
      () async {
        mockApi(
          const PaginatedPostsDto(
            items: [
              PostItemDto(
                id: 1,
                username: 'alice',
                postUuid: 'uuid-1',
                status: 'approved',
              ),
            ],
            totalCount: 1,
            page: 1,
            itemsPerPage: 10,
          ),
        );

        final result = await adapter(page: 1, perPage: 10);

        final posts = (result as Right<Failure, PaginatedPosts>).value;
        expect(posts.items.first.status, PostStatus.approved);
      },
    );

    test("status 'pending_review' maps to PostStatus.pendingReview", () async {
      mockApi(
        const PaginatedPostsDto(
          items: [
            PostItemDto(
              id: 1,
              username: 'alice',
              postUuid: 'uuid-1',
              status: 'pending_review',
            ),
          ],
          totalCount: 1,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      final posts = (result as Right<Failure, PaginatedPosts>).value;
      expect(posts.items.first.status, PostStatus.pendingReview);
    });

    test(
      "status 'changes_requested' maps to PostStatus.changesRequested",
      () async {
        mockApi(
          const PaginatedPostsDto(
            items: [
              PostItemDto(
                id: 1,
                username: 'alice',
                postUuid: 'uuid-1',
                status: 'changes_requested',
              ),
            ],
            totalCount: 1,
            page: 1,
            itemsPerPage: 10,
          ),
        );

        final result = await adapter(page: 1, perPage: 10);

        final posts = (result as Right<Failure, PaginatedPosts>).value;
        expect(posts.items.first.status, PostStatus.changesRequested);
      },
    );

    test(
      'unknown status falls back to PostStatus.pendingReview and logs warning',
      () async {
        mockApi(
          const PaginatedPostsDto(
            items: [
              PostItemDto(
                id: 1,
                username: 'alice',
                postUuid: 'uuid-1',
                status: 'archived',
              ),
            ],
            totalCount: 1,
            page: 1,
            itemsPerPage: 10,
          ),
        );

        when(() => logger.warning(any())).thenReturn(null);

        final result = await adapter(page: 1, perPage: 10);

        final posts = (result as Right<Failure, PaginatedPosts>).value;
        expect(posts.items.first.status, PostStatus.pendingReview);
        verify(() => logger.warning(any())).called(1);
      },
    );

    test('post_uuid round-trips correctly', () async {
      mockApi(
        const PaginatedPostsDto(
          items: [
            PostItemDto(
              id: 1,
              username: 'alice',
              postUuid: 'uuid-abc',
              status: 'pending_review',
            ),
          ],
          totalCount: 1,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      final posts = (result as Right<Failure, PaginatedPosts>).value;
      expect(posts.items.first.postUuid, 'uuid-abc');
    });
  });
}
