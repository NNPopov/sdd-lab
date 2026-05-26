import 'dart:async';

import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event.dart';
import 'package:flutter_application_1/features/posts/_shared/application/post_event_bus.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/create_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/paginated_posts_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_item_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/create_post/application/create_post_cubit.dart';
import 'package:flutter_application_1/features/posts/create_post/application/create_post_state.dart';
import 'package:flutter_application_1/features/posts/create_post/data/create_post_adapter.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/entities/new_post_data.dart';
import 'package:flutter_application_1/features/posts/create_post/domain/usecases/create_post_usecase.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_cubit.dart';
import 'package:flutter_application_1/features/posts/user_posts/application/user_posts_state.dart';
import 'package:flutter_application_1/features/posts/user_posts/data/user_posts_adapter.dart';
import 'package:flutter_application_1/features/posts/user_posts/domain/usecases/user_posts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAuthCubit extends Mock implements AuthCubit {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockPostEventBus extends Mock implements PostEventBus {}

void main() {
  // Fixtures keyed by the integer author id this migration introduces.
  const authorId = 7;

  const owner = CurrentUser(
    id: authorId,
    username: 'alice',
    email: 'alice@example.com',
    name: 'Alice',
    isSuperuser: false,
    isModerator: false,
  );

  const otherUser = CurrentUser(
    id: 99,
    username: 'mallory',
    email: 'mallory@example.com',
    name: 'Mallory',
    isSuperuser: false,
    isModerator: false,
  );

  const longText =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  final authorPostsDto = PaginatedPostsDto(
    items: [
      PostItemDto(
        id: 1,
        title: 'Title',
        text: 'Text',
        createdAt: DateTime(2026),
        username: 'alice',
        postUuid: 'uuid-1',
        status: 'approved',
        createdByUserId: authorId,
      ),
    ],
    totalCount: 1,
    page: 1,
    itemsPerPage: 10,
  );

  late _MockPostsApiClient api;
  late _MockAuthCubit authCubit;
  late _MockAppLogger logger;
  late _MockPostEventBus eventBus;
  late StreamController<PostEvent> eventController;

  late UserPostsCubit userPostsCubit;
  late CreatePostCubit createPostCubit;

  setUpAll(() {
    registerFallbackValue(const CreatePostRequestDto(title: '', text: ''));
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    api = _MockPostsApiClient();
    authCubit = _MockAuthCubit();
    logger = _MockAppLogger();
    eventBus = _MockPostEventBus();
    eventController = StreamController<PostEvent>.broadcast();
    when(() => eventBus.stream).thenAnswer((_) => eventController.stream);

    // user_posts vertical — wired real, only the API client is mocked.
    final userPostsAdapter = UserPostsAdapter(api, logger);
    final userPostsUseCase = UserPostsUseCase(userPostsAdapter);
    userPostsCubit = UserPostsCubit(userPostsUseCase, eventBus);

    // create_post vertical — wired real, API client + AuthCubit mocked.
    final createPostAdapter = CreatePostAdapter(api, logger);
    final createPostUseCase = CreatePostUseCase(createPostAdapter, authCubit);
    createPostCubit = CreatePostCubit(createPostUseCase);
  });

  tearDown(() async {
    await userPostsCubit.close();
    await createPostCubit.close();
    await eventController.close();
  });

  test(
    'Scenario 1: listing an author calls getUserPosts with the integer id',
    () async {
      when(
        () => api.getUserPosts(
          authorId,
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => authorPostsDto);

      final expectation = expectLater(
        userPostsCubit.stream,
        emitsInOrder([
          const UserPostsState.loading(),
          isA<UserPostsLoaded>(),
        ]),
      );

      await userPostsCubit.load(authorId);
      await expectation;

      final loaded = userPostsCubit.state as UserPostsLoaded;
      expect(loaded.posts.length, 1);
      expect(loaded.posts.first.createdByUserId, authorId);
      verify(() => api.getUserPosts(authorId, page: 1, perPage: 10)).called(1);
    },
  );

  test(
    'Scenario 2: publishing as oneself calls createPost with the integer id '
    'and unchanged body',
    () async {
      when(() => authCubit.currentUser).thenReturn(owner);
      when(() => api.createPost(authorId, any())).thenAnswer(
        (_) async => const PostDto(
          id: 1,
          postUuid: 'uuid-1',
          status: 'pending_review',
          createdByUserId: authorId,
        ),
      );

      final expectation = expectLater(
        createPostCubit.stream,
        emitsInOrder([
          const CreatePostState.loading(),
          const CreatePostState.success(),
        ]),
      );

      await createPostCubit.submit(
        const NewPostData(
          userId: authorId,
          title: 'Hello world',
          text: longText,
        ),
      );
      await expectation;

      final captured = verify(
        () => api.createPost(authorId, captureAny()),
      ).captured;
      final body = captured.single as CreatePostRequestDto;
      expect(body.title, 'Hello world');
      expect(body.text, longText);
      expect(body.mediaUrl, isNull);
    },
  );

  test(
    'Scenario 3: publishing as a different user is refused by identity '
    'before any network call',
    () async {
      when(() => authCubit.currentUser).thenReturn(otherUser);

      final expectation = expectLater(
        createPostCubit.stream,
        emitsInOrder([
          const CreatePostState.loading(),
          isA<CreatePostError>(),
        ]),
      );

      await createPostCubit.submit(
        const NewPostData(
          userId: authorId,
          title: 'Hello world',
          text: longText,
        ),
      );
      await expectation;

      final errorState = createPostCubit.state as CreatePostError;
      expect(errorState.failure, isA<ForbiddenFailure>());
      verifyNever(() => api.createPost(any(), any()));
    },
  );
}
