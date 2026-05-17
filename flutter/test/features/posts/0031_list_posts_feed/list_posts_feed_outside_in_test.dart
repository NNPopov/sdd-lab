import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/paginated_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_item_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_state.dart';
import 'package:flutter_application_1/features/posts/list_posts/data/list_posts_adapter.dart';
import 'package:flutter_application_1/features/posts/list_posts/domain/usecases/list_posts_usecase.dart';
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
  late ListPostsAdapter adapter;
  late ListPostsUseCase useCase;
  late ListPostsCubit cubit;

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

    adapter = ListPostsAdapter(api, logger);
    useCase = ListPostsUseCase(adapter);
    cubit = ListPostsCubit(useCase, eventBus);
  });

  tearDown(() async {
    await cubit.close();
    await eventController.close();
  });

  test(
    'load — first page — GET /posts called, username mapped, hasMore=true',
    () async {
      when(
        () => api.getPosts(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => PaginatedPostsDto(
          items: [
            PostItemDto(
              id: 7,
              title: 'Hello World',
              text: 'some body text',
              createdAt: DateTime.parse('2026-05-14T12:00:00.000Z'),
              createdByUserId: 3,
              username: 'alice',
              postUuid: 'test-uuid',
              status: 'pending_review',
            ),
          ],
          totalCount: 100,
          page: 1,
          itemsPerPage: 10,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ListPostsState.loading(),
          isA<ListPostsLoaded>()
              .having((s) => s.posts.length, 'posts.length', 1)
              .having((s) => s.posts.first.id, 'id', 7)
              .having((s) => s.posts.first.title, 'title', 'Hello World')
              .having((s) => s.posts.first.username, 'username', 'alice')
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
    'load — server returns 500 — cubit emits error, logger not called',
    () async {
      when(
        () => api.getPosts(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/posts'),
          response: Response(
            requestOptions: RequestOptions(path: '/posts'),
            statusCode: 500,
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const ListPostsState.loading(),
          isA<ListPostsError>().having(
            (s) => s.failure,
            'failure',
            const Failure.server(statusCode: 500),
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
