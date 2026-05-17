import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/moderation_log_entry_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/pending_post_item_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/pending_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_result.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/pending_posts/data/pending_posts_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late PendingPostsAdapter adapter;

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    adapter = PendingPostsAdapter(api, logger);
    registerFallbackValue(StackTrace.empty);
    when(() => logger.warning(any())).thenReturn(null);
    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);
  });

  void mockApi(PendingPostsDto dto) {
    when(
      () => api.getPendingPosts(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => dto);
  }

  void mockApiThrows(Object error) {
    when(
      () => api.getPendingPosts(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenThrow(error);
  }

  final logEntry1 = ModerationLogEntryDto(
    id: 1,
    eventType: 'moderator_review',
    action: 'changes_requested',
    message: 'Please revise.',
    createdAt: DateTime(2026, 5, 16, 11),
    actorUserId: 42,
    actorUsername: 'mod1',
  );

  final logEntry2 = ModerationLogEntryDto(
    id: 2,
    eventType: 'author_revision',
    createdAt: DateTime(2026, 5, 16, 12),
    actorUserId: 7,
    actorUsername: 'alice',
  );

  final testItemDto = PendingPostItemDto(
    postUuid: 'abc-001',
    title: 'Review this post',
    text: 'Post body.',
    status: 'pending_review',
    createdAt: DateTime(2026, 5, 16, 10),
    updatedAt: DateTime(2026, 5, 16, 10),
    authorUsername: 'alice',
    moderationLog: [logEntry1, logEntry2],
  );

  group('call — success path', () {
    test('maps item to PendingPostItem with correct basic fields', () async {
      mockApi(
        PendingPostsDto(
          items: [testItemDto],
          totalCount: 25,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(result.isRight(), isTrue);
      final paginated =
          (result as Right<Failure, PaginatedResult<PendingPostItem>>).value;
      expect(paginated.items.length, 1);
      final item = paginated.items.first;
      expect(item.postUuid, 'abc-001');
      expect(item.title, 'Review this post');
      expect(item.authorUsername, 'alice');
      expect(item.status, PostStatus.pendingReview);
    });

    test('maps moderationLog entries correctly', () async {
      mockApi(
        PendingPostsDto(
          items: [testItemDto],
          totalCount: 25,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);
      final item = (result as Right<Failure, PaginatedResult<PendingPostItem>>)
          .value
          .items
          .first;

      expect(item.moderationLog.length, 2);
      expect(
        item.moderationLog.first.eventType,
        ModerationEventType.moderatorReview,
      );
      expect(
        item.moderationLog.first.action,
        ModerationAction.changesRequested,
      );
      expect(
        item.moderationLog.last.eventType,
        ModerationEventType.authorRevision,
      );
      expect(item.moderationLog.last.action, isNull);
    });

    test('hasMore=true when page * perPage < totalCount', () async {
      mockApi(
        PendingPostsDto(
          items: [testItemDto],
          totalCount: 25,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);
      final paginated =
          (result as Right<Failure, PaginatedResult<PendingPostItem>>).value;
      expect(paginated.hasMore, isTrue);
    });

    test('hasMore=false when page * perPage >= totalCount', () async {
      mockApi(
        PendingPostsDto(
          items: [testItemDto],
          totalCount: 10,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);
      final paginated =
          (result as Right<Failure, PaginatedResult<PendingPostItem>>).value;
      expect(paginated.hasMore, isFalse);
    });

    test("status 'approved' maps to PostStatus.approved", () async {
      mockApi(
        PendingPostsDto(
          items: [
            PendingPostItemDto(
              postUuid: 'u',
              title: 'T',
              text: 'B',
              status: 'approved',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              authorUsername: 'bob',
            ),
          ],
          totalCount: 1,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);
      final item = (result as Right<Failure, PaginatedResult<PendingPostItem>>)
          .value
          .items
          .first;
      expect(item.status, PostStatus.approved);
    });

    test(
      "status 'changes_requested' maps to PostStatus.changesRequested",
      () async {
        mockApi(
          PendingPostsDto(
            items: [
              PendingPostItemDto(
                postUuid: 'u',
                title: 'T',
                text: 'B',
                status: 'changes_requested',
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
                authorUsername: 'bob',
              ),
            ],
            totalCount: 1,
            page: 1,
            itemsPerPage: 10,
          ),
        );

        final result = await adapter(page: 1, perPage: 10);
        final item =
            (result as Right<Failure, PaginatedResult<PendingPostItem>>)
                .value
                .items
                .first;
        expect(item.status, PostStatus.changesRequested);
      },
    );

    test(
      "eventType 'author_revision' maps to ModerationEventType.authorRevision",
      () async {
        mockApi(
          PendingPostsDto(
            items: [
              PendingPostItemDto(
                postUuid: 'u',
                title: 'T',
                text: 'B',
                status: 'pending_review',
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
                authorUsername: 'bob',
                moderationLog: [
                  ModerationLogEntryDto(
                    id: 1,
                    eventType: 'author_revision',
                    createdAt: DateTime(2026),
                    actorUserId: 1,
                    actorUsername: 'bob',
                  ),
                ],
              ),
            ],
            totalCount: 1,
            page: 1,
            itemsPerPage: 10,
          ),
        );

        final result = await adapter(page: 1, perPage: 10);
        final entry =
            (result as Right<Failure, PaginatedResult<PendingPostItem>>)
                .value
                .items
                .first
                .moderationLog
                .first;
        expect(entry.eventType, ModerationEventType.authorRevision);
      },
    );

    test("action 'approved' maps to ModerationAction.approved", () async {
      mockApi(
        PendingPostsDto(
          items: [
            PendingPostItemDto(
              postUuid: 'u',
              title: 'T',
              text: 'B',
              status: 'pending_review',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
              authorUsername: 'bob',
              moderationLog: [
                ModerationLogEntryDto(
                  id: 1,
                  eventType: 'moderator_review',
                  action: 'approved',
                  createdAt: DateTime(2026),
                  actorUserId: 1,
                  actorUsername: 'mod1',
                ),
              ],
            ),
          ],
          totalCount: 1,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);
      final entry = (result as Right<Failure, PaginatedResult<PendingPostItem>>)
          .value
          .items
          .first
          .moderationLog
          .first;
      expect(entry.action, ModerationAction.approved);
    });
  });

  group('call — HTTP error mapping', () {
    test('DioException 401 maps to Left(UnauthorizedFailure)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(path: '/posts/pending'),
          response: Response(
            requestOptions: RequestOptions(path: '/posts/pending'),
            statusCode: 401,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((f) => f, (_) => null),
        isA<UnauthorizedFailure>(),
      );
      verifyNever(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );
    });

    test('DioException 403 maps to Left(PermissionDenied)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(path: '/posts/pending'),
          response: Response(
            requestOptions: RequestOptions(path: '/posts/pending'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(
        result,
        const Left<Failure, PaginatedResult<PendingPostItem>>(
          Failure.permissionDenied(),
        ),
      );
      verifyNever(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );
    });

    test('DioException 404 maps to Left(NotFoundFailure)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(path: '/posts/pending'),
          response: Response(
            requestOptions: RequestOptions(path: '/posts/pending'),
            statusCode: 404,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(
        result,
        const Left<Failure, PaginatedResult<PendingPostItem>>(
          Failure.notFound(),
        ),
      );
    });

    test('DioException 500 maps to Left(ServerFailure)', () async {
      mockApiThrows(
        DioException(
          requestOptions: RequestOptions(path: '/posts/pending'),
          response: Response(
            requestOptions: RequestOptions(path: '/posts/pending'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await adapter(page: 1, perPage: 10);

      expect(
        result,
        const Left<Failure, PaginatedResult<PendingPostItem>>(
          Failure.server(statusCode: 500),
        ),
      );
    });

    test(
      'DioException without statusCode maps to Left(NetworkFailure)',
      () async {
        mockApiThrows(
          DioException(
            requestOptions: RequestOptions(path: '/posts/pending'),
            type: DioExceptionType.connectionError,
          ),
        );

        final result = await adapter(page: 1, perPage: 10);

        expect(result.isLeft(), isTrue);
        expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
      },
    );

    test(
      'unexpected Exception maps to Left(UnknownFailure) and logs error',
      () async {
        final exception = Exception('boom');
        mockApiThrows(exception);

        final result = await adapter(page: 1, perPage: 10);

        expect(
          result,
          const Left<Failure, PaginatedResult<PendingPostItem>>(
            Failure.unknown(),
          ),
        );
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
