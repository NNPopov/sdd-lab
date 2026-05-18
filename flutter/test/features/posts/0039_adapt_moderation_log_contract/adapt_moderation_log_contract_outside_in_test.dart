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
    when(() => logger.warning(any())).thenReturn(null);
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
    'load — moderation log entry without actor fields — emits loaded with null actor fields',
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
              postUuid: 'uuid-changes-001',
              title: 'Needs revision',
              text: 'Body text.',
              status: 'changes_requested',
              createdAt: DateTime(2026, 5, 16, 20, 45),
              authorUsername: 'userson3',
              moderationLog: [
                // actorUserId and actorUsername intentionally omitted —
                // the real API does not return these fields.
                ModerationLogEntryDto(
                  id: 440,
                  eventType: 'moderator_review',
                  action: 'changes_requested',
                  message: 'strange post',
                  createdAt: DateTime(2026, 5, 16, 21, 3),
                ),
              ],
            ),
          ],
          totalCount: 1,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const PendingPostsState.loading(),
          isA<PendingPostsLoaded>(),
        ]),
      );

      await cubit.load();
      await expectation;

      final loaded = cubit.state as PendingPostsLoaded;
      expect(loaded.items.length, 1);
      expect(loaded.items.first.postUuid, 'uuid-changes-001');
      expect(loaded.items.first.status, PostStatus.changesRequested);
      expect(loaded.items.first.moderationLog.length, 1);
      expect(loaded.items.first.moderationLog.first.actorUserId, isNull);
      expect(loaded.items.first.moderationLog.first.actorUsername, isNull);
      expect(
        loaded.items.first.moderationLog.first.action,
        ModerationAction.changesRequested,
      );
      expect(loaded.hasMore, isFalse);

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
    'load — server returns 403 — emits PermissionDenied error, logger not called',
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
