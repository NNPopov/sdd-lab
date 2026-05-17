import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/moderation_log_entry_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/pending_post_item_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/pending_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_action.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/moderation_event_type.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_state.dart';
import 'package:flutter_application_1/features/posts/pending_posts/data/pending_posts_adapter.dart';
import 'package:flutter_application_1/features/posts/pending_posts/domain/usecases/get_pending_posts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockPostEventBus extends Mock implements PostEventBus {}

class _MockAppLogger extends Mock implements AppLogger {}

void main() {
  late _MockPostsApiClient api;
  late _MockPostEventBus eventBus;
  late _MockAppLogger logger;
  late StreamController<PostEvent> eventController;
  late PendingPostsAdapter adapter;
  late GetPendingPostsUseCase useCase;
  late PendingPostsCubit cubit;

  setUp(() {
    api = _MockPostsApiClient();
    eventBus = _MockPostEventBus();
    logger = _MockAppLogger();
    eventController = StreamController<PostEvent>.broadcast();

    when(() => eventBus.stream).thenAnswer((_) => eventController.stream);
    when(
      () => logger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
      ),
    ).thenReturn(null);

    adapter = PendingPostsAdapter(api, logger);
    useCase = GetPendingPostsUseCase(adapter);
    cubit = PendingPostsCubit(useCase, eventBus);
  });

  tearDown(() async {
    await cubit.close();
    await eventController.close();
  });

  test(
    'load — first page — items mapped with moderationLog fields and count, hasMore=true',
    () async {
      when(
        () => api.getPendingPosts(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => PendingPostsDto(
          items: [
            PendingPostItemDto(
              postUuid: 'abc-001',
              title: 'Review this post',
              text: 'Post body text that goes on for a while.',
              status: 'pending_review',
              createdAt: DateTime.parse('2026-05-16T10:00:00.000Z'),
              updatedAt: DateTime.parse('2026-05-16T10:00:00.000Z'),
              authorUsername: 'alice',
              moderationLog: [
                ModerationLogEntryDto(
                  id: 1,
                  eventType: 'moderator_review',
                  action: 'changes_requested',
                  message: 'Please revise.',
                  createdAt: DateTime.parse('2026-05-16T11:00:00.000Z'),
                  actorUserId: 42,
                  actorUsername: 'mod1',
                ),
                ModerationLogEntryDto(
                  id: 2,
                  eventType: 'author_revision',
                  action: null,
                  message: null,
                  createdAt: DateTime.parse('2026-05-16T12:00:00.000Z'),
                  actorUserId: 7,
                  actorUsername: 'alice',
                ),
              ],
            ),
          ],
          totalCount: 25,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PendingPostsState.loading(),
          isA<PendingPostsLoaded>()
              .having((s) => s.items.length, 'items.length', 1)
              .having((s) => s.items.first.postUuid, 'postUuid', 'abc-001')
              .having((s) => s.items.first.title, 'title', 'Review this post')
              .having(
                (s) => s.items.first.authorUsername,
                'authorUsername',
                'alice',
              )
              .having(
                (s) => s.items.first.status,
                'status',
                PostStatus.pendingReview,
              )
              .having(
                (s) => s.items.first.moderationLog.length,
                'moderationLog.length',
                2,
              )
              .having(
                (s) => s.items.first.moderationLog.first.eventType,
                'moderationLog[0].eventType',
                ModerationEventType.moderatorReview,
              )
              .having(
                (s) => s.items.first.moderationLog.first.action,
                'moderationLog[0].action',
                ModerationAction.changesRequested,
              )
              .having(
                (s) => s.items.first.moderationLog.last.eventType,
                'moderationLog[1].eventType',
                ModerationEventType.authorRevision,
              )
              .having(
                (s) => s.items.first.moderationLog.last.action,
                'moderationLog[1].action',
                null,
              )
              .having((s) => s.page, 'page', 1)
              .having((s) => s.hasMore, 'hasMore', isTrue),
        ]),
      );

      await cubit.load();
      await expectation;

      verifyNever(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );
    },
  );

  test(
    'load — server returns 403 — cubit emits PermissionDenied error, logger not called',
    () async {
      when(
        () => api.getPendingPosts(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/posts/pending'),
          response: Response(
            requestOptions: RequestOptions(path: '/posts/pending'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PendingPostsState.loading(),
          isA<PendingPostsError>().having(
            (s) => s.failure,
            'failure',
            const Failure.permissionDenied(),
          ),
        ]),
      );

      await cubit.load();
      await expectation;

      verifyNever(
        () => logger.error(
          any(),
          error: any(named: 'error'),
          stackTrace: any(named: 'stackTrace'),
        ),
      );
    },
  );
}
