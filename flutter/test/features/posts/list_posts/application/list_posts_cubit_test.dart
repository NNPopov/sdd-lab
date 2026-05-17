import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/list_posts/application/list_posts_state.dart';
import 'package:flutter_application_1/features/posts/list_posts/domain/usecases/list_posts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListPostsUseCase extends Mock implements ListPostsUseCase {}

class _MockPostEventBus extends Mock implements PostEventBus {}

void main() {
  late _MockListPostsUseCase useCase;
  late _MockPostEventBus eventBus;
  late StreamController<PostEvent> eventController;
  late ListPostsCubit cubit;

  final post1 = Post(
    id: 1,
    title: 'Post 1',
    text: 'Content 1',
    createdAt: DateTime(2026),
    createdByUserId: 1,
    postUuid: 'test-uuid-1',
    status: PostStatus.pendingReview,
  );
  final post2 = Post(
    id: 2,
    title: 'Post 2',
    text: 'Content 2',
    createdAt: DateTime(2026),
    createdByUserId: 1,
    postUuid: 'test-uuid-2',
    status: PostStatus.pendingReview,
  );

  PaginatedPosts page(
    List<Post> items, {
    int totalCount = 20,
    int page = 1,
  }) => PaginatedPosts(
    items: items,
    totalCount: totalCount,
    page: page,
    itemsPerPage: 10,
  );

  setUp(() {
    useCase = _MockListPostsUseCase();
    eventBus = _MockPostEventBus();
    eventController = StreamController<PostEvent>.broadcast();
    when(() => eventBus.stream).thenAnswer((_) => eventController.stream);
    cubit = ListPostsCubit(useCase, eventBus);
  });

  tearDown(() async {
    await cubit.close();
    await eventController.close();
  });

  void mockSuccess(PaginatedPosts result, {int callPage = 1}) {
    when(
      () => useCase(
        page: callPage,
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(result));
  }

  void mockFailure(Failure failure) {
    when(
      () => useCase(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Left(failure));
  }

  group('load', () {
    blocTest<ListPostsCubit, ListPostsState>(
      'success emits [loading, loaded]',
      build: () => cubit,
      setUp: () => mockSuccess(page([post1])),
      act: (c) => c.load(),
      expect: () => [
        const ListPostsState.loading(),
        ListPostsState.loaded(posts: [post1], page: 1, hasMore: true),
      ],
    );

    blocTest<ListPostsCubit, ListPostsState>(
      'failure emits [loading, error]',
      build: () => cubit,
      setUp: () => mockFailure(const Failure.network()),
      act: (c) => c.load(),
      expect: () => [
        const ListPostsState.loading(),
        const ListPostsState.error(Failure.network()),
      ],
    );
  });

  group('refresh', () {
    blocTest<ListPostsCubit, ListPostsState>(
      'resets to page 1 and emits [loading, loaded]',
      build: () => cubit,
      seed: () =>
          ListPostsState.loaded(posts: [post1, post2], page: 2, hasMore: false),
      setUp: () => mockSuccess(page([post1], totalCount: 10)),
      act: (c) => c.refresh(),
      expect: () => [
        const ListPostsState.loading(),
        ListPostsState.loaded(posts: [post1], page: 1, hasMore: false),
      ],
    );
  });

  group('loadMore', () {
    blocTest<ListPostsCubit, ListPostsState>(
      'appends posts and increments page when hasMore=true',
      build: () => cubit,
      seed: () => ListPostsState.loaded(posts: [post1], page: 1, hasMore: true),
      setUp: () {
        when(
          () => useCase(page: 2, perPage: any(named: 'perPage')),
        ).thenAnswer((_) async => Right(page([post2], page: 2)));
      },
      act: (c) => c.loadMore(),
      expect: () => [
        ListPostsState.loaded(
          posts: [post1],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
        ListPostsState.loaded(posts: [post1, post2], page: 2, hasMore: false),
      ],
    );

    blocTest<ListPostsCubit, ListPostsState>(
      'failure emits loadMoreStatus.error',
      build: () => cubit,
      seed: () => ListPostsState.loaded(posts: [post1], page: 1, hasMore: true),
      setUp: () {
        when(
          () => useCase(page: 2, perPage: any(named: 'perPage')),
        ).thenAnswer((_) async => const Left(Failure.network()));
      },
      act: (c) => c.loadMore(),
      expect: () => [
        ListPostsState.loaded(
          posts: [post1],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
        ListPostsState.loaded(
          posts: [post1],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.error,
          loadMoreError: const Failure.network(),
        ),
      ],
    );

    blocTest<ListPostsCubit, ListPostsState>(
      'does nothing when hasMore=false',
      build: () => cubit,
      seed: () =>
          ListPostsState.loaded(posts: [post1], page: 1, hasMore: false),
      act: (c) => c.loadMore(),
      expect: () => <ListPostsState>[],
      verify: (_) => verifyNever(
        () => useCase(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ),
    );

    blocTest<ListPostsCubit, ListPostsState>(
      'does nothing when already loading more',
      build: () => cubit,
      seed: () => ListPostsState.loaded(
        posts: [post1],
        page: 1,
        hasMore: true,
        loadMoreStatus: LoadMoreStatus.loading,
      ),
      act: (c) => c.loadMore(),
      expect: () => <ListPostsState>[],
      verify: (_) => verifyNever(
        () => useCase(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ),
    );

    blocTest<ListPostsCubit, ListPostsState>(
      'does nothing when state is not loaded',
      build: () => cubit,
      act: (c) => c.loadMore(),
      expect: () => <ListPostsState>[],
    );
  });

  group('PostEventBus integration', () {
    test(
      'PostDeleted removes matching post from ListPostsLoaded',
      () async {
        cubit.emit(
          ListPostsState.loaded(
            posts: [post1, post2],
            page: 1,
            hasMore: false,
          ),
        );

        eventController.add(PostDeleted(post1.id));
        await Future<void>.delayed(Duration.zero);

        expect(
          cubit.state,
          ListPostsState.loaded(posts: [post2], page: 1, hasMore: false),
        );
      },
    );

    test(
      'PostDeleted when state is ListPostsInitial is ignored',
      () async {
        expect(cubit.state, const ListPostsState.initial());

        eventController.add(PostDeleted(post1.id));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, const ListPostsState.initial());
      },
    );
  });
}
