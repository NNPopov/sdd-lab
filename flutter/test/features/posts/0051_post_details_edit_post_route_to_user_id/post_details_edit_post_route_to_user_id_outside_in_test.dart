import 'package:flutter_application_1/core/auth/application/auth_cubit.dart';
import 'package:flutter_application_1/core/auth/domain/entities/current_user.dart';
import 'package:flutter_application_1/core/errors/failure.dart';
import 'package:flutter_application_1/core/logging/domain/app_logger.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/post_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/dto/update_post_request_dto.dart';
import 'package:flutter_application_1/features/posts/_shared/data/posts_api_client.dart';
import 'package:flutter_application_1/features/posts/_shared/domain/entities/post_status.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_cubit.dart';
import 'package:flutter_application_1/features/posts/edit_post/application/edit_post_state.dart';
import 'package:flutter_application_1/features/posts/edit_post/data/edit_post_adapter.dart';
import 'package:flutter_application_1/features/posts/edit_post/data/revise_post_adapter.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/entities/updated_post_data.dart';
import 'package:flutter_application_1/features/posts/edit_post/domain/usecases/edit_post_usecase.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_cubit.dart';
import 'package:flutter_application_1/features/posts/post_details/application/post_details_state.dart';
import 'package:flutter_application_1/features/posts/post_details/data/get_post_adapter.dart';
import 'package:flutter_application_1/features/posts/post_details/domain/usecases/get_post_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPostsApiClient extends Mock implements PostsApiClient {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAuthCubit extends Mock implements AuthCubit {}

// The post selected by the read/update routes; its author has id 42.
const _authorId = 42;
const _postId = 7;
const _postUuid = 'uuid-7';

CurrentUser _user(int id) => CurrentUser(
  id: id,
  username: 'alice',
  email: 'alice@example.com',
  name: 'Alice',
  isSuperuser: false,
  isModerator: false,
);

PostDto _postDto() => PostDto(
  id: _postId,
  postUuid: _postUuid,
  status: 'pending_review',
  title: 'Hello',
  text: 'Body',
  createdAt: DateTime(2024, 1, 1),
  createdByUserId: _authorId,
);

UpdatedPostData _updatedData() => const UpdatedPostData(
  userId: _authorId,
  id: _postId,
  postUuid: _postUuid,
  status: PostStatus.pendingReview,
  title: 'Updated title',
  text: 'Updated body',
);

void main() {
  late _MockPostsApiClient api;
  late _MockAppLogger logger;
  late _MockAuthCubit authCubit;

  late PostDetailsCubit postDetailsCubit;
  late EditPostCubit editPostCubit;

  setUpAll(() {
    registerFallbackValue(
      const UpdatePostRequestDto(title: '', text: ''),
    );
  });

  setUp(() {
    api = _MockPostsApiClient();
    logger = _MockAppLogger();
    authCubit = _MockAuthCubit();

    // Wire the read vertical real: adapter → use-case → cubit.
    postDetailsCubit = PostDetailsCubit(
      GetPostUseCase(GetPostAdapter(api, logger)),
    );

    // Wire the update vertical real: adapters → use-case → cubit.
    editPostCubit = EditPostCubit(
      EditPostUseCase(
        EditPostAdapter(api, logger),
        RevisePostAdapter(api, logger),
        authCubit,
      ),
    );
  });

  tearDown(() {
    postDetailsCubit.close();
    editPostCubit.close();
  });

  test('reading a post calls getPost with the integer user id', () async {
    when(
      () => api.getPost(_authorId, _postId),
    ).thenAnswer((_) async => _postDto());

    final expectation = expectLater(
      postDetailsCubit.stream,
      emitsInOrder([isA<PostDetailsLoading>(), isA<PostDetailsLoaded>()]),
    );

    await postDetailsCubit.load(_authorId, _postId);
    await expectation;

    final loaded = postDetailsCubit.state as PostDetailsLoaded;
    expect(loaded.post.id, _postId);
    expect(loaded.post.createdByUserId, _authorId);
    verify(() => api.getPost(_authorId, _postId)).called(1);
  });

  test('the author updating a post calls patchPost with the integer user id '
      'and the unchanged body', () async {
    when(() => authCubit.currentUser).thenReturn(_user(_authorId));
    when(
      () => api.patchPost(_authorId, _postId, any()),
    ).thenAnswer((_) async {});

    final expectation = expectLater(
      editPostCubit.stream,
      emitsInOrder([isA<EditPostLoading>(), isA<EditPostSuccess>()]),
    );

    await editPostCubit.submit(_updatedData());
    await expectation;

    final captured = verify(
      () => api.patchPost(_authorId, _postId, captureAny()),
    ).captured;
    final body = captured.single as UpdatePostRequestDto;
    expect(body.title, 'Updated title');
    expect(body.text, 'Updated body');
    expect(body.mediaUrl, isNull);
  });

  test('a non-author is forbidden by id and no update is sent', () async {
    when(() => authCubit.currentUser).thenReturn(_user(99));

    final expectation = expectLater(
      editPostCubit.stream,
      emitsInOrder([isA<EditPostLoading>(), isA<EditPostError>()]),
    );

    await editPostCubit.submit(_updatedData());
    await expectation;

    final error = editPostCubit.state as EditPostError;
    expect(error.failure, isA<ForbiddenFailure>());
    verifyNever(() => api.patchPost(any(), any(), any()));
  });
}
