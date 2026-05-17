import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_posts.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_state.dart';
import 'package:flutter_application_1/features/posts/user_posts/domain/usecases/user_posts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockUserPostsUseCase extends Mock implements UserPostsUseCase {}

class _MockPostEventBus extends Mock implements PostEventBus {}

void main() {
  late _MockUserPostsUseCase useCase;
  late _MockPostEventBus eventBus;
  late StreamController<PostEvent> eventController;
  late UserPostsCubit cubit;

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
    useCase = _MockUserPostsUseCase();
    eventBus = _MockPostEventBus();
    eventController = StreamController<PostEvent>.broadcast();
    when(() => eventBus.stream).thenAnswer((_) => eventController.stream);
    cubit = UserPostsCubit(useCase, eventBus);
  });

  tearDown(() async {
    await cubit.close();
    await eventController.close();
  });

  void mockSuccess(PaginatedPosts result, {int callPage = 1}) {
    when(
      () => useCase(
        username: any(named: 'username'),
        page: callPage,
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(result));
  }

  void mockFailure(Failure failure) {
    when(
      () => useCase(
        username: any(named: 'username'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Left(failure));
  }

  group('load', () {
    blocTest<UserPostsCubit, UserPostsState>(
      'success emits [loading, loaded]',
      build: () => cubit,
      setUp: () => mockSuccess(page([post1])),
      act: (c) => c.load('alice'),
      expect: () => [
        const UserPostsState.loading(),
        UserPostsState.loaded(posts: [post1], page: 1, hasMore: true),
      ],
    );

    blocTest<UserPostsCubit, UserPostsState>(
      'failure emits [loading, error]',
      build: () => cubit,
      setUp: () => mockFailure(const Failure.network()),
      act: (c) => c.load('alice'),
      expect: () => [
        const UserPostsState.loading(),
        const UserPostsState.error(Failure.network()),
      ],
    );
  });

  group('refresh', () {
    blocTest<UserPostsCubit, UserPostsState>(
      'resets to page 1 and emits [loading, loaded]',
      build: () => cubit,
      seed: () => UserPostsState.loaded(
        posts: [post1, post2],
        page: 2,
        hasMore: false,
      ),
      setUp: () => mockSuccess(page([post1], totalCount: 10)),
      act: (c) => c.refresh('alice'),
      expect: () => [
        const UserPostsState.loading(),
        UserPostsState.loaded(posts: [post1], page: 1, hasMore: false),
      ],
    );
  });

  group('loadMore', () {
    blocTest<UserPostsCubit, UserPostsState>(
      'appends posts and increments page when hasMore=true',
      build: () => cubit,
      seed: () => UserPostsState.loaded(
        posts: [post1],
        page: 1,
        hasMore: true,
      ),
      setUp: () {
        when(
          () => useCase(
            username: any(named: 'username'),
            page: 2,
            perPage: any(named: 'perPage'),
          ),
        ).thenAnswer((_) async => Right(page([post2], page: 2)));
      },
      act: (c) => c.loadMore('alice'),
      expect: () => [
        UserPostsState.loaded(
          posts: [post1],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
        UserPostsState.loaded(posts: [post1, post2], page: 2, hasMore: false),
      ],
    );

    blocTest<UserPostsCubit, UserPostsState>(
      'does nothing when hasMore=false',
      build: () => cubit,
      seed: () => UserPostsState.loaded(
        posts: [post1],
        page: 1,
        hasMore: false,
      ),
      act: (c) => c.loadMore('alice'),
      expect: () => <UserPostsState>[],
      verify: (_) => verifyNever(
        () => useCase(
          username: any(named: 'username'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ),
    );

    blocTest<UserPostsCubit, UserPostsState>(
      'does nothing when already loading more',
      build: () => cubit,
      seed: () => UserPostsState.loaded(
        posts: [post1],
        page: 1,
        hasMore: true,
        loadMoreStatus: LoadMoreStatus.loading,
      ),
      act: (c) => c.loadMore('alice'),
      expect: () => <UserPostsState>[],
      verify: (_) => verifyNever(
        () => useCase(
          username: any(named: 'username'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ),
    );
  });

  group('PostEventBus integration', () {
    test(
      'PostDeleted removes matching post from UserPostsLoaded list',
      () async {
        cubit.emit(
          UserPostsState.loaded(
            posts: [post1, post2],
            page: 1,
            hasMore: false,
          ),
        );

        eventController.add(PostDeleted(post1.id));
        await Future<void>.delayed(Duration.zero);

        expect(
          cubit.state,
          UserPostsState.loaded(
            posts: [post2],
            page: 1,
            hasMore: false,
          ),
        );
      },
    );

    test(
      'PostDeleted with unknown id leaves list unchanged',
      () async {
        cubit.emit(
          UserPostsState.loaded(
            posts: [post1, post2],
            page: 1,
            hasMore: false,
          ),
        );

        eventController.add(PostDeleted(999));
        await Future<void>.delayed(Duration.zero);

        expect(
          cubit.state,
          UserPostsState.loaded(
            posts: [post1, post2],
            page: 1,
            hasMore: false,
          ),
        );
      },
    );

    test(
      'PostDeleted when state is not UserPostsLoaded emits nothing',
      () async {
        expect(cubit.state, const UserPostsState.initial());

        eventController.add(PostDeleted(post1.id));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, const UserPostsState.initial());
      },
    );
  });
}
