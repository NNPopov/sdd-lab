import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/paginated_result.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/pending_post_item.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/pending_posts/application/pending_posts_state.dart';
import 'package:flutter_application_1/features/posts/pending_posts/domain/usecases/get_pending_posts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetPendingPostsUseCase extends Mock
    implements GetPendingPostsUseCase {}

class _MockPostEventBus extends Mock implements PostEventBus {}

void main() {
  late _MockGetPendingPostsUseCase useCase;
  late _MockPostEventBus eventBus;
  late StreamController<PostEvent> eventController;
  late PendingPostsCubit cubit;

  final item1 = PendingPostItem(
    postUuid: 'uuid-1',
    title: 'First Pending',
    text: 'Body 1',
    status: PostStatus.pendingReview,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorUsername: 'alice',
    moderationLog: [],
  );

  final item2 = PendingPostItem(
    postUuid: 'uuid-2',
    title: 'Second Pending',
    text: 'Body 2',
    status: PostStatus.pendingReview,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    authorUsername: 'bob',
    moderationLog: [],
  );

  PaginatedResult<PendingPostItem> page(
    List<PendingPostItem> items, {
    int totalCount = 20,
    int pageNum = 1,
  }) => PaginatedResult<PendingPostItem>(
    items: items,
    totalCount: totalCount,
    page: pageNum,
    itemsPerPage: 10,
  );

  setUp(() {
    useCase = _MockGetPendingPostsUseCase();
    eventBus = _MockPostEventBus();
    eventController = StreamController<PostEvent>.broadcast();
    when(() => eventBus.stream).thenAnswer((_) => eventController.stream);
    cubit = PendingPostsCubit(useCase, eventBus);
  });

  tearDown(() async {
    await cubit.close();
    await eventController.close();
  });

  void mockSuccess(
    PaginatedResult<PendingPostItem> result, {
    int callPage = 1,
  }) {
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
    blocTest<PendingPostsCubit, PendingPostsState>(
      'success emits [loading, loaded]',
      build: () => cubit,
      setUp: () => mockSuccess(page([item1])),
      act: (c) => c.load(),
      expect: () => [
        const PendingPostsState.loading(),
        PendingPostsState.loaded(items: [item1], page: 1, hasMore: true),
      ],
    );

    blocTest<PendingPostsCubit, PendingPostsState>(
      'failure emits [loading, error]',
      build: () => cubit,
      setUp: () => mockFailure(const Failure.network()),
      act: (c) => c.load(),
      expect: () => [
        const PendingPostsState.loading(),
        const PendingPostsState.error(Failure.network()),
      ],
    );
  });

  group('refresh', () {
    blocTest<PendingPostsCubit, PendingPostsState>(
      'resets to page 1 and emits [loading, loaded]',
      build: () => cubit,
      seed: () => PendingPostsState.loaded(
        items: [item1, item2],
        page: 2,
        hasMore: false,
      ),
      setUp: () => mockSuccess(page([item1], totalCount: 10)),
      act: (c) => c.refresh(),
      expect: () => [
        const PendingPostsState.loading(),
        PendingPostsState.loaded(items: [item1], page: 1, hasMore: false),
      ],
    );
  });

  group('loadMore', () {
    blocTest<PendingPostsCubit, PendingPostsState>(
      'appends items and increments page',
      build: () => cubit,
      seed: () =>
          PendingPostsState.loaded(items: [item1], page: 1, hasMore: true),
      setUp: () {
        when(
          () => useCase(page: 2, perPage: any(named: 'perPage')),
        ).thenAnswer((_) async => Right(page([item2], pageNum: 2)));
      },
      act: (c) => c.loadMore(),
      expect: () => [
        PendingPostsState.loaded(
          items: [item1],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
        PendingPostsState.loaded(
          items: [item1, item2],
          page: 2,
          hasMore: false,
        ),
      ],
    );

    blocTest<PendingPostsCubit, PendingPostsState>(
      'failure emits loadMoreStatus.error',
      build: () => cubit,
      seed: () =>
          PendingPostsState.loaded(items: [item1], page: 1, hasMore: true),
      setUp: () {
        when(
          () => useCase(page: 2, perPage: any(named: 'perPage')),
        ).thenAnswer((_) async => const Left(Failure.network()));
      },
      act: (c) => c.loadMore(),
      expect: () => [
        PendingPostsState.loaded(
          items: [item1],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.loading,
        ),
        PendingPostsState.loaded(
          items: [item1],
          page: 1,
          hasMore: true,
          loadMoreStatus: LoadMoreStatus.error,
          loadMoreError: const Failure.network(),
        ),
      ],
    );

    blocTest<PendingPostsCubit, PendingPostsState>(
      'does nothing when hasMore=false',
      build: () => cubit,
      seed: () =>
          PendingPostsState.loaded(items: [item1], page: 1, hasMore: false),
      act: (c) => c.loadMore(),
      expect: () => <PendingPostsState>[],
      verify: (_) => verifyNever(
        () => useCase(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ),
    );

    blocTest<PendingPostsCubit, PendingPostsState>(
      'does nothing when already loading more',
      build: () => cubit,
      seed: () => PendingPostsState.loaded(
        items: [item1],
        page: 1,
        hasMore: true,
        loadMoreStatus: LoadMoreStatus.loading,
      ),
      act: (c) => c.loadMore(),
      expect: () => <PendingPostsState>[],
      verify: (_) => verifyNever(
        () => useCase(
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ),
    );

    blocTest<PendingPostsCubit, PendingPostsState>(
      'does nothing when state is not loaded',
      build: () => cubit,
      act: (c) => c.loadMore(),
      expect: () => <PendingPostsState>[],
    );
  });

  group('PostModeratedEvent', () {
    test(
      'removes matching item from PendingPostsLoaded',
      () async {
        cubit.emit(
          PendingPostsState.loaded(
            items: [item1, item2],
            page: 1,
            hasMore: false,
          ),
        );

        eventController.add(PostModeratedEvent(item1.postUuid));
        await Future<void>.delayed(Duration.zero);

        expect(
          cubit.state,
          PendingPostsState.loaded(items: [item2], page: 1, hasMore: false),
        );
      },
    );

    test(
      'does nothing when state is PendingPostsInitial',
      () async {
        expect(cubit.state, const PendingPostsState.initial());

        eventController.add(PostModeratedEvent('uuid-1'));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, const PendingPostsState.initial());
      },
    );
  });
}
