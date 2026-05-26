import 'dart:async';

import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/paginated_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_item_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_state.dart';
import 'package:flutter_application_1/features/posts/user_posts/data/user_posts_adapter.dart';
import 'package:flutter_application_1/features/posts/user_posts/domain/usecases/user_posts_usecase.dart';
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
  late UserPostsAdapter adapter;
  late UserPostsUseCase useCase;
  late UserPostsCubit cubit;

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

    adapter = UserPostsAdapter(api, logger);
    useCase = UserPostsUseCase(adapter);
    cubit = UserPostsCubit(useCase, eventBus);
  });

  tearDown(() async {
    await cubit.close();
    await eventController.close();
  });

  void mockApiSuccess({
    required int totalCount,
    required int page,
    required int itemsPerPage,
  }) {
    when(
      () => api.getUserPosts(
        any(),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => PaginatedPostsDto(
        items: [
          PostItemDto(
            id: 2,
            title: 'Test Post',
            text: 'test',
            createdAt: DateTime.parse('2026-04-29T21:26:38.178566Z'),
            createdByUserId: 2,
            username: 'userson1',
            postUuid: 'test-uuid',
            status: 'pending_review',
          ),
        ],
        totalCount: totalCount,
        page: page,
        itemsPerPage: itemsPerPage,
      ),
    );
  }

  test(
    'load — first page — new contract parsed, username mapped, hasMore=true',
    () async {
      mockApiSuccess(totalCount: 100, page: 1, itemsPerPage: 10);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const UserPostsState.loading(),
          isA<UserPostsLoaded>()
              .having((s) => s.posts.length, 'posts.length', 1)
              .having((s) => s.posts.first.title, 'title', 'Test Post')
              .having((s) => s.posts.first.username, 'username', 'userson1')
              .having((s) => s.page, 'page', 1)
              .having((s) => s.hasMore, 'hasMore', isTrue),
        ]),
      );

      await cubit.load(2);
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
    'load — last page exactly full — hasMore=false when totalCount==page×itemsPerPage',
    () async {
      mockApiSuccess(totalCount: 10, page: 1, itemsPerPage: 10);

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          const UserPostsState.loading(),
          isA<UserPostsLoaded>()
              .having((s) => s.posts.length, 'posts.length', 1)
              .having((s) => s.hasMore, 'hasMore', isFalse),
        ]),
      );

      await cubit.load(2);
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
